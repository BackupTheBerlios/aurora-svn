package XML::XSP::Taglib;

use strict;

sub new   {
  my ($class) = @_;
  return bless {}, $class;
}

sub start {}

sub stop  {}


1;

__END__

=pod

=head1 NAME

XML::XSP::Taglib - A base class for all XML::XSP based taglibs.

=head1 SYNOPSIS

  package MyTaglib;
  use XML::XSP::Taglib;
  use vars qw/@ISA/;

  @ISA = qw/XML::XSP::Taglib/;

  ...

  1;
  __DATA__
  <?xml version="1.0"?>
  <xsl:stylesheet
     xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

   ...

  </xsl:stylesheet>


=head1 DESCRIPTION

Taglibs represent an easy way to extend an XSP processor, by providing
the ability to create new XSP tags that can be embeded with a document
and control how they are evaluated.

This provides a base class that all XML::XSP based Taglibs must
inherit from.

=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class.

=head1 PROCESSING METHODS

=over 2

=item B<start>()

This method is called when the XSP processor is first started (if this
is under a forking regime (e.g mod_perl), the child process will call it,
straight after it has forked) and can be used to initialise any persistent
objects (e.g database connections).

=item B<stop>()

This method is called when the XSP processor is finally stoped (or under a
forking regime, when the child process is terminated) and can be used to
cleanup and terminate any persistent objects.

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

L<XML::XSP>,L<XML::XSP::TaglibFactory>,L<XML::XSP::Taglib::Core>

=cut
