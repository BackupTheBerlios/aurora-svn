package Aurora::Context::Cookies;
use strict;

use Sys::Hostname;

use HTTP::Date qw//;
use HTTP::Cookies;
use LWP::Debug qw//;
use HTTP::Headers::Util qw/split_header_words join_header_words/;

use Aurora::Log;
use Aurora::Util qw/str2time urldecode/;
use Aurora::Exception qw/try/;
use vars qw/@ISA/;

@ISA = qw/HTTP::Cookies/;

sub new {
  my ($class, $message) = @_;
  my ($self);
  $self = $class->SUPER::new;
  $self->extract_cookies($message)
    if UNIVERSAL::isa($message, 'HTTP::Request');
  return $self;
}

# Modified version of HTTP::Cookies::extract_cookies - this should
# only be used on the request.
sub extract_cookies {
  my $self = shift;
  my $message = shift || return;
  my ($netscape_cookies, @pairs);
  return $message
    unless UNIVERSAL::isa($message, 'HTTP::Request');

  my @set = split_header_words($message->header("Cookie2"));

  unless (@set) {
    @set = $message->header("Cookie");
    return $message unless @set;
    $netscape_cookies++;
  }

  my $url = $message->uri;
  my $req_host = $url->host;
  if(($req_host =~ tr/././) < 2) {
    $req_host = ($req_host =~ /\./)? "$req_host.local" : ".$req_host";
  }
  my $req_port = $url->port;
  my $req_path = HTTP::Cookies::_url_path($url);
  HTTP::Cookies::_normalize_path($req_path) if $req_path =~ /%/;

  if ($netscape_cookies) {
    # The old Netscape cookie format for Set-Cookie
    # http://www.netscape.com/newsref/std/cookie_spec.html
    # can for instance contain an unquoted "," in the expires
    # field, so we have to use this ad-hoc parser.
    my $now = time();
    my @old = @set;
    @set = ();
    my $set;
    for $set (@old) {
      my @cur;
      my $param;
      my $expires;
      for $param (split(/\s*;\s*/, $set)) {
	my($k,$v) = split(/\s*=\s*/, $param, 2);
	my $lc = lc($k);
	if ($lc eq "expires") {
	  my $etime = HTTP::Date::str2time($v);
	  if ($etime) {
	    push(@cur, "Max-Age" => HTTP::Date::str2time($v) - $now);
	    $expires++;
	  }
	} else {
	  push(@cur, $k => $v);
	}
      }
      #	    push(@cur, "Port" => $req_port);
      push(@cur, "Discard" => undef) unless $expires;
      push(@cur, "Version" => 0);
      push(@set, \@cur);
    }
  }


 SET_COOKIE:
  for my $set (@set) {
    next unless @{$set} >= 2;

    while(defined $set->[0] && $set->[0] !~/^(discard|domain|max-age|
                                          path|port|secure|version)$/xi) {
      push @pairs, splice(@{$set}, 0, 2);
    }

    my %hash;
    while (@$set) {
      my $k = shift @$set;
      my $v = shift @$set;
      my $lc = lc($k);
      # don't loose case distinction for unknown fields
      $k = $lc if $lc =~ /^(?:discard|domain|max-age|
                                    path|port|secure|version)$/x;
      if ($k eq "discard" || $k eq "secure") {
	$v = 1 unless defined $v;
      }
      next if exists $hash{$k};	# only first value is signigicant
      $hash{$k} = $v;
    }
    ;

    my %orig_hash = %hash;
    my $version   = delete $hash{version};
    $version = 1 unless defined($version);
    my $discard   = delete $hash{discard};
    my $secure    = delete $hash{secure};
    my $maxage    = delete $hash{'max-age'};

    # Check domain
    my $domain  = delete $hash{domain};
    if (defined($domain) && $domain ne $req_host) {
      if ($domain !~ /\./ && $domain ne "local") {
	LWP::Debug::debug("Domain $domain contains no dot");
	next SET_COOKIE;
      }
      $domain = ".$domain" unless $domain =~ /^\./;
      if ($domain =~ /\.\d+$/) {
	LWP::Debug::debug("IP-address $domain illeagal as domain");
	next SET_COOKIE;
      }
      my $len = length($domain);
      unless (substr($req_host, -$len) eq $domain) {
	LWP::Debug::debug("Domain $domain does not match host $req_host");
	next SET_COOKIE;
      }
      my $hostpre = substr($req_host, 0, length($req_host) - $len);
      if ($hostpre =~ /\./ && !$netscape_cookies) {
	LWP::Debug::debug("Host prefix contain a dot: $hostpre => $domain");
	next SET_COOKIE;
      }
    } else {
      $domain = $req_host;
    }

    my $path = delete $hash{path};
    my $path_spec;
    if (defined $path && $path ne '') {
      $path_spec++;
      HTTP::Cookies::_normalize_path($path) if $path =~ /%/;
      if (!$netscape_cookies &&
	  substr($req_path, 0, length($path)) ne $path) {
	LWP::Debug::debug("Path $path is not a prefix of $req_path");
	next SET_COOKIE;
      }
    } else {
      $path = $req_path;
      $path =~ s,/[^/]*$,,;
      $path = "/" unless length($path);
    }

    my $port;
    if (exists $hash{port}) {
      $port = delete $hash{port};
      if (defined $port) {
	$port =~ s/\s+//g;
	my $found;
	for my $p (split(/,/, $port)) {
	  unless ($p =~ /^\d+$/) {
	    LWP::Debug::debug("Bad port $port (not numeric)");
	    next SET_COOKIE;
	  }
	  $found++ if $p eq $req_port;
	}
	unless ($found) {
	  LWP::Debug::debug("Request port ($req_port) not found in $port");
	  next SET_COOKIE;
	}
      } else {
	$port = "_$req_port";
      }
    }
    while(my ($key, $val) = splice(@pairs,0,2)) {
      $self->set_cookie($version, urldecode($key), urldecode($val), $path,
			$domain, $port, $path_spec, $secure,
			$maxage, $discard, \%hash)
	if $self->set_cookie_ok(\%orig_hash);
    }
  }

  $message;
}

# Modifed version of HTTP::Cookies::set_cookie
sub set_cookie {
  my $self = shift;
  my($version,
     $key, $val, $path, $domain, $port,
     $path_spec, $secure, $maxage, $discard, $rest) = @_;

  $domain ||= (hostname || '.localhost');
  $path_spec ||= '/';

  # there must always be at least 2 dots in a domain unless localhost
  if(($domain =~ tr/././) < 2 && $domain !~ /\.local(host)?$/) {
    logwarn("Invalid cookie domain ", $domain);
    return $self 
  }

  # path and key can not be empty (key can't start with '$')
  if(!defined($path) || $path !~ m,^/, ||
     !defined($key)  || $key  !~ m,[^\$],) {
    logwarn("Invalid cookie path ", $path);
    return $self;
  }

  # ensure legal port
  if (defined $port && $port !~ /^_?\d+(?:,\d+)*$/) {
    logwarn("Invlaid port ", $port);
    return $self;
  }

  my $expires;
  if (defined $maxage) {
    if ($maxage <= 0) {
      $expires = 0;
    }
    else {
      $expires = time() + $maxage;
    }
  }
  $version = 0 unless defined $version;

  my @array = ($version, $val,$port,
	       $path_spec,
	       $secure, $expires, $discard);

  push(@array, {%$rest}) if defined($rest) && %$rest;
  # trim off undefined values at end
  pop(@array) while !defined $array[-1];

  $self->{COOKIES}{$domain}{$path}{$key} = \@array;
  $self;
}

sub cookie {
  my ($self,  @cookies);
  $self = shift;
  if(@_ == 1 && !ref $_[0]) {
    my ($name);
    $name = $_[0];

    $self->scan(sub {
		  if ($_[1] eq $name) {
		    push @cookies,
		      Aurora::Context::Cookies::Cookie->new
			  (name  => $_[1],
			   value => $_[2],
			   path  => $_[3],
			   domain => $_[4],
			   port => $_[5],
			   path_spec => $_[6],
			   secure => $_[7],
			   expires => $_[8]
			  );
		  }
		});

  }
  else {
    my ($cookie);
    $cookie = (@_ == 1)? $_[0] : Aurora::Context::Cookies::Cookie->new(@_);

    $self->set_cookie(undef,
		      $cookie->{name},
		      $cookie->{value},
		      $cookie->{path},
		      $cookie->{domain},
		      $cookie->{port},
		      $cookie->{path_spec},
		      $cookie->{secure},
		      str2time($cookie->{expires})
		     );
    push @cookies, $cookie;
  }
  return @cookies;
}

sub clear {
  shift->SUPER::clear(@_);
}

package Aurora::Context::Cookies::Cookie;
use strict;
use vars qw/$AUTOLOAD/;

use overload '""' => sub { $_[0]->{value}};

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 name    => $options{name},
		 value   => ($options{value} || undef),
		 path    => ($options{path} || '/'),
		 domain  => ($options{domain} || undef),
		 port    => ($options{port} || undef),
		 secure  => ($options{secure} || 0),
		 expires => (((exists $options{maxage})?
			      $options{maxage} : $options{expires}) || undef),
		 path_spec => ($options{path_spec} || undef)
	       }, $class;
  return $self;
}

sub DESTROY {}

sub AUTOLOAD {
  my ($value, $function);

  my $self = shift;
  $value = shift;
  ($function) = ($AUTOLOAD =~ /::([^:]*)$/);


  if(exists $self->{$function}) {
  UNSAFE: {
      no strict 'refs';
      *{$AUTOLOAD} = sub {
	my ($self, $value) = @_;
	return (defined $value)? $self->{$function} = $value : $self->{$function};
      };
      return (defined $value)? $self->{$function} = $value : $self->{$function};
    };
  }
  die (join '', 'Can\'t locate object method "',$function,
       '" via package "',ref $self,'"');
}



1;

__END__

=pod

=head1 NAME

Aurora::Context::Cookies - An easy way to manipulate cookie
information within the current context.

=head1 SYNOPSIS

  use Aurora::Context::Cookies;

  $cookies = Aurora::Context::Cookies->new($request);

  $cookie = $cookies->cookie('session-id');
  $value = $cookie->value;
  $name = $cookie->name;

  $new = $cookies->cookie
          (name => 'session-id', value => 'value');

=head1 DESCRIPTION

Aurora::Context::Cookies provides an easy way to manipulate cookies
within the current context.

=head1 CONSTRUCTOR

=over 1

=item B<new>([$request])

Constructs a new Aurora Cookies object. The constructor accepts an
optional Aurora request object, from which to initialise the currently
available cookies.

=back

=head1 ACCESSOR METHODS

=over 2

=item B<cookie>($name)

This will return all of the cookie objects for the specified name.

=item B<cookie>(%options)

The method will create a new cookie from the options supplied. Valid
options are name (mandatory), value (mandatory), path (defaults to
'/'), domain, port, secure and expires.

=back

=head1 AUTHOR/LICENCE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA  02111-1307, USA.

(c)2001-2004 Darren Graves (darren@iterx.org), All Rights Reserved.

=head1 SEE ALSO

L<Aurora>, L<Aurora::Context::Request>, L<Aurora::Context::Response>
