package XML::XSP::Taglib::Param;
use strict;
use XML::XSP;
use XML::XSP::Taglib;

use vars qw/@ISA $NS $VERSION/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://iterx.org/xsp/param/v1';
$VERSION = '0.4.1';

1;
__END__

=pod

=head1 NAME

XML::XSP::Taglib::Param - An implementation of the XSP Param Taglib for
XML::XSP.

=head1 SYNOPSIS

  # To load Taglib into XML::XSP
  use XML::XSP;
  $xsp = XML::XSP->new(taglibs => ['XML::XSP::Taglib::Param']);
  $page = $xsp->page($document);
  $results = $page->transform($document, {id => 1, name => "my value"});


  # Example of usage in an XSP Document
  <?xml version="1.0"?>
  <xsp:page language="perl"
    xmlns:xsp="http://apache.org/xsp/core/v1"
    xmlns:param="http://iterx.org/xsp/param/v1">
    <data>
      <id><param:id/></id>
      <name><param:name>default value</param:name></name>
    </data>
  </xsp:page>

=head1 DESCRIPTION

This module provides an implementation of the XSP Param Taglib for
XML::XSP. The XSP Param Taglib enables the user to extract values from
the optional hash that is passed in, when the transformer is invoked.

=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class.

=head1 XSP TAGS

=over 3

=item * param:[name]

Display the value from the supplied optional hash, as referenced by
the local name of the element. The content of this tag is used to
provide the default value if the option can't be found.

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

L<XML::XSP>

=cut

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:param="http://iterx.org/xsp/param/v1"
  version="1.0">

  <xsl:template match="node()[namespace-uri() = 'http://iterx.org/xsp/param/v1']">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>


  <xsl:template match="node()[namespace-uri() = 'http://iterx.org/xsp/param/v1']" mode="code">
    (defined $options &amp;&amp; $options-&gt;{<xsl:value-of select="local-name()"/>})?
       $options-&gt;{<xsl:value-of select="local-name()"/>} :
     <xsl:choose>
      <xsl:when test="@default">
        <xsl:call-template name="as-string">
          <xsl:with-param name="string" select="@default" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="as-expr">
          <xsl:with-param name="node" select="current()" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>;
  </xsl:template>

</xsl:stylesheet>





