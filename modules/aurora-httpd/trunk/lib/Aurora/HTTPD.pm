package Aurora::HTTPD;
use strict;

use XML::SAX2Object;
use Aurora::HTTPD::Log;
use Aurora::HTTPD::Server;

use vars qw/$VERSION $DEBUG/;

$VERSION = '0.4.4';
$DEBUG = 3;

use constant NSMAP =>
  {
   'http://iterx.org/aurora/httpd/1.0' => '#default',
  };

sub new {
  my ($class, %options) = @_;
  my ($self, $config);
  if(defined $options{Conf}) {
    my ($sax2object, $in);
    $sax2object = XML::SAX2Object->new
      (Namespace       => 1,
       NamespaceIgnore => 1,
       NamespaceMap    => NSMAP);
    $in = $sax2object->reader(delete $options{Conf});
    $config = {%{$in}, (map { (lc $_ => $options{$_}) } keys %options)};
  }
  else {
    $config = {(map { (lc $_ => $options{$_}) } keys %options)};
  }

  $DEBUG = $config->{debug} if defined $config->{debug};
  Aurora::HTTPD::Log->new(AccessLog =>  $config->{accesslog},
			  ErrorLog  =>  $config->{errorlog});

  $self = bless {
		 Conf     => ((UNIVERSAL::isa($config->{aurora}, 'ARRAY'))?
			       $config->{aurora} : [$config->{aurora}]),
		 Port      => ($config->{port} || 8080),
		 MaxServer => ($config->{maxserver} || 1),
		}, $class;
  return $self;
}



sub run {
  my ($self) = @_;
  Aurora::HTTPD::Server->new(Conf      => $self->{Conf},
			     Port      => $self->{Port},
			     MaxServer => $self->{MaxServer});

  return Aurora::HTTPD::Server->run;
}

1;

__END__

=pod

=head1 NAME

Aurora::HTTPD - A lightweight HTTPD for Aurora.

=head1 SYNOPSIS

  use Aurora::HTTPD;

  $httpd = Aurora::HTTPD->new(%options);
  $httpd->run;


=head1 DESCRIPTION


Aurora::HTTPD is a pure perl, lightweight HTTPD for Aurora, built upon
the POE Component Framework. It is designed primarily to be used in a
development environment or internally within an organisation, where
the deployment of a full blown webserver (such as Apache) isn't
justified. Under no circumstances should this server be deployed in a
hostile environment, since little serious thought has been given to
the servers security model. 

The HTTPD currently supports:

=over 2

=item * Virtual Hosts

=item * Access and Error logging

=back



Further information about Aurora can be found at:

=over 1

=item * http://iterx.org/software/aurora

=back


=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Construct a Aurora::HTTPD server. The constructor takes an optional hash,
containing on or more of the following parameters.

=over 5

=item * Aurora

A list containing the locations of all the Aurora configuration files
that should used to create each of the virtual hosts.


=item * Conf

Specify the location of the file containing the configuration options
this server should use.


=item * Debug

Set the level of log messages to be displayed. A value of 0 will
result in no log messages being displayed, while 10 will mean all log
messages will be seen.  By default, this is set to 3 (error messages
only).

=item * Port

Set the port number this server should be run. By default this is set
to port 8080.

=item * MaxServer

Set the maximum number of instances, this server should create. By
default this is set to 1.

=back

=back

=head1 PROCESSING METHODS

=over 1

=item B<run>()

This method starts the HTTPD.

=back

=head1 CAVEATS


Currently, the Aurora::HTTPD doesn't support:

=over 2

=item *  PUT Requests

=item *  Multipart POST Requests

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

L<Aurora>

=cut
