package XML::XSP::Taglib::Core;

use strict;
use XML::XSP;
use XML::XSP::Taglib;

use vars qw/@ISA $NS/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://apache.org/xsp/core/v1';

1;
__END__

=pod

=head1 NAME

XML::XSP::Taglib::Core - An XML::XSP Taglib implementing the core XSP tags.

=head1 DESCRIPTION

This module provides implementations for the current Core XSP tags:

=over 9

=item * xsp:page

=item * xsp:logic

=item * xsp:expr

=item * xsp:content

=item * xsp:element

=item * xsp:attribute

=item * xsp:text

=item * xsp:pi

=item * xsp:comment

=back

No implementation is provided for xsp:structure, xsp:include & xsp:dtd, with
currently these XSP tags being ignored. Further details about the core XSP tags
can be found at:

=over 2

=item * http://xml.apache.org/cocoon/userdocs/xsp/xsp.html

=item * http://www.axkit.org/docs/xsp/guide.dkb

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

L<XML::XSP::Taglib>

=cut


__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  version="1.0">

  <xsl:template match="xsp:page">
    <xsl:if test="translate(@language, 'PERL', 'perl') = 'perl'">
      <xsl:copy>
        <!--xsl:apply-templates select="@*" /-->
        <xsl:apply-templates />
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xsp:structure|xsp:dtd|xsp:include"/>

  <xsl:template match="xsp:structure|xsp:dtd|xsp:include" mode="code"/>

  <xsl:template match="xsp:content" mode="code">
    <xsl:apply-templates select="node()" />
  </xsl:template>

  <xsl:template match="xsp:content">
    <xsl:apply-templates select="node()" />
  </xsl:template>

  <xsl:template match="xsp:expr|xsp:logic">
  <xsl:copy>
     <xsl:apply-templates select="node()" mode="code" />
  </xsl:copy>
  </xsl:template>

  <xsl:template match="xsp:expr|xsp:logic" mode="code">
    <xsl:apply-templates select="node()" mode="code" />
  </xsl:template>

  <xsl:template match="xsp:attribute|xsp:element|xsp:text|xsp:comment|xsp:pi">
  <xsl:copy>
     <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
  </xsl:template>

  <xsl:template match="xsp:attribute|xsp:element|xsp:text|xsp:comment|xsp:pi" mode="code">
  <xsl:copy>
     <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
  </xsl:template>

  <xsl:template match="node()|@*" mode="code">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- HELPER TEMPLATES -->

 <xsl:template name="as-expr">
  <xsl:param name="node" />
  <xsl:choose>
  <xsl:when test="not(node())">
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="current()"/>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    (join '',
    <xsl:for-each select="$node/node()|$node/text()">
     <xsl:choose>
     <xsl:when test="self::text()">
       <xsl:call-template name="as-string">
         <xsl:with-param name="string" select="current()"/>
       </xsl:call-template>,
     </xsl:when>
     <xsl:otherwise>
       do {<xsl:apply-templates select="current()" mode="code"/>},
     </xsl:otherwise>
     </xsl:choose>
    </xsl:for-each>
    '')
  </xsl:otherwise>
  </xsl:choose>
  </xsl:template>

  <xsl:template name="as-string">
  <xsl:param name="string"/>
  <xsl:param name="quote" select="true()"/>
  <xsl:param name="is-start" select="true()"/>
  <xsl:if test="$quote and $is-start">
    <xsl:value-of select="'q|'"/>
  </xsl:if>
  <xsl:choose>
  <xsl:when test="contains($string,'|')">
    <xsl:value-of select="concat(substring-before($string, '|'),'\|')"/>
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="substring-after($string,'|')"/>
      <xsl:with-param name="quote" select="$quote"/>
      <xsl:with-param name="is-start" select="false()"/>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$string"/>
    <xsl:if test="$quote">
      <xsl:value-of select="'|'"/>
    </xsl:if>
  </xsl:otherwise>
  </xsl:choose>
  </xsl:template>

</xsl:stylesheet>



