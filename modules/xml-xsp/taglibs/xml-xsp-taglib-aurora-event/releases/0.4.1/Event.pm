package XML::XSP::Taglib::Aurora::Event;
use strict;

use XML::XSP;
use XML::XSP::Taglib;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Util qw/str2code/;
use Aurora::Constants qw/:response/;

use vars qw/@ISA $NS $VERSION/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://iterx.org/xsp/aurora/event/v1';
$VERSION = '0.4.1';

# need to cause cleanup of XML::XSP state!
sub throw {
  my ($self, $name, $options) = @_;
  my ($event);
  $name =~ tr/[a-z\-]/[A-Z_]/;
  $options ||= {};
  $event = str2code($name);

  throw Aurora::Exception("No valid event name supplied!")
    unless defined $event;
  throw Aurora::Exception("The supplied event options must be a HASH!")
    unless UNIVERSAL::isa($options, 'HASH');

  if($event == REDIRECT) {
    throw Aurora::Exception::Redirect
      ((map { ((join '','-',lc $_) => $options->{$_})} keys %{$options}));
  }
  else {
    throw Aurora::Exception::Event
      ((map { ((join '','-',lc $_) => $options->{$_})} keys %{$options}),
       -event => $event);
  }
}

=pod

=head1 NAME

XML::XSP::Taglib::Aurora::Event - This Taglib provides a mechanism for
generating Aurora events.

=head1 SYNOPSIS

  # To load taglib into XML::XSP
  use XML::XSP;
  $xsp = XML::XSP->new
    (Taglibs => ['XML::XSP::Taglib::Aurora::Event']);


  # Example of usage in an XSP Document
  <?xml version="1.0"?>
    <xsp:page language="perl"
      xmlns:xsp="http://apache.org/xsp/core/v1"
      xmlns:event="http://iterx.org/xsp/aurora/event/v1">

      <data>
        <event:redirect uri="http://iterx.org/"/>
        <event:throw code="302"  uri="http://iterx.org/"/>
      </data>
  </xsp:page>

=head1 DESCRIPTION

This module provides a mechanism for generating Aurora events within
an XSP page.

=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class.

=head1 TAGS

=over 3

=item * event:[event name]

This tag generates an Aurora event, with the event type being based
upon the name supplied (see L<Aurora::Constants> for a complete list
of possible event names).

=item * event:redirect

This tag generates an Aurora redirect event. This event requires the
specification of an additional uri attribute or child node which
contains the URI of location that the request should be redirected to.

=item * event:throw

This tag generates an Aurora event, based upon the value of the code
attribute provided. Parameters can be provided by specifying
additional attributes or child nodes. This tag is primarily provided
for handling user defined events.

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

L<XML::XSP>, L<Aurora>, L<Aurora::Constants>

=cut

1;

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:event="http://iterx.org/xsp/aurora/event/v1"
  version="1.0">

  <xsl:template match="node()[starts-with(namespace-uri(),'http://iterx.org/xsp/aurora/event')]">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>


  <xsl:template match="node()[starts-with(namespace-uri(),'http://iterx.org/xsp/aurora/event')]" mode="code">
  {
   my ($event, $name, %options);
   $event = $self-&gt;taglib('http://iterx.org/xsp/aurora/event/v1');
   <xsl:choose>
   <xsl:when test="local-name() = 'throw'">
   $name = <xsl:call-template name="as-string">
             <xsl:with-param name="string" select="@code"/>
           </xsl:call-template>;
   </xsl:when>
   <xsl:otherwise>
   $name = <xsl:call-template name="as-string">
             <xsl:with-param name="string" select="local-name()"/>
           </xsl:call-template>;
   </xsl:otherwise>
   </xsl:choose>

   <xsl:apply-templates select="@*|node()" mode="aurora.event.options"/>
   $event-&gt;throw($name =&gt; \%options);
  }
  </xsl:template>

  <xsl:template match="text()" mode="aurora.event.options"/>

  <xsl:template match="@*" mode="aurora.event.options">
  $options{<xsl:value-of select="local-name()"/>} =
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="current()"/>
    </xsl:call-template> || '';
  </xsl:template>

  <xsl:template match="node()" mode="aurora.event.options">
  $options{<xsl:value-of select="local-name()"/>} =
   <xsl:choose>
   <xsl:when test="text()">
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="text()"/>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>
   </xsl:otherwise>
   </xsl:choose> || '';
  </xsl:template>

</xsl:stylesheet>





