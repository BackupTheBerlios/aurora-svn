package Aurora::Context::Request;
use strict;

use HTTP::Request;

use Aurora::Server;
use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Context::Cookies;

use vars qw/@ISA/;

@ISA = qw/HTTP::Request/;

sub new  {
  my ($class, $self);
  $class = shift;

  $self = (ref $_[0] && UNIVERSAL::isa($_[0], 'HTTP::Request'))?  $_[0] :
    $class->SUPER::new($_[0], $_[1],
		       ((ref $_[2] eq 'HASH')?
			HTTP::Headers->new(%{$_[2]}) : $_[2]));
  $self->{_name} = undef;
  return bless $self, $class;
}


sub base {
  my ($self) = @_;
  return Aurora::Server->base;
}


sub name {
  my ($self, $name) = @_;
  return (defined $name)? $self->{_name} = $name : $self->{_name};
}


sub cookie {
  my ($self, $name) = @_;
  my (@cookies);
  unless (exists $self->{_cookies}) {
    $self->{_cookies} = Aurora::Context::Cookies->new($self);
  }
  @cookies = $self->{_cookies}->cookie($name);
  return (wantarray)? @cookies : $cookies[0];
}

sub param {
  my ($self, $name) = @_;
  unless(ref $self->{_content}) {
    my (@strings, $type, $method, $content);
    $type = lc $self->header('content_type') ||
      'application/x-www-form-urlencoded';
    $method = $self->method;

  SWITCH: {
      ($method eq 'POST' &&
       index($type, 'multipart/form-data')) && do {
	 logwarn('Multipart forms are currently not supported');
       };
      ($method eq 'POST' &&
       index($type,'application/x-www-form-urlencoded') == 0) && do {
	 push @strings, $self->{_content};
      };
      do {
	my (@pairs);
	push @strings, $self->uri->query;
	@pairs = grep { y/\+/ /; s/\%([A-F\d]{2})/chr(hex($1))/eig; 1 }
		 map {
		   ((index $_, '=') > 0)? (split(/=/,$_,2)) : ($_, undef);
		 }
                 map { (split(/[;&]/s,$_)) } @strings;
	while(@pairs) {
	  push( @{ $content->{shift(@pairs)} } , shift(@pairs));
	}
        $self->{_content} = $content;
	last SWITCH;
      };
    }
  }

  return ((!defined $name)?
	  ((wantarray)? keys %{$self->{_content}} :
	   [keys %{$self->{_content}}]) :
	  ((wantarray  && exists $self->{_content}->{$name})?
	   @{$self->{_content}->{$name}} : $self->{_content}->{$name}->[0]));
}

sub upload {
  warn('not implemented');
  return undef;
}

sub as_string {
  warn('not implemented');
  return '';
}

package Aurora::Context::Request::Upload;
use strict;



1;

__END__

=pod

=head1 NAME

Aurora::Context::Request - processing information for the current
request.

=head1 SYNOPSIS

  use Aurora::Context::Request;

  $request = Aurora::Context::Request->new(GET => 'http://localhost/myfile');

  @params =  $request->param();
  $value = $request->headers('user-agent');
  $uri = $request->uri;

  $cookie = $request->cookie('session-id');


=head1 DESCRIPTION

This object provides a encapsulated HTTP style request, containing the
current processing information that should be used.

=head1 CONSTRUCTOR

The constructor for a new Aurora::Context::Request, changes depending
upon the choice of backend Aurora servers deployed. 

For the default backend server:

=over 2

=item B<new>($request)

Construct a new Aurora request object, where the request is a current
HTTP::Request object.

=item  B<new>($method, $uri, [$header, [$content]])

Construct a new Aurora request object, where the method is a string,
the uri variable can either be a string or a URI object, while the
headers should be a reference to a valid HTTP::Headers object.

=back

Using the mod_perl backend server:

=over 1

=item B<new>($request)

Construct a new Aurora request object, request variable is the
Apache::Request object.

=back


=head1 ACCESSOR METHODS

=over 4

=item B<cookie>($name)

In list context, this will return all of the cookie objects for the
specified name, while in scalar context it will return just the first
value.

=item B<header>($name)

In list context, this method will return a list of the values set for
specified HTTP Header name, while in scalar context a string will be
returned with the values concatenated by the comma seperator.

=item B<method>()

Returns the HTTP method for the current request.


=item B<param>([$name])

With no name specified, this method will return a list containing the
names of all the current parameters available (either as a array or
array reference depending on context). If a name is specified, then in
list context a list of values set for this parameter name will be
returned , while in scalar context it will return just the first value.

=item B<upload>()

Returns the Upload object for the current request, which are created
during file uploads from the client.

=item B<uri>()

Returns the URI object for the current request.

=back

=head1 CAVEATS

File uploads are only currently supported under the mod_perl backend.


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

L<Aurora>, L<Aurora::Context>, L<Aurora::Context::Cookies>, L<URI>

