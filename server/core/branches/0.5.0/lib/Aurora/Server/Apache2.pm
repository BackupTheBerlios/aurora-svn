package Aurora::Server::Apache2;
use strict;

use Aurora::Server;
use vars qw/@ISA/;

@ISA = qw/Aurora::Server/;


package Aurora;
use strict;

use mod_perl;

use Apache2;
use Apache::URI;
use Apache::Server;
use Apache::ServerUtil;
use Apache::Module;
use Apache::Const qw/:methods :cmd_how :override/;

use Apache::CmdParms;
use Apache::RequestIO;
use Apache::RequestRec;
use Apache::RequestUtil;

use Aurora::Log;
use Aurora::Context;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;

use vars qw/@APACHE_MODULE_COMMANDS @CONFIG/;

use constant ENGINE_DISABLED        => 0;
use constant ENGINE_INHERIT         => 1;
use constant ENGINE_ENABLED         => 2;


{
  my (#$base,
      $tmp);

  @APACHE_MODULE_COMMANDS =
    ({
      name         => 'Aurora',
      errmsg       => 'On or Off to enable or disable (default) the whole aurora engine',
      args_how     => Apache::FLAG,
      req_override => Apache::OR_FILEINFO,
     },
     {
      name         => 'AuroraConfig',
      errmsg       => 'URI - Location of server configuration file',
      args_how     => Apache::TAKE1,
      req_override => Apache::RSRC_CONF,
     },
     {
      name         => 'AuroraDebug',
      errmsg       => '[1-10] - Set the debug level of the server loggging',
      args_how     => Apache::TAKE1,
      req_override => Apache::RSRC_CONF,
     });

  sub init {
    my ($server);

    $server = Apache->server;
    $server->push_handlers(PerlPostConfigHandler   => \&Aurora::bootstrap);
    $server->push_handlers(PerlChildInitHandler    => \&Aurora::start);
    $server->push_handlers(PerlChildExitHandler    => \&Aurora::stop);

    #$server->push_handlers(PerlMapToStorageHandler => \&Aurora::run);
    $server->push_handlers(PerlTransHandler => \&Aurora::run);

  }


  sub SERVER_CREATE {
    my ($class) = @_;
    my ($config);

    $config = { Conf => [] };
    push @CONFIG, $config;

    return bless { State => ENGINE_DISABLED }, $class;
  }

  sub DIR_CREATE {
    my ($class) = @_;

    return bless { State => ENGINE_INHERIT }, $class;
  }

  sub DIR_MERGE {
    my ($parent, $child) = @_;
    my ($state);

    $state = (($child->{State} == ENGINE_INHERIT)?
	      ((defined $parent && $parent->{State} == ENGINE_INHERIT)?
	       ENGINE_DISABLED : $parent->{State}) :
	      $child->{State});

    return bless { State => $state }, ref $parent;
  }

  sub SERVER_MERGE {
    my ($parent, $child) = @_;

    return $parent;
  }

  sub AuroraConfig {
    my ($self, $params, $value) = @_;

    push @{$CONFIG[-1]->{Conf}}, $value unless $params->path;
  }

  sub AuroraDebug {
    my ($self, $params, $value) = @_;

    $CONFIG[-1]->{Debug} = $value unless $params->path;
  }

  sub Aurora {
    my ($self, $params, $on) = @_;

    $self->{State} = ($on)? ENGINE_ENABLED : ENGINE_DISABLED;
  }


  sub bootstrap {
    my($conf_pool, $log_pool, $temp_pool, $server) = @_;

    #Apache::ServerUtil::add_version_component($conf_pool,"Aurora/${Aurora::VERSION}");
    while($_ = pop @CONFIG) {
      new('Aurora',
	  Base => $Apache::Server::server_root,
	  %{$_});
    }
    return OK;
  }



# MapToStorageHandler -> fixes up response handler
#sub run {
#     my ($r) = @_;
#     my ($config);
#     $config = Apache::Module->get_config
#       (__PACKAGE__, $r->server, $r->per_dir_config);
#     return DECLINED if $config->{State} == ENGINE_DISABLED;
#     $r->handler("perl-script");
#     $r->push_handlers(PerlResponseHandler => \&Aurora::run);
#     return OK;
#  }


  #temporary handler -> this should really be run in the response
  #handler phases
  sub run {
    my ($r) = @_;
    my ($host, $uri, $server, $context, $response, $status);

    my ($config);
    $config = Apache::Module->get_config
      (__PACKAGE__, $r->server, $r->per_dir_config);

    return DECLINED if $config->{State} == ENGINE_DISABLED || !$r->is_initial_req;
    #$base = (join '', 'file://', $r->document_root);

    $host = $r->server->server_hostname;
    $uri = $r->parsed_uri;
    $server = server('Aurora', $host);

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

	$r->handler("perl-script");
	$r->push_handlers(PerlResponseHandler => \&Aurora::output);
	$tmp = $response;

	#$r->print(($r->method() eq 'HEAD')?
	#	  $response->headers_as_string :
	#	  $response->as_string);

	return OK;
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
	};
      };
    };
    return $status;
  }

  sub output {
    my ($r) = @_;
    $r->print(($r->method() eq 'HEAD')?
	      $tmp->headers_as_string :
	      $tmp->as_string);
    return OK;
  }

  *handler = \&Aurora::run;


}

package Aurora::Context::Connection;
use strict;

use Apache::Connection;

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

use Apache::URI;
use Apache::RequestRec;

@ISA = qw/HTTP::Request/;

# should check through all of this, to make sure that
# all methods are correctly overloaded!!!

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

use Apache::RequestRec;
use vars qw/@ISA/;

@ISA = qw/Apache::Upload/;


package Aurora::Context::Request::URI;
use strict;

use APR::URI;
use vars qw/@ISA/;

@ISA = qw/APR::URI/;

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
  return APR::URI::hostname(@_);
}


package Aurora::Context::Response;

use strict;
use Apache::RequestRec;
use Apache::Response;


sub as_string {
  my $self = shift;
  my @result;

  my $code = $self->code;
  my $status_message = HTTP::Status::status_message($code) || "Unknown code";
  my $message = $self->message || "";
  my $status_line = "$code";
  my $proto = $self->protocol;
  $status_line = "$proto $status_line" if $proto;
  $status_line .= " ($status_message)" if $status_message ne $message;
  $status_line .= " $message";
#  push(@result, $status_line);
#  push(@result, $self->headers_as_string("\x0D\x0A"));

  # check if content exists?
  my $r = Apache->request;
  $r->status($code);
  $r->content_encoding($self->header('content-encoding'));
  $r->content_type($self->header('content-type'));


  if(my $content = $self->content) {
    $content = $content->as_string
      (charset          => $self->header('charset'),
       content_encoding => $self->header('content-encoding'),
       content_type     => $self->header('content-type'),
       mime_type        => $self->header('mime-type')) ;
    push @result, $content;
  }

  return join("\x0D\x0A", @result, "");
}


1;

__END__

=pod

=head1 NAME

Aurora::Server::Apache2 - The Apache 2 Aurora server backend.

=head1 DESCRIPTION

This class provides the Apache 2 l Aurora server backend. This backend
is used when embeding Aurora under Apache 2, using the mod_perl API.


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

