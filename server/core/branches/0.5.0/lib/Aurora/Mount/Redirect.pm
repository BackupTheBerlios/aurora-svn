package Aurora::Mount::Redirect;
use strict;

use Aurora::Log;
use Aurora::Util qw/str2time evaluate/;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Mount;

use vars qw/@ISA/;
@ISA = qw/Aurora::Mount/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{uri} = $options{uri} ||
    throw Aurora::Exception("No uri specified");
  $self->{base} = $options{base} if $options{base};
  $self->{expires} = str2time($options{expires}) if $options{expires};
  return $self;
}

# add option for setting expires to header!!!
sub run {
  my ($self, $context, $options) = @_;
  my ($root, $base, $uri, $response);
  logsay('Running redirect');
  $response = $context->response;

  # should make sure that URL is valid - no ../../ holes, etc!!!
  $root = $context->request->base;
  $base = ((defined $self->{base})?
	   evaluate($self->{base}, $context) :  $root);

  # fix the base appending.... need to get it to work with CGI scripts:
  # e.g /contact -> /cgi/contact.cgi!

  $uri = (((index $self->{uri}, '$') == -1)?
	  $self->{uri} :
	  evaluate($self->{uri}, $context));
  $uri = (join '/',$base, $uri) if $base && $uri !~ /:\/\//;
  $uri =~ s/([^:\/])\/\//$1\//g;

  logdebug('Running plugins');
  map { &$_->run($context) } @{$self->{plugin}};

  logdebug('Checking redirect ',$uri);

 SWITCH:{
    index($uri,'file://') == 0 && do {
      unless(-e substr($uri,7) && -r _) {
	throw Aurora::Exception::Event
	  (-event => NOT_FOUND,
	   -text => (join '','File ',$uri,' is not readable or not found'));
      }
    };
    index($uri, $root) == 0 && do {
      $response->status(DECLINED);
      $response->header(
			expires  => $self->{expires},
			location => substr($uri, length($root))
		       );
      last SWITCH;
    };
    $uri =~ /^(http(s)?|file):\/\// && do {
      $response->status(REDIRECT);
      $response->header(
			expires  => $self->{expires},
			location => $uri
		       );
      last SWITCH;
    };
    do {
      throw Aurora::Exception::Error("Protocol not supported");
    };
  };
  return REDIRECT;
}


1;

__END__

=pod

=head1 NAME

Aurora::Mount::Redirect - A redirect Aurora mount.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <mounts>
      <mount type="redirect" matcher:uri="^(.*)">
        <redirect uri="$uri:1" base="file:///web/"/>
      </mount>
    </mounts>
  </sitemap>


=head1 DESCRIPTION

The redirect mount provides a handler that enables you to "redirect"
the incomming request to new URI, by returning a HTTP redirect
response. For redirects to local resources, instead of returning a the
redirect response, the server will return the actual resource.

When specifying a redirect mount within a sitemap, it can contain:

=over 2

=item * 

One or more plugin declarations

=item * 

A redirect declaration

=back

=head1 TAGS

=over 1

=item B<<redirect>>

The redirect tag specifies where the current request should be
redirected to. The redirect tag, can take the following elements:

=over 2

=item * B<<uri>>

The URI where the request should be redirected to.

=item * B<<base>>

The base URI, which should be applied when resolving relative URIs.

=back

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

L<Aurora>, L<Aurora::MountFactory>, L<Aurora::Mount>
