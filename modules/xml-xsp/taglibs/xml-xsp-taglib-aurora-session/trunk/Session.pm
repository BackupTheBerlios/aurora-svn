package XML::XSP::Taglib::Aurora::Session;
use strict;

use XML::XSP;
use XML::XSP::Taglib;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use vars qw/@ISA $NS $VERSION/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://iterx.org/xsp/aurora/session/v1';
$VERSION = '0.4.1';


# should add options to deal with deep nested datastructures being saved.

=head1 NAME

XML::XSP::Taglib::Aurora::Session - An XSP taglib to access or create
the current Aurora session object.

=head1 SYNOPSIS

  # To load the taglib into XML::XSP
  use XML::XSP;
  $xsp = XML::XSP->new
    (Taglibs => ['XML::XSP::Taglib::Aurora::Session']);

  # Example of usage in an XSP document
  <?xml version="1.0"?>
  <xsp:page language="perl"
    xmlns:xsp="http://apache.org/xsp/core/v1"
    xmlns:session="http://iterx.org/xsp/aurora/session/v1"
    create-session="yes">

    <p><session:id/></p>
    <p><session:expires/></p>
    <p><session:user/></p>
    <p><session:is-new/></p>
    <p><session:is-valid/></p>

    <p><session:get name="a"/></p>
    <p><session:remove name="a"/></p>

    <session:restore/>

    <p><session:set name="a" value="b"/></p>

    <session:save/>
    <session:invalidate/>

  </xsp:page>

=head1 DESCRIPTION

This module provides an XSP interface to the current Aurora session
object or the option to create a new session if none currently exists.

=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class.

=head1 XSP TAGS

=over 11

=item * session:expires

This tag returns the current expires time for the session. If a child
xsp:expr element or string are supplied, then the expires time for the
session is set to that value.

=item * session:get

This tag gets the session value for the supplied name key, as
determined by the name attribute.

=item * session:id

Returns the current session id.

=item * session:invalidate

This tag causes the current session to be invalidated and removed from
the session store.

=item * session:is-new

Returns a bool indicating if the session has been created during the
request and has not yet been saved to the session store.

=item * session:is-valid

Returns a bool indicating if the current session is valid and hasn't
expired yet.

=item * session:remove

This tag removes the session value for the supplied name key, as
determined by the name attribute.

=item * session:restore

This tag causes the current session to be restored to the state it was
in the last time this session was saved.

=item * session:save

This tag causes the current session to be saved to the session cache.

=item * session:set

This tag sets the session value for the supplied name key, as
determined by the name attribute, with the value of child node.

=item * session:user

Returns the username associated with the current session.

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

L<XML::XSP>, L<Aurora>, L<Aurora::Session>

=cut

1;

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:session="http://iterx.org/xsp/aurora/session/v1"
  version="1.0">

  <xsl:template match="session:*">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>

  <xsl:template match="xsp:page[@language='perl']/@create-session">
  <xsp:logic>
  $options-&gt;{context}-&gt;session
  (undef, {create =&gt; '<xsl:value-of select="."/>'});
  </xsp:logic>
  </xsl:template>

  <xsl:template match="session:id|session:create-date|session:last-access|session:is-new|session:is-valid|session:user"
  mode="code">
  do {
    my ($session);
    $session = $options-&gt;{context}-&gt;session;
    $session-&gt;<xsl:value-of select="translate(local-name(),'-','_')"/>
      if $session;
  }
  </xsl:template>

  <xsl:template match="session:expires"
  mode="code">
  do {
    my ($session, $value);
    $session = $options-&gt;{context}-&gt;session;
    $value =
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="@value"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template> || undef;
    $session-&gt;<xsl:value-of select="translate(local-name(),'-','_')"/>
      (Aurora::Util::str2time($value)) if $session;
  }
  </xsl:template>



  <xsl:template match="xsp:page//session:*[not(following::node()[starts-with(namespace-uri(),'http://iterx.org/xsp/aurora/session')])]">
  <!-- this is broken in the case of session being in an if block-->
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  <xsp:logic>
  {
  my ($session);
  $session = $options-&gt;{context}-&gt;session;
  $session-&gt;save if $session;
  }
  </xsp:logic>
  </xsl:template>


  <xsl:template match="session:get" mode="code">
  <xsl:if test="@name">
  do {
  my ($session, $value);
  $session = $options-&gt;{context}-&gt;session;
  $value = $session->get
    ('<xsl:value-of select="@name"/>') if $session;
  (defined $value)? $value :
   <xsl:call-template name="as-expr">
     <xsl:with-param name="node" select="current()"/>
   </xsl:call-template>
  }
  </xsl:if>
  </xsl:template>

  <xsl:template match="session:remove" mode="code">
  <xsl:if test="@name">
  do {
  my ($session, $value);
  $session = $options-&gt;{context}-&gt;session;
  $value = $session->put
    ('<xsl:value-of select="@name"/>',undef) if $session;
  }
  </xsl:if>
  </xsl:template>


  <xsl:template match="session:set" mode="code">
  <xsl:if test="@name">
  do {
    my ($session, $name, $value);
    $session = $options-&gt;{context}-&gt;session;
    $name =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@name"/>
    </xsl:call-template> ;
    $value =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@value"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template> || undef;
    $session-&gt;put($name, $value) if $session;
    '';
  }
  </xsl:if>
  </xsl:template>

  <xsl:template match="session:restore" mode="code">
  do {
    my ($session);
    $session = $options-&gt;{context}-&gt;session;
    $session-&gt;restore if $session;
    '';
  }
  </xsl:template>

  <xsl:template match="session:invalidate" mode="code">
  do {
    my ($session);
    $session = $options-&gt;{context}-&gt;session;
    $session-&gt;invalidate if $session;
    '';
  }
  </xsl:template>

  <xsl:template match="session:save" mode="code">
  do {
    my ($session, $expires);
    $session = $options-&gt;{context}-&gt;session;
    $expires =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@expires"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()/session:expires"/>
    </xsl:call-template> || 0;
    $session-&gt;save(expires =&gt;
		      Aurora::Util::str2time($expires)) if $session;
    '';
  }
  </xsl:template>

</xsl:stylesheet>
