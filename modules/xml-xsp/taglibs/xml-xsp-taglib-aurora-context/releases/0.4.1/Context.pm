package XML::XSP::Taglib::Aurora::Context;
use strict;
use XML::XSP;
use XML::XSP::Taglib;

use Aurora::Constants;
use Aurora::Resource;
use Aurora::Exception qw/:try/;

use vars qw/@ISA $NS $VERSION/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://iterx.org/xsp/aurora/context/v1';
$VERSION = '0.4.1';

sub dependancy {
  my ($self, $context, $uri, $options) = @_;
  my ($rib, $base);
  $base = $options->{base} || $context->request->base;

  try {
    ($uri) = ($uri =~ m/^\s*(.*?)\s*$/);
    ($base) = ($base =~ m/^\s*(.*?)\s*$/);
    $rib = Aurora::Resource->fetch($uri, {base => $base});
    if(defined $rib) {
      $context->dependancy(resource => $rib);
    }
  }
  otherwise {
    logwarn(shift);
  };
  return;
}

sub status {
  my ($self, $context, $status) = @_;
  unless ($status =~/^-?\d+$/) {
    eval {
      no strict 'refs';
      $status = &{(join '::','Aurora::Constants', (uc $status))};
    };
    if($@) {
      # should log warning
      return;
    }
  }
  $context->response->status($status);
  return;
}

=pod

=head1 NAME

XML::XSP::Taglib::Aurora::Context - An XSP taglib to access the
current Aurora context object.


=head1 SYNOPSIS

  # To load the taglib into XML::XSP
  use XML::XSP;
  $xsp = XML::XSP->new(Taglibs => ['XML::XSP::Taglib::Aurora::Context']);


  # Example of usage in an XSP Document
  <?xml version="1.0"?>
  <xsp:page language="perl"
    xmlns:xsp="http://apache.org/xsp/core/v1"
    xmlns:context="http://iterx.org/xsp/aurora/context/v1"
    xmlns:cookies="http://iterx.org/xsp/aurora/context/cookies/v1"
    xmlns:request="http://iterx.org/xsp/aurora/context/request/v1"
    xmlns:response="http://iterx.org/xsp/aurora/context/response/v1" >

  <data>
    <context:dependancy uri="file:///tmp/file" />
    <p><request:method/></p>

    # URI
    <p><request:uri/></p>
    <p><request:uri-scheme/></p>
    <p><request:uri-host/></p>
    <p><request:uri-path/></p>
    <p><request:uri-fragment/></p>
    <p><request:uri-query/></p>

    # HTTP Headers
    <p><request:accept/></p>
    <p><request:user-agent/></p>
    <p><response:content-type>text/html</response:content-type></p>
    <p><response:code value="404" /></p>

    # Request Parameters
    <p><request:param name="a"/></p>
    <p><request:param name="b">default</request:param></p>

    # Response Status
    <p><response:status value="DONE"/></p>

    #Connection
    <p><connection:user/></p>
    <p><connection:ip/></p>
    <p><connection:host/></p>

    # Cookies
    <p><cookie:get name="a"/></p>
    <p><cookie:get name="b">default</cookie:get></p>

    <p><cookie:set name="d" expires="1d" value="value"/></p>
    <p>
       <cookie:set name="d" domain=".iterx.org">
       <cookie:expires>1d</cookie:expires>
       <cookie:value>value</cookie:value>
       </cookie:set>
    </p>
  </data>
  </xsp:page>

=head1 DESCRIPTION

This module provides an XSP interface to the current Aurora context
object. With this taglib, it is possible to interrogate the current
request, set response headers and manipulate cookies. 


=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class.

=head1 XSP TAGS

=over 18

=item * connection:host

Returns the hostname for the current clients connection.

=item * connection:ip

Returns the IP address for the current clients connection.

=item * connection:user

Returns the username for the current clients connection, if this
connection has been authenticated.

=item * context:dependancy

Adds an object dependancy (as specified by the uri attribute or the
tags value) to the current context.


=item * cookie:get

Retrieves the value of the named cookie parameter (as specified by
the name attribute or the tags value).

=item * cookie:set

Sets the cookie named parameter, with the value specified by the value
attribute or the tags value. Additionally, expires and domain
attributes can specifed, to set these at the same time. The cookie
domain defaults to the current server domain.

=item * cookie:expires

Sets the cookie expires time.

=item * request:[header]

Gets the value of the request header specified.

=item * request:param

Retrieves the value of the named request parameter (as specified by
the name attribute or the tags value).

=item * request:method

The HTTP method of the request.

=item * request:uri

The full incomming request URI.

=item * request:uri-scheme

The scheme of the incomming HTTP request.

=item * request:uri-host

The hostname of the incomming HTTP request.

=item * request:uri-path

The path of the incomming HTTP request.


=item * request:uri-query

The URI query string for the incomming HTTP request.

=item * request:uri-fragment

The URI fragment for the incomming HTTP request.

=item * response:[header]

Sets the response header, with the value specified by the value
attribute or the tags value.

=item * response:status

Sets the status code of the response, the value specified by the value
attribute or the tags value.

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

1;

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:context="http://iterx.org/xsp/aurora/context/v1"
  xmlns:cookie="http://iterx.org/xsp/aurora/context/cookie/v1"
  xmlns:connection="http://iterx.org/xsp/aurora/context/connection/v1"
  xmlns:request="http://iterx.org/xsp/aurora/context/request/v1"
  xmlns:response="http://iterx.org/xsp/aurora/context/response/v1"
  version="1.0">

  <xsl:template match="node()[starts-with(namespace-uri(),
  'http://iterx.org/xsp/aurora/context')]">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>

  <xsl:template match="request:method" mode="code">
  $options-&gt;{context}-&gt;request-&gt;method
  </xsl:template>

  <xsl:template match="request:uri" mode="code">
  (join '', $options-&gt;{context}-&gt;request-&gt;uri, '')
  </xsl:template>

  <xsl:template match="request:uri-scheme|request:uri-host|request:uri-path|request:uri-query|request:uri-fragment" mode="code">
  <xsl:variable name="part"><xsl:value-of select="substring-after(local-name(.),'-')"/></xsl:variable>
  $options-&gt;{context}-&gt;request-&gt;uri-&gt;<xsl:value-of select="$part"/>
  </xsl:template>

  <xsl:template match="request:accept|request:date|request:expires|request:last-modified|request:content-type|request:content-encoding|request:content-length|request:content-language|request:user-agent|request:referer" mode="code">
  <xsl:variable name="header"><xsl:value-of select="local-name(current())"/></xsl:variable>
  $options-&gt;{context}-&gt;request-&gt;header('<xsl:value-of select="$header"/>')
  </xsl:template>

  <xsl:template match="request:param[@name]" mode="code">
  ($options->{context}->request->param
   (<xsl:call-template name="as-string">
      <xsl:with-param name="string" select="@name"/>
    </xsl:call-template>) ||
    <xsl:call-template name="as-expr">
     <xsl:with-param name="node" select="current()"/>
    </xsl:call-template> || '')
  </xsl:template>

  <xsl:template match="context:dependancy" mode="code">
  do {
   my ($context, $uri, %options);

   $context = $self-&gt;taglib('http://iterx.org/xsp/aurora/context/v1');

   $uri =
   <xsl:choose>
   <xsl:when test="@uri">
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="@uri"/>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="context:uri"/>
    </xsl:call-template>
   </xsl:otherwise>
   </xsl:choose> || '';

   $options{base} =
   <xsl:choose>
   <xsl:when test="@base">
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="@base"/>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="context:base"/>
    </xsl:call-template>
   </xsl:otherwise>
   </xsl:choose> || '';

   $context-&gt;dependancy($options-&gt;{context}, $uri, \%options);
   '';
  }
  </xsl:template>

  <xsl:template
  match="response:code|response:content-type|response:expires|response:charset|response:content-encoding"
  mode="code">
  do {
    $options-&gt;{context}-&gt;response-&gt;<xsl:value-of select="translate(local-name(),'-','_')"/>
      (
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="@value"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
     <xsl:with-param name="node" select="current()"/>
    </xsl:call-template> || '');
    '';
  }
  </xsl:template>

  <xsl:template match="response:status" mode="code">
  do {
   my ($context, $status);

   $context = $self-&gt;taglib('http://iterx.org/xsp/aurora/context/v1');

   $status = <xsl:call-template name="as-string">
   <xsl:with-param name="string" select="@value"/>
   </xsl:call-template> ||
   <xsl:call-template name="as-expr">
   <xsl:with-param name="node" select="current()"/>
   </xsl:call-template> || '';

   $context-&gt;status($options-&gt;{context}, $status);
   '';
  }
  </xsl:template>

  <xsl:template match="connection:host" mode="code">
  $options-&gt;{context}-&gt;connection-&gt;host
  </xsl:template>

  <xsl:template match="connection:ip" mode="code">
  $options-&gt;{context}-&gt;connection-&gt;ip
  </xsl:template>

  <xsl:template match="connection:user" mode="code">
  $options-&gt;{context}-&gt;connection-&gt;user
  </xsl:template>

  <xsl:template match="cookie:get" mode="code">
  <xsl:if test="@name">
  do {
  my ($cookie);
  $cookie = $options-&gt;{context}-&gt;request-&gt;cookie
    ('<xsl:value-of select="@name"/>');
  (defined $cookie)? $cookie->value :
   <xsl:call-template name="as-expr">
     <xsl:with-param name="node" select="current()"/>
   </xsl:call-template>
  }
  </xsl:if>
  </xsl:template>

  <xsl:template match="cookie:set" mode="code">
  <xsl:if test="@name or cookie:name">
  do {
    my (%cookie);
    $cookie{name} =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@name"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()/cookie:name"/>
    </xsl:call-template>;
    $cookie{value} =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@value"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()/cookie:value"/>
    </xsl:call-template>;
    $cookie{domain} =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@domain"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()/cookie:domain"/>
    </xsl:call-template> ||
      $options -&gt;{context}-&gt;request-&gt;uri->host;
    $cookie{domain} = (join '', '.',$cookie{domain})
      unless ( $cookie{domain} =~ tr/\./\./ ) &gt; 1;
    $cookie{path} =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@path"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()/cookie:path"/>
    </xsl:call-template> || $options->{context}->request-&gt;uri-&gt;path;
    $cookie{path} = substr($cookie{path},0,rindex($cookie{path},'/'));
    <xsl:if test="@expires or cookie:expires">
    $cookie{expires} =
    <xsl:call-template name="as-string">
    <xsl:with-param name="string" select="@expires"/>
    </xsl:call-template> ||
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()/cookie:expires"/>
    </xsl:call-template>;
    </xsl:if>
    $options-&gt;{context}-&gt;response-&gt;cookie(%cookie);
    '';
  }
  </xsl:if>
  </xsl:template>

</xsl:stylesheet>
