package Aurora;
use strict;

use Cwd;

use Aurora::Log;
use Aurora::Server;
use Aurora::Config;
use Aurora::Context;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;

use vars qw/$VERSION $DEBUG/;

{
  my ($driver, $servers);
  $VERSION = '0.4.2';
  $DEBUG = 3;

 SWITCH: {
    no warnings;

    $ENV{MOD_PERL} =~ /^Zeus\-Perl\// && do {
      $driver = 'Aurora::Server::Zeus';
      last SWITCH;
    };
    $ENV{MOD_PERL} =~ /^mod_perl\/([\d\.]+)/&& do {
      $driver = (($1 >= 1.99)?
      		 'Aurora::Server::Apache2' :
      		 'Aurora::Server::Apache');
      last SWITCH;
    };
    do {
      $driver = 'Aurora::Server::Default';
      last SWITCH;
    };
  };
  eval "require $driver;" ||
    throw Aurora::Exception("Aurora Initialisation Failed: $@");
  init();


  sub new {
    my ($class, %options) = @_;

    $DEBUG = $options{Debug} if defined $options{Debug};

    unless (defined $servers) {
      logsay("================================");
      logsay("   Aurora (Version $VERSION)    ");
      logsay(" (c)2001-2004 darren\@iterx.org ");
    }
    logsay("================================");

    foreach my $uri ((UNIVERSAL::isa($options{Conf},'ARRAY')?
		      @{$options{Conf}} : $options{Conf})) {

      try {
	my ($base, $config);
	$base = $options{Base} || Cwd::cwd();

	$config = Aurora::Config->reader($uri);
	map {
	  try {
	    my ($server);
	    logsay('Starting server ', $_->{name});
	    $server = $driver->new(base => $base, %{$_});
	    if(defined $server) {
	      $servers->{$server->name} = $server;
	      logsay('Done');
	    }
	  }
	  otherwise {
	    logerror(shift);
	  }
	} ((ref $config->{aurora}->{server} eq 'ARRAY')?
	   @{$config->{aurora}->{server}} : $config->{aurora}->{server});
      }
      otherwise {
	logerror(shift);
      };
    }

    return (defined $servers)? bless $servers, $class : undef;
  }

  sub server {
    my ($class, $name) = @_;
    return $servers->{$name};
  }

  sub init {}

  sub start {

    map { $_->start } values %{$servers} if defined $servers;
  }

  sub run {}

  sub stop  {

    map { $_->stop } values %{$servers} if defined $servers;
  }

  sub destroy {}


  END {
    destroy();
    $driver = $servers = undef;
  };

}

1;

__END__

=pod

=head1 NAME

Aurora - an XML Content Delivery Framework for Perl.

=head1 SYNOPSIS

Aurora can either be used directly from within your Perl program or a
server backends can employed, enabling Aurora to be directly embeded
within a number of third party servers.

Calling Aurora from directly within a script:

  use Aurora;
  use HTTP::Request;

  $aurora = Aurora->new
    (Conf => ["file:///home/web/mywebsite/etc/aurora.conf"]);
  $aurora->start;

  $response = $aurora->run
    ('127.0.0.1' => GET =>  "http://localhost/page.xml");
  print $response->as_string();

  $aurora->stop;

Alternatively, you can enable the mod_perl backend under Apache by adding
the following directives to your mod_perl enabled Apache httpd.conf:

  # These commands must be outsite of any run time configuration
  # blocks (e.g. <Location>).
  PerlModule    Aurora
  PerlDebug	10
  AuroraConfig  file:///home/web/mywebsite/etc/aurora.conf

  # Outside any configuration block or within a location block.
  Aurora        On

or under mod_perl & Apache 2.0, add to the httpd.conf:

  # These commands must be outsite of any run time configuration
  # blocks (e.g. <Location>).
  PerlLoadModule    Aurora
  PerlDebug	10
  AuroraConfig  file:///home/web/mywebsite/etc/aurora.conf

  # Outside any configuration block or within a location block.
  Aurora        On

or under the Zeus webserver, in the perlstartup.pl script add:

  use Aurora;

  #Create an Aurora server instance
  Aurora->new
    (Conf => ["file:///home/web/mywebsite/etc/aurora.conf"]);

and under the virtual server config, enable the Perl Extension option. Then
select add new URL Prefix and add "Aurora" as a URI translation handler.

=head1 DESCRIPTION

Aurora is a Perl based XML Content Delivery Framework. It is designed
to provide a general framework from which external content can
dynamically manipulated and repurposed to a targetted output
medium. Features include:

=over 4

=item * Embedable

Aurora can either be used directly from within a Perl or embeded into
3rd party applications such as Apache/mod_perl.

=item * XML Sitemap

Built in support for server configuration via an XML based sitemap.

=item * Modular

The framework is completely modular, enabling it to easily be
customised and extended.

=item * Pipelines

The framework has build in support for XML pipelines, providing an
easy mechanism to process and repurpose data.

=item * Sessions

Aurora has builtin session support.

=item * Caching

There is advanced caching support, enabling fine grained control over
what data to cache, including partly processed responses.

=back

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Construct a new Aurora processor instance. The constructor takes an
optional hash, containing on or more of the following parameters.

=over 2

=item * Debug

Set the level of log messages to be displayed. A value of 0 will
result in no log messages being displayed, while 10 will mean all log
messages will be seen.

The default value is 3 (show error messages only)

=item * Conf

An array containing the URIs to the configuration files for each of
the Aurora Virtual Server that should be created within this Aurora
instance.

=back

=back

=head1 PROCESSING METHODS

=over 4

=item B<start>()

This method causes all the components within the current instance to
start and initialise any persistent state or connections.

=item B<stop>()

This method causes all the components within the current instance to
stop and cleanup any persistent state or connections.

=item B<server>($name)

Return the Aurora Virtual Server for the supplied hostname, if one
currently exists.

=item B<run>()

This process the current request and return the results. The exact
specification of the input and output parameters, depends upon the
current Aurora server backend deployed.

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

L<Aurora::Server>, L<Aurora::Sitemap>, L<Aurora::Config>,
L<Aurora::Component>, L<Aurora::Mount>, L<Aurora::Context>,
L<Aurora::Cache>, L<Aurora::Session>

