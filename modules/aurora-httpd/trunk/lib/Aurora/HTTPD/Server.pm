package Aurora::HTTPD::Server;
use strict;

use Socket;

use POE qw/Wheel::SocketFactory Wheel::ReadWrite Filter::HTTPD Driver::SysRW/;
use POE::Session;

use Aurora;
use Aurora::HTTPD::Log;
use Aurora::HTTPD::Server::Session;


use POSIX qw(ECHILD EAGAIN);

sub new {
  my ($class, %options) = @_;
  my ($self, @uri);

  if($options{Conf}) {
    @uri = ((UNIVERSAL::isa($options{Conf}, 'ARRAY'))?
	    @{$options{Conf}} : $options{Conf});
  }

  $self = bless {
		 Port      => ($options{Port} || 8080),
		 MaxServer => ($options{MaxServer} || 1),
		 Server    => Aurora->new(Conf  => \@uri,
					  Debug => $Aurora::HTTPD::DEBUG)
		}, $class;

  POE::Session->new($self,
		    [ qw/_start _stop _fork _retry  _connection/ ],
                   );
  return $self;
}

sub run {
  $poe_kernel->run();
}


sub _start {
  my ($kernel, $object, $heap) = @_[KERNEL, OBJECT, HEAP];
  $heap->{wheel} = POE::Wheel::SocketFactory->new
    ( BindPort       => $object->{Port},
      SuccessEvent   => '_connection',
      FailureEvent   => '_error'
    );
  $kernel->sig('CHLD', '_signal');
  $kernel->sig('INT', '_signal');

  $heap->{children}    = {};
  $heap->{fork_failed} = 0;
  $heap->{is_child}    = 0;
  if(defined $object->{Server}) {
    foreach (2 .. $object->{MaxServer}) {
      $kernel->yield('_fork');
    }
    $object->{Server}->start
  }
  else {
    logerror("No servers avaliable to start");
    exit;
  }
}

sub _stop {
  my ($object, $heap) = @_[OBJECT, HEAP];
  foreach (keys %{$heap->{children}}) {
    $object->{Server}->stop;
    kill -1, $_;
  }
}

sub _fork {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  return if ($heap->{is_child});
  my $pid = fork();
  unless (defined($pid)) {
    if (($! == EAGAIN) || ($! == ECHILD)) {
      $heap->{fork_failed}++;
      $kernel->delay('_retry', 1);
    }
    else {
      logwarn("Fork failed:  $!");
      $kernel->yield('_stop');
    }
    return;
  }
  if ($pid) {
    $heap->{children}->{$pid} = 1;
  }
  else {
    $heap->{is_child} = 1;
    $heap->{children} = { };
  }
}

sub _error {
  my ($heap, $operation, $errnum, $errstr) = @_[HEAP, ARG0, ARG1, ARG2];
  (($errnum)?
   logerror("Server encountered $operation error $errnum: $errstr") :
   logerror("Fatal server errror"));
  delete $heap->{wheel};
}

sub _retry {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  for (1 .. $heap->{fork_failed}) {
    $kernel->yield('_fork');
  }
  $heap->{fork_failed} = 0;
}


sub _signal {
  my ($kernel, $heap, $signal, $pid, $status) =
    @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

  if ($signal eq 'CHLD') {
    if (delete $heap->{children}->{$pid}) {
      $kernel->yield('_fork');
    }
  }
  return 0;
}

sub _connection {
  my ($kernel, $object, $heap, $socket, $peer_addr, $peer_port) =
    @_[KERNEL, OBJECT, HEAP, ARG0, ARG1, ARG2];
  Aurora::HTTPD::Server::Session->new
      (Server => $object->{Server},
       Handle => $socket,
       Addr   => inet_ntoa($peer_addr),
       Port   => $peer_port);
}

1;
