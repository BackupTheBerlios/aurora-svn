package Aurora::Config;

use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use XML::SAX2Object;
use vars qw/@ISA/;

@ISA = qw/XML::SAX2Object/;

use constant NSMAP =>
  {
   'http://iterx.org/aurora/sitemap/1.0'         => '#default',
   'http://iterx.org/aurora/sitemap/1.0/event'   => 'event',
   'http://iterx.org/aurora/sitemap/1.0/matcher' => 'matcher',
   'http://iterx.org/aurora/sitemap/1.0/plugin'  => 'plugin'
  };

sub new {
  my ($class);
  $class = shift;
  return $class->SUPER::new
    (Namespace       => 1,
     #NamespaceIgnore => 1,
     NamespaceMap    => NSMAP,
     @_);
}

sub reader {
  my ($self, $uri) = @_;
  $self = $self->new unless ref $self;
  return $self->SUPER::reader($uri);
}

sub writer {
  my ($self, $uri, $config) = @_;
  $self = $self->new unless ref $self;
  return $self->SUPER::writer($config, {Output => $uri});
}



1;
__END__

=pod

=head1 NAME

Aurora::Config - The Aurora configuration reader/writer.

=head1 SYNOPSIS

  use Aurora::Config;
  
  $config = Aurora::Config->new();

  $my_config = $config->reader($uri)
  $config->writer($uri, $my_config);


=head1 DESCRIPTION

Aurora::Config provides a simple mechanism to read and write the
current Aurora configuration file. The configuration is stored as an
XML file on the local filesystem. When the configuration is loaded,
the XML is converted to a Perl datastructure representing the data.

=head1 CONSTRUCTOR

=over 1

=item B<new>()

Construct a new Aurora::Config object.

=back

=head1 PROCESSING METHODS

=over 2

=item B<reader>($uri)

This method returns a Perl datastructure representing the XML file
located at the supplied URIs location. Currently only URIs with the
file protocol are supported.

=item B<writer>($uri, $object)

This method writes the supplied Perl datastructure to an XML file at
the URI location supplied. Currently only URIs with the file protocol
are supported.

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

L<Aurora>, L<XML::SAX2Object>
