package Aurora::Server;
use strict;

use Aurora::Log;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;

{
  my ($server);

  sub new {
    my ($class, %options) = @_;
    my ($self, $base);
    $base = $options{base};

    if($base !~ /^(file:\/\/|\/)/) {
      throw Aurora::Exception((join '', "Invalid base uri ", $base));
    }

    $server = $self = bless {
			     name     => $options{name},
			     base     => $base,
			     modules  => {
					  cache   => undef,
					  session => undef,
					 },
			     sitemap => undef,
			    }, $class;

    if(my $modules = delete $options{modules}){
      map {
	try {
	  my ($name, $config, $file);
	  $name = $_;
	  $config = $modules->{$name};
	  logsay('Loading module ', $name,' (', $config->{class},')');
	  $file = $config->{class};
	  $file =~ s/::/\//g;
	  require (join '',$file,'.pm');
	  if(exists $self->{modules}->{$name}) {
	    if(my $code = $config->{class}->can('new')) {
	      $self->{modules}->{$name} =
		$code->($config->{class}, %{$config});
	    }
	    else {
	      throw Aurora::Exception
		("Can't create module");
	    }
	  }
	}
	otherwise {
	  logwarn(shift);
	  logsay('Module failed');
	};
      } keys %{$modules};
    }
    if(my $sitemap = delete $options{sitemap}) {
      try {
	my ($class, $file);
	$class = $sitemap->{class} || 'Aurora::Sitemap';
	logsay('Loading sitemap ', $class);
	$file = $sitemap->{class};
	$file =~ s/::/\//g;
	require (join '',$file,'.pm');
  	if(my $code = $class->can('new')) {
  	  $self->{sitemap} =  $code->($class, %{$sitemap});
  	}
	else {
	  throw Aurora::Exception
	    ("Can't create sitemap");
	}
      }
      otherwise {
	logwarn(shift);
	logsay('Sitemap failed');
      };
    }
    return $self;
  }


  sub name {
    my ($self) = @_;
    return (ref $self)? $self->{name} : $server->{name};
  }

  sub base {
    my ($self) = @_;
    return (ref $self)? $self->{base} : $server->{base};
  }


  sub sitemap {
    my ($self) = @_;
    return (ref $self)? $self->{sitemap} : $server->{sitemap};
  }

  sub cache   {
    my ($self) = @_;
    return (ref $self)?
      $self->{modules}->{cache} : $server->{modules}->{cache};
  }


  sub session   {
    my ($self) = @_;
    return (ref $self)?
      $self->{modules}->{session} : $server->{modules}->{session};
  }

  sub run {
    my ($self, $context) = @_;
    my ($mount);
    (ref $self)? ($server = $self) :
      (defined $server)? ($self = $server) :
	do {
	  logerror('Fatal error, no server specified');
	  $context->response->status(SERVER_ERROR);
	  return $context;
	};

    try {
      # should wrap this around in a closure with a global method for
      # getting the current sitemap/state!!!
      logdebug("Processing request");
      # add caching layer over mount finding....
      # to speed up matching
      $mount  = $self->{sitemap}->run($context);
      $mount->run($context); # should we throw event?
      logdebug("Done");
    }
    catch Aurora::Exception::OK with {
      $context->status(shift->event);
    }
    catch Aurora::Exception::Declined with {
      $context->status(shift->event);
    }
    catch Aurora::Exception::Redirect with {
      my ($error, $response, $redirect);
      $error = shift;
      # mod_perl request rewriting doesn't seem to work
      if($error->uri =~ /^((?!\w+:\/\/))/) {
	if(defined $error->uri) {
	  my ($uri, $local);
	  $uri = $context->request->uri;
	  $local = (join '', ($uri->scheme || 'http'),'://',$uri->host,
		    (($uri->port &&
		      ($uri->port != 80 ||
		       $uri->port != 443))? (':',$uri->port) : ''));
	  # no relative path support
	  $redirect = (join '', $local, $error->uri);
	}
	else {
	  $redirect = $context->request->uri->as_string;
	}
      }
      else {
	$redirect = $error->uri;
      }
      $response = $context->response;
      $response->status(REDIRECT);
      $response->header(location => $redirect);
    }
    catch Aurora::Exception::Event with {
      my ($event, $response, $status);
      $event = shift;
      logwarn($event);
      logdebug($event->event,' event caught');
      $response = $context->response;
      if($mount && $response->status != $event->event) {
	# set internal server response code
	$response->status($event->event);
	# set http response code
	$response->code($event->event);
	$status = $mount->catch($context);
	if(defined $status) {
	  $response->status($status);
	}
      }
      else {
	$response->status($event->event);
      }
    }
    otherwise {
      my ($response, $status);
      logerror(shift);
      $response = $context->response;
      if($mount && $response->status != SERVER_ERROR) {
	$response->status(SERVER_ERROR);
	$status = $mount->catch($context);
	if(defined $status) {
	  $response->status($status);
	}
      }
      else {
	$response->status(SERVER_ERROR);
      }
    };
    return $context;
  }

  sub start {
    my ($self) = @_;
    logdebug("Starting child server ", $self->{name});
    $self->{sitemap}->start();
    return;
  }

  sub stop {
    my ($self) = @_;
    logdebug("Stopping child server ", $self->{name});
    $self->{sitemap}->stop();
    return;
  }
}


1;

__END__

=pod

=head1 NAME

Aurora::Server - An Aurora server instance.

=head1 SYNOPSIS

  use Aurora::Server;

  $server = Aurora::Server->new($options);

  $server->start;
  $server->run($context);
  $server->stop;


=head1 DESCRIPTION

This class provides an Aurora server instance. A server instance
should be created for each virtual host domain & sitemap that this
Aurora instance needs to support. The server object provides the top
level API for dispatching requests for a specific virtual host to
process.

When embeding Aurora within 3rd party systems, implementors should
use this as a base class, around which they integrate. Currently,
Aurora has built in support for the following backend servers:

=over 2

=item * Default

The default backend, used when Aurora is embeded directly within
normal Perl programmes.

=item * mod_perl

This backend is used to embed Aurora within Apache, making use of the
mod_perl API.

=back

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new Server instance. Valid options are:

=over 3

=item * name

The virtual domain name for this server.

=item * modules

Parameters to create any server modules that need to be loaded.

=item * sitemap

Parameters to create the server sitemap.

=back

=back

=head1 ACCESSOR METHODS

=over 5

=item B<base>()

Returns the current document root URI base. This is used when
resolving relative URIs.

=item B<cache>()

This method returns the cache instance for this server.

=item B<name>()

This method returns this servers virtual host domain name.

=item B<session>()

This method returns the session instance for this server.

=item B<sitemap>()

This method returns the sitemap instance for this server.

=back

=head1 PROCESSING METHODS

=over 3

=item B<run>()

This method processes the current request and return the results. The
exact specification of the input and output parameters, depends upon
the current Aurora server backend deployed.

=item B<start>()

This method causes all the components within the current instance to
start and initialise any persistent state or connections.

=item B<stop>()

This method causes all the components within the current instance to
stop and cleanup any persistent state or connections.

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

L<Aurora>, L<Aurora::Server::Default>, L<Aurora::Server::mod_perl>,
L<Aurora::Server::Zeus>
