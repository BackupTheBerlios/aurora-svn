package Aurora::Server::Default;
use strict;

use Aurora::Server;
use vars qw/@ISA/;

@ISA = qw/Aurora::Server/;


package Aurora;
use strict;

use URI;
use Sys::Hostname;
use HTTP::Response;

use Aurora::Log;
use Aurora::Context;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;
use Aurora::Resource;


no warnings;

sub run {
  my ($class, $context, $server, $request, $response, $status);
  $class = shift;
  $context = Aurora::Context->new(@_);
  $request = $context->request;
  if(my $uri = $context->request->uri) {
    $uri->scheme('http') unless $uri->scheme;
    $uri->host(($request->header('host')?
		$request->header('host') : hostname())) unless $uri->host;
  }

  $server = Aurora->server($request->uri->host);
  (defined $server)? $context = $server->run($context) :
    do { logerror("Can't find server ", $server); return; };
  $response = $context->response;
  $status = $response->status;

 STATUS: {
    $status == DECLINED && do {
      my ($request, $uri, $rib);
      $request = $context->request;
      $uri = ($response->header('location') ||
	      (join '', $request->base, $request->uri->path));
      try {
	my ($headers);
	$rib = Aurora::Resource->fetch($uri);
	$headers = $rib->type;
	$response = Aurora::Context::Response->new(undef, undef,$headers);
	$response->content($rib->object)
	  unless $request->method eq 'HEAD';
      }
      otherwise {
	logerror(shift);
	$response->status(NOT_FOUND);
      };
      last STATUS;
    };
    $status <= OK && do {
      $response->remove_header('content-encoding')
	if $response->header('content-encoding') &&
	  $context->request->header('accept-encoding') !~ /gzip/;
      $response->content('') if $request->method eq 'HEAD';
      return $response;
    };
    $status == REDIRECT && do {
      my ($uri);
      $uri = $response->header('location');
    SWITCH: {
	$uri =~ s/^file:\/\/// && do {
	  my ($rib);
	  try {
	    $rib = Aurora::Resource->fetch($uri);
	    $response = Aurora::Context::Response->new($rib->type);
	    $response->content($rib->object)
	      unless $request->method eq 'HEAD';
	  }
	  otherwise {
	    logerror(shift);
	    $response->status(NOT_FOUND);
	  };
	};
	do {
	  $response = (Aurora::Context::Response->new
		       (REDIRECT,
			undef,
			{location => $response->header('location')}));
	};
      };
      last STATUS;
    };
  };
  return $response;
}




1;
__END__

=pod

=head1 NAME

Aurora::Server::Default - The default Aurora server backend.

=head1 DESCRIPTION

This class provides the default Aurora server backend. This backend is
used when embeding Aurora in normal Perl programmes and scripts.

=head1 PROCESSING METHODS

In addition to all of the methods defined within Aurora::Server, there
is:

=over 1

=item B<run>($connection, $request)

This method accepts a connection object (either the clients IP address
or an Aurora::Connection object) and a request object (either a
HTTP::Request or an Aurora::Context::Request object), returning after
processing an Aurora::Context::Response object.

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

L<Aurora>, L<Aurora::Server>, L<Aurora::Context>, 
L<Aurora::Context::Connection>, L<Aurora::Context::Request>,
L<Aurora::Context::Response>

