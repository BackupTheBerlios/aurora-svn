package Aurora::Server::Apache;
use strict;

use Aurora::Server;
use vars qw/@ISA/;

@ISA = qw/Aurora::Server/;


package Aurora;
use strict;

use Apache;
use Apache::URI;
use Apache::Constants qw/:methods/;

use DynaLoader;

use Aurora::Log;
use Aurora::Context;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;

use vars qw/@ISA/;

@ISA = qw/DynaLoader/;


{

  sub init {

    Aurora->bootstrap($VERSION);

    Apache->push_handlers(PerlChildInitHandler => \&Aurora::start);
    Apache->push_handlers(PerlChildExitHandler => \&Aurora::stop);

    unless($Apache::Server::Starting) {
      map { Aurora->new(%{$_})} @Aurora::CONFIG;
    }
  }

  sub run {
    my ($r) = @_;
    my ($host, $uri, $server, $context, $response, $status);
    return DECLINED unless $r->is_main;

    $host = $r->server->server_hostname;
    $uri = $r->parsed_uri;
    $server = Aurora->server($host);

    $context = Aurora::Context->new($r->connection => $r);

    (defined $server)? $context = $server->run($context) :
      do { logerror("Can't find server ", $host); return SERVER_ERROR; };

    $response = $context->response;
    $status = $response->status;

  STATUS: {
      $status == DECLINED && do {
	my ($target);
	$target = $response->header('location');
	$r->uri($target) if $target;
	return DECLINED;
      };
      $status <= OK && do {
	$response->remove_header('content-encoding')
	  if $response->header('content-encoding') &&
	    $r->header_in('Accept-Encoding') !~ /gzip/;
	$r->print(($r->method() eq 'HEAD')?
		  $response->headers_as_string :
		  $response->as_string);
	return DONE;
      };
      $status == REDIRECT && do {
	my ($target, $localhost);
	$target = $response->header('location');
      SWITCH: {
	  $target =~ s/^file:\/\/// && do {
	    $r->method('GET');
	    $r->method_number(M_GET);
	    $r->headers_in->unset('Content-Length');
	    $r->filename($target);
	    return OK;
	  };
	  do {
	    $r->status($status);
	    $r->method('GET');
	    $r->method_number(M_GET);
	    $r->headers_in->unset('Content-Length');
	    $r->header_out(Location => $target);
	    $r->send_http_header;
	    return REDIRECT;
	  };
	}
	;
      };
    };
    return $status;
  }

  *handler = \&Aurora::run;
}

package Aurora::Context::Connection;
use strict;

sub new {
  my ($class, $connection) = @_;
  my ($self);
  $self = bless {
		 ip   => $connection->remote_ip,
		 host => undef,
		}, $class;
  return $self;
}



package Aurora::Context::Request;
use strict;

use Apache;
use Apache::URI;
use Apache::Request;

@ISA = qw/HTTP::Request/;

# should check through all of this, to make sure that
# all methods are correctly overloaded!!!

sub new  {
  my ($class, $r) = @_;
  my ($self);

  # check if $r provided
  $self = bless {
		 _request => Apache::Request->new($r),
		 _name    => undef,
		 _content => undef
		}, $class;
  return $self;
}

sub name {
  my ($self, $name) = @_;
  return (defined $name)? $self->{_name} = $name : $self->{_name};
}

sub base {
  my ($self) = @_;
  return (join '', 'file://', $self->{_request}->document_root);
}


sub param {
  my ($self, $name, $value) = @_;
  $value = undef;
  if(!defined $name) {
    my (@params);
    @params = $self->{_request}->param;
    return (wantarray)? @params : \@params;
  }

  return ((defined $value)? $self->{_request}->param($name, $value) :
	  ((wantarray)? @{[$self->{_request}->param($name)]} :
	   $self->{_request}->param($name)));
}

sub upload {
  return shift->{_request}->upload(@_);
}

sub method {
  return shift->{_request}->method(@_);
}

sub header {
  return shift->{_request}->header_in(@_);
}


sub headers {
  return shift->{_request}->headers_in();
}

sub uri {
  my ($self, $uri) = @_;
  return (defined $uri)? $self->{_request}->uri($uri) :
    Aurora::Context::Request::URI->new($self->{_request});
}


package Aurora::Context::Request::Upload;
use strict;

use Apache;
use Apache::Request;
use vars qw/@ISA/;

@ISA = qw/Apache::Upload/;


package Aurora::Context::Request::URI;
use strict;

use Apache;
use Apache::URI;
use vars qw/@ISA/;

@ISA = qw/Apache::URI/;

use overload q/""/ => sub {
  my ($self) = @_;
  return $self->unparse();
};

sub new {
  my ($class, $request) = @_;
  my ($self);
  $self = bless $request->parsed_uri, $class;
  $self->host($request->server->server_hostname);
  return $self;
}

sub host {
  return Apache::URI::hostname(@_);
}

1;

__END__

=pod

=head1 NAME

Aurora::Server::Apache - The Apache Aurora server backend.

=head1 DESCRIPTION

This class provides the Apache Aurora server backend. This backend
is used when embeding Aurora under Apache, using the mod_perl API.


=head1 PROCESSING METHODS

In addition to all of the methods defined within Aurora::Server, there
is:

=over 1

=item B<run>($r)

This method accepts the Apache Request object and returns an Apache
status code, indicating how Apache should now proceed.

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

L<Aurora>, L<Aurora::Server>

