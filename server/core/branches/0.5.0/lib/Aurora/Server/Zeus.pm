package Aurora::Server::Zeus;
use strict;

use Aurora::Server;

use vars qw/@ISA/;

@ISA = qw/Aurora::Server/;


package Aurora;
use strict;

use Apache;
use Apache::URI;
use Apache::Constants qw/:methods/;
use Zeus::ModPerl;

use Aurora::Log;
use Aurora::Context;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;

{

  sub init {

    Zeus::ModPerl->push_handlers(PerlChildInitHandler => \&Aurora::start);
    Zeus::ModPerl->push_handlers(PerlChildExitHandler => \&Aurora::stop);
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

package Aurora::Context::Request;
use strict;

use Zeus::ModPerl;
use Zeus::ModPerl::URI;
use Zeus::ModPerl::Request;


@ISA = qw/HTTP::Request/;


sub new  {
  my ($class, $r) = @_;
  my ($self);

  # check if $r provided
  $self = bless {
		 _request => $r,
		 _name    => undef,
		 _content => undef
		}, $class;
  return $self;
}

sub param {
  my ($self, $name, $value) = @_;

  # $r->args() && Zeus::ModPerl::Request->instance($r)->param
  # borked in Zeus 4.2r4

  return;
}


sub uri {
  my ($self, $uri) = @_;
  my ($request);
  $request = Zeus::ModPerl::Request->instance($self->{_request});

  return (defined $uri)? $request->uri($uri) :
    Aurora::Context::Request::URI->new($request);
}

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

package Aurora::Log;

use strict;
use Exporter;
use POSIX qw/strftime/;

use Aurora::Exception qw/:try/;

use Zeus::ModPerl::Log;

{
  my ($instance);

  sub new {
    my ($class, $handler) = @_;
    my ($self);
    throw Aurora::Exception("The log handler supplied isn't a callback.")
      unless ref $handler eq 'CODE';

    $self = bless {
		   handler => $handler
		  }, $class;

    $instance ||= $self;
    return $self;
  }

  sub AUTOLOAD {
    my ($self, $level, $method, $found, $function);
    $self = (caller)[0];
    $level = 0;
    $found = 0;
    ($function) = ($AUTOLOAD =~ /::([^:]*)$/);
    if(grep {$level++ unless $found;
	     ($function eq $_)? ($found = 1) : 0} @EXPORT) {
      $level = 1+ ($level * 2);
    UNSAFE: {
	no strict 'refs';
	if($Apache::Server::Starting && !$instance) {
	  print STDERR
	    "[",(strftime '%d/%b/%Y:%H:%M:%S %z',gmtime()),"] ",
	      uc($LEVEL[$level]),":Aurora ",
		@_, ((ref @_[-1] ||
			   (@_[-1] || '') !~ /\n$/)? "\n" : '');
	  return;
	}

	$method = lc($LEVEL[$level]);
	*{$AUTOLOAD} = ($instance)?
	  sub { $instance->{handler}->((caller)[0], $level, @_);  } :
	    sub {
	      my ($pkg, @errors);
	      $pkg = (caller)[0];
	      @errors = @_;
	      return if
		(ref $self &&
		 (${(join '', ref $self, '::DEBUG')} || 10) < $level) ||
		   $Aurora::DEBUG == 0 || $Aurora::DEBUG < $level;
	      Zeus::ModPerl->request->server->log->$method("Aurora ", @errors);
	    };
      }
      if(my $code = $self->can($function)) {
	return $code->(@_);
      }
    }
    die (join '','Can\'t locate object method "',$function,
	 '" via package "',ref $self,'"',"\n");
  }
}


1;
__END__

=pod

=head1 NAME

Aurora::Server::Zeus - The Zeus Aurora server backend.

=head1 DESCRIPTION

This class provides the Zeus Aurora server backend. This backend
is used when embeding Aurora under Zeus, using the mod_perl API. This
server backend is currently highly experimental and has not been tested
in a real world environment.

=head1 PROCESSING METHODS

In addition to all of the methods defined within Aurora::Server, there
is:

=over 1

=item B<run>($r)

This method accepts the Request object and returns a status code,
indicating how the webserver should now proceed.

=back

=head1 CAVEATS

Currently the Zeus backend doesn't support query string parameters,
due to problems with the Zeus request object implementation.

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

