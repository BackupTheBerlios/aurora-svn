package Aurora::Constants;
use strict;
use Exporter;

use vars qw/@ISA %EXPORT_TAGS/;
@ISA = qw/Exporter/;

# Internal
use constant OK                  => 0;
use constant DECLINED            => -1;
use constant DONE                => -2;
use constant DELETE              => -3;

# Sucessful
use constant REQUEST_OK          => 200;

# Redirection
use constant MOVED_PERMANENTLY   => 301;
use constant REDIRECT            => 302;
use constant NOT_MODIFIED        => 304;

# Client Error
use constant BAD_REQUEST         => 400;
use constant UNAUTHORIZED        => 401;
use constant FORBIDDEN           => 403;
use constant NOT_FOUND           => 404;

# Server Error
use constant SERVER_ERROR        => 500;
use constant NOT_IMPLEMENTED     => 501;
use constant BAD_GATEWAY         => 502;
use constant SERVICE_UNAVAILABLE => 503;

%EXPORT_TAGS = (internal => [ qw/OK
                                 DECLINED
                                 DONE
                                 DELETE/],
		response => [ qw/REQUEST_OK
 		                 MOVED_PERMANENTLY
		                 REDIRECT
		                 NOT_MODIFIED
		                 BAD_REQUEST
		                 UNAUTHORIZED
		                 FORBIDDEN
			         NOT_FOUND
  			         SERVER_ERROR
			         NOT_IMPLEMENTED
			         BAD_GATEWAY
                                 SERVICE_UNAVAILABLE/]
	       );

Exporter::export_tags(qw/internal/);
Exporter::export_ok_tags(qw/internal response/);


1;

__END__

=pod

=head1 NAME

Aurora::Constants - Constants that are used internally within Aurora.

=head1 SYNOPSIS

  use Aurora::Constants qw/:internal :response/;

=head1 DESCRIPTION

A collection of constants used internally within Aurora to set the
status of the Aurora response object and control the internal
processing of a request.


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

L<Aurora>
