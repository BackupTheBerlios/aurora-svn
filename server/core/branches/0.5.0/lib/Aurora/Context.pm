package Aurora::Context;

use strict;

use HTTP::Request;
use Digest::MD5 qw/md5_hex/;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use Aurora::Server;
use Aurora::Resource;
use Aurora::Constants qw/:internal :response/;
use Aurora::Context::Connection;
use Aurora::Context::Request;
use Aurora::Context::Response;
use Aurora::Context::Session;


# new($connection, HTTP::Request)
# new($connection, METHOD, URL, HEADERS)
sub new {
  my ($class, $connection, $self);
  $class = shift;
  $connection = shift;

  $self = bless {
		 id             => undef,
		 connection     => Aurora::Context::Connection->new($connection),
		 request        => Aurora::Context::Request->new(@_),
		 response       => Aurora::Context::Response->new(),
		 session        => undef,
		 _matches       => {},
		 _dependancies  => []
		}, $class;
}

sub id {
  my ($self) = @_;
  unless($self->{id}) {
    my ($id, $uri);
    $uri = $self->{request}->uri;
    $id = (join '',
	   '[',
	   do {
	     (join ';',
	      (map {
		(join '',$_,'=',
		 (join ',',
		  (map { ($_ || '' ) } @{$self->{_matches}->{$_}})))
	      } sort keys %{$self->{_matches}}))
	   },
	   (($uri->query)?
	    do {
	      ('|',join ';',
	       (sort {
		 my (@a, @b);
		 @a = split /\=/,($a || ''),2;
		 @b = split /\=/,($b || ''),2;
		 ($a[0] cmp $b[0] || $a[1] cmp $b[1]);
	       } split /[;&]/, $uri->query))
	    } : ()),']');
    $self->{id} = md5_hex($id);
  }
  return ((scalar @{$self->{_dependancies}})?
	  (join ':', $self->{id}, scalar @{$self->{_dependancies}}) :
	  $self->{id});

}

sub matches {
  my ($self, %matches) = @_;
  if(%matches) {
    $self->{_matches} = \%matches;
  }
  return (wantarray)? %{$self->{_matches}} : $self->{_matches};
}

sub dependancy {
  my ($self, $object) = @_;
  if (defined $object) {
    if(UNIVERSAL::isa($object, 'Aurora::Component')) {
      # no should be [instance_id => [args] or OIB or undef]
      push @{$self->{_dependancies}}, [ $object->id => undef];
    }
    else {
      unless(ref $self->{_dependancies}->[-1]) {
	logwarn("Dependancy registration failed, no component assigned");
	return 0;
      }
      push @{$self->{_dependancies}->[-1]->[1]}, $object;
    }
    return 1;
  }
  return ((wantarray)?
	  @{$self->{_dependancies}} : $self->{_dependancies});
}

sub consecrate {
  my ($self) = @_;
  my ($cache, $oib, $object);
  if($cache = Aurora::Server->cache) {
    my (@dependancies, $response);
    $response = $self->{response};
    $oib = $cache->oib(id          => $self->id,
		       dependancy  => [@{$self->{_dependancies}}],
		       type        => $response->headers);
    $object = $self->{response}->content->as_string
      (charset => $response->header('charset'),
       content_type => $response->header('content_type'),
       content_encoding => $response->header('content_encoding'));
    #flush dependancies, now dependant on cached object
    #atm, this can cause a problem if cached object isn't then
    #subsequently saved
    @dependancies =  map { [$_->[0], undef] } @{$self->{_dependancies}};
    $dependancies[-1]->[1] = $oib->id;
    $self->{_dependancies} = \@dependancies;
  }
  return ($oib, $object);
}

sub reconsecrate {
  my ($self, $oib, $object) = @_;
  if(defined $oib) {
    my ($oid, $response, $headers, $expires);
    $oid = $oib->id;
    $headers = $oib->type;
    $expires = ($oib->date - time() + $oib->expires);
    $response = Aurora::Context::Response->new(undef, undef, $headers);
    $response->header(expires => (($expires > 0)? $expires : undef));
    $response->content
      ($object,
       {charset => $response->header('charset'),
	content_type => $response->header('content_type'),
	content_encoding => $response->header('content_encoding')});

    $self->{response} = $response;
    $self->{_dependancies} = [@{$oib->dependancy}];
  }
  return $self;
}


sub connection {
  my ($self, $connection) = @_;
  return (defined $connection)?
    $self->{connection} = $connection : $self->{connection};
}

sub request {
  my ($self, $request) = @_;
  return (defined $request)?
    $self->{request} = $request : $self->{request};
}

sub response {
  my ($self, $response) = @_;
  return (defined $response)?
    $self->{response} = $response : $self->{response};
}

sub session {
  my ($self, $session, $options) = @_;
  unless(defined $self->{session}) {
    $self->{session} = Aurora::Context::Session->new($self, $options);
  }
  return (defined $session)?
    $self->{session} = $session : $self->{session};
}

1;

__END__

=head1 NAME

Aurora::Context - The Aurora::Context Object.

=head1 SYNOPSIS

  use Aurora::Context;
  use HTTP::Request;

  $context = Aurora::Context->new
  ('127.0.0.1' => GET => 'http://localhost/');

  $connection = $context->connection; 
  $session = $context->session;
  $request = $context->request;
  $response = $context->response;


  # register an external file dependancy
  $context->dependancy($rib);


=head1 DESCRIPTION

The Aurora context object provides a unified way to access to the
processing state for the current request. The context object is
comprised of:

=over 4

=item * Aurora::Context::Connection

The connection information for the remote client.

=item * Aurora::Context::Session

Retrieve the session information for the current connection. 

=item * Aurora::Context::Request 

Contains the current request data.

=item * Aurora::Context::Response

Contains the response data for the current request.

=back

=head1 CONSTRUCTOR

The constructor for a new Aurora::Context, changes depending upon the
choice of backend Aurora servers deployed. 

For the default backend server:

=over 2

=item B<new>($connection, $request)

Construct a new Aurora context object, where the connection variable
is either a string representing the remote IP address of the caller,
or an Aurora::Context::Connection object and the request is a
Aurora::Context::Request or HTTP::Request object.

=item  B<new>($connection, $method, $uri, [$header, [$content]])

Construct a new Aurora context object, where the connection variable
is either a string representing the remote IP address of the caller,
or an Aurora::Context::Connection object. The uri variable can either
be a string or a URI object, while the headers should be a reference
to a HTTP::Headers object.

=back

Using the mod_perl backend server:

=over 1

=item B<new>($connection, $request)

Construct a new Aurora context object, where the connection variable
is an Apache::Connection object and the request variable is the
Apache::Request object.

=back

=head1 ACCESSOR METHODS

=over 5

=item B<id>()

This method returns a unique identifier for the current context, based
upon the context request object.

=item B<connection>([$connection])

If an Aurora::Context::Connection object is supplied, then replace the
current context connection with the new instance, otherwise return the
current connection.

=item B<session>([$session],[\%options])

If an Aurora::Context::Session object is supplied, then replace the
current context session with the new instance, otherwise return the
current session (automatically creating a session, if no session
currently exists).

=item B<request>([$request])

If an Aurora::Context::Request object is supplied, then replace the
current context request with the new instance, otherwise return the
current request.

=item B<response>([$response])

If an Aurora::Context::Response object is supplied, then replace the
current context response with the new instance, otherwise return the
current response.

=back

=head1 PROCESSING METHODS

=over 3

=item B<dependancy>($rib)

This method associates the external resource supplied, as a cache
dependancy for the creation of the resultant response.

=item B<consecrate>()

The consecrate method serialises the current context, returning a
Resource ID Block and a string representation of the response
content. This can then be used to cache the current context.

=item B<reconsecrate>($rib, $object)

The reconsecrate method takes a Resource ID Block and a string
representation of the response content (from a previously consecrated
context) and recreates a the context object from them.

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

L<Aurora>, L<Aurora::Context::Connection>,
L<Aurora::Context::Session>, L<Aurora::Context::Request>, 
L<Aurora::Context::Response>
