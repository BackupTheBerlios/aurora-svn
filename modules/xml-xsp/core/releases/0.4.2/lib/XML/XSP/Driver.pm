package XML::XSP::Driver;
use strict;

use XML::XSP::Exception qw/:try/;

sub new {
  my ($class, %options) = @_;
  return bless {}, $class;
}

sub compile { throw XML::XSP::Exception("Abstract class"); }

sub document { throw XML::XSP::Exception("Abstract class"); }

sub stylesheet { throw XML::XSP::Exception("Abstract class"); }

1;

__END__

=pod

=head1 NAME

XML::XSP::Driver - An abstract class for an XML::XSP Driver.

=head1 SYNOPSIS

  package MyDriver;
  use XML::XSP::Driver;
  use vars qw/@ISA/;

  @ISA = qw/XML::XSP::Driver/;

  ...


=head1 DESCRIPTION

This provides an abstract class that all user defined drivers must inherit from.
User drivers should then provide implementations of the following processing
methods.

=over 3

=item * document

=item * stylesheet

=item * compile

=back

=head1 CONSTRUCTOR

=over 1

=item B<new>(%hash)

Construct a new driver instance. It can take a number of optional parameters,
the exact nature of which is dependant on the driver implementation.

=back

=head1 PROCESSING METHODS

=over 3

=item B<document>($source,[\%options])

This method accepts a source reference (either a URI pointing to the source
document, a filehandle, a string reference or a driver native document) and
returns a driver native DOM document. The options hash can take a "Clone"
parameter, which will cause a clone of the source to be created.

=item B<stylesheet>($source,[\%options])

This method accepts a source reference (either a URI pointing to the source
document, a filehandle, a string reference or a driver native document) and
returns a driver native XSLT stylesheet. The options hash can take a "Clone"
parameter, which will cause a clone of the source to be created.

=item B<compile>($class, $document)

The compile method accepts a class name and a driver native DOM document and
returns the source code for the XSP page, to apply the requested transform to
the document.

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

L<XML::XSP>,L<XML::XSP::DriverFactory>

=cut
