package Aurora::HTTPD::Server::Session;
use strict;


use Aurora::HTTPD::Log;

use POE::Session;
use POE::Driver::SysRW;
use POE::Filter::HTTPD;
use POE::Wheel::ReadWrite;

use HTTP::Status;
use HTTP::Response;


sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 Server => $options{Server},
		 Handle => $options{Handle},
		 Addr   => $options{Addr},
		 Port   => $options{Port}
		}, $class;

  POE::Session->new($self,
		    [ qw/_start _stop _receive _flushed _error/ ]);
  return $self;
}


sub _start {
  my ($kernel, $object, $heap) = @_[KERNEL, OBJECT, HEAP];
  $heap->{wheel} = POE::Wheel::ReadWrite->new
    ( Handle       =>  $object->{Handle},
      Driver       =>  POE::Driver::SysRW->new,
      Filter       =>  POE::Filter::HTTPD->new,
      InputEvent   => '_receive',
      ErrorEvent   => '_error',
      FlushedEvent => '_flushed');
}

sub _stop { }

sub _receive {
  my ($object, $heap, $request) = @_[OBJECT, HEAP, ARG0];
  my ($context, $response);
  eval {
    $response = $object->{Server}->run($object->{Addr} => $request);
  };
  if($@ || !defined $response) {
    logerror("Server error:", $@) if $@;
    $response = HTTP::Response->new(RC_INTERNAL_SERVER_ERROR);
    $response->protocol('HTTP/1.1');
  }
  if($response->is_error && length($response->content) == 0) {
    $response->content($response->error_as_HTML);
  }

  $heap->{request} = $request;
  $heap->{response} = $response;
  $heap->{wheel}->put($response);
}

sub _error {
  my ($heap, $operation, $errnum, $errstr) = @_[HEAP, ARG0, ARG1, ARG2];
  (($errnum)?
   logerror("$operation error $errnum : $errstr") :
   logwarn("Client disconnected"));
  delete $heap->{wheel};
}

sub _flushed {
  my ($object, $heap) = @_[OBJECT, HEAP];
  my ($request, $response, $uri);
  $request = $heap->{request};
  $response = $heap->{response};
  $uri = $request->uri;

  logaccess($request->header('host'),
	    $object->{Addr},
	    (join ' ', $request->method,
	     (($uri->query)? $uri->path : (join '?', $uri->path, $uri->query)),
	     $request->protocol),
	    $response->code,
	    $request->header('referer'),
	    $request->header('user-agent'),
	   );

  delete $heap->{request};
  delete $heap->{response};
  delete $heap->{wheel};
}

package POE::Filter::HTTPD;

sub put {
  my ($self, $responses) = @_;
  my (@raw);
  map { push @raw, $_->as_string} @$responses;
  return \@raw;
}

1;
