package XML::XSP::Taglib::Aurora::Resource;
use strict;

use XML::XSP;
use XML::XSP::Taglib;

use Aurora::Log;
use Aurora::Server;
use Aurora::Resource;
use Aurora::Exception qw/:try/;

use vars qw/@ISA $NS $VERSION/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://iterx.org/xsp/aurora/resource/v1';
$VERSION = '0.4.2';


sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
                 base => ($options{Base} || Aurora::Server->base)
                }, $class;
  return $self;
}

sub is_valid {
  my ($self, $uri, $options) = @_;
  my ($rib, $valid, $base);
  $base = $options->{base} || $self->{base};

  try {
    ($uri) = ($uri =~ m/^\s*(.*?)\s*$/);
    ($base) = ($base =~ m/^\s*(.*?)\s*$/);
    $rib = Aurora::Resource->fetch($uri, { base => $base });
    $valid = ($rib->is_valid)? 1 : 0;
  }
  otherwise {
    logwarn(shift);
  };

  return $valid;
}

sub exists {
  my ($self, $uri, $options) = @_;
  my ($rib, $exists, $base);
  $base = $options->{base} || $self->{base};
  $exists = 0;

  try {
    ($uri) = ($uri =~ m/^\s*(.*?)\s*$/);
    ($base) = ($base =~ m/^\s*(.*?)\s*$/);
    $rib = Aurora::Resource->fetch($uri, {base => $base});
    $exists = 1;
  }
  otherwise {
    logwarn(shift);
  };
  return $exists;
}


sub fetch {
  my ($self, $uri, $options) = @_;
  my ($page, $document, $context, $base, $rib, $object, $fragment);
  $page = delete $options->{page};
  $document = delete $options->{document};
  $context = delete $options->{context};
  $base = $options->{base} || $self->{base} || $context->request->base;

  try {
    ($uri) = ($uri =~ m/^\s*(.*?)\s*$/);
    ($base) = ($base =~ m/^\s*(.*?)\s*$/);
    $rib = Aurora::Resource->fetch($uri, {base => $base});
    if(defined $rib) {
      $object = $rib->object;
      $context->dependancy(resource => $rib);
    }
  }
  otherwise {
    logwarn(shift);
  };
  if(defined $object) {
  SWITCH: {
      $object =~ /^\s*\<\?xml(.*?)\?\>/ && do {
	my ($xml);
	$xml = $page->driver->document(\$object);
	$fragment = $xml->getDocumentElement;
	last SWITCH;
      };
      # should check for extended chars -> then base64 encode
      do {
	$fragment = $document->createCDATASection($object);
      };
    };
  }
  return $fragment;
}

=pod

=head1 NAME

XML::XSP::Taglib::Aurora::Resource - An XSP taglib to access resources
via Aurora.

=head1 SYNOPSIS

  # To load taglib into XML::XSP
  use XML::XSP;
  $xsp = XML::XSP->new
    (Taglibs => ['XML::XSP::Taglib::Aurora::Resource']);


  # Example of usage in an XSP Document
  <?xml version="1.0"?>
    <xsp:page language="perl"
      xmlns:xsp="http://apache.org/xsp/core/v1"
      xmlns:resource="http://iterx.org/xsp/aurora/resource/v1">

      <data>
        <p><resource:fetch uri="examples/test.xml" /></p>
        <p>
           <resource:fetch>
	     <resource:uri>examples/test.xml</resource:uri>
           </resource:fetch>
        </p>
        <p>
          <resource:fetch>
	    <resource:uri>examples/test.xml</resource:uri>
	    <resource:base>file:///tmp</resource:base>
          </resource:fetch>
        </p>

        <p><resource:is-valid uri="examples/test.txt"/></p>

        <p><resource:exists uri="examples/test.txt"/></p>

     </data>
  </xsp:page>

=head1 DESCRIPTION

This module provides an XSP interface to the Aurora::Resource class,
enabling you to load and manipulate resources, while ensuring that
context dependancies are kept upto date.

=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class. This Taglib takes the following
optional parameters:

=over 1

=item * Base

Set the base directory or URI for all relative URIs supplied. By
default this is set to the current work directory.

=back

=head1 TAGS

=over 3

=item * resource:fetch

This tag imports a resource from the specified URI and inserts the
content into the current document. This tag can have two child
elements:

=over 2

=item * resource:uri

This is either an xsp:expr or string that contains the URI of
the resource. For convience, this can also be used as an attribute in
the resource:fetch tag.


=item * resource:base

This is either an xsp:expr or string that contains the base URI of
the resource, which is used when resolving relative URIs. For
convience, this can also be used as an attribute in the resource:fetch
tag.

=back

=item * resource:is_valid

This tag checks to see if the specified resource is valid and hasn't
yet expired. This tag can have two child elements:

=over 2

=item * resource:uri

This is either an xsp:expr or string that contains the URI of
the resource. For convience, this can also be used as an attribute in
the resource:fetch tag.


=item * resource:base

This is either an xsp:expr or string that contains the base URI of
the resource, which is used when resolving relative URIs. For
convience, this can also be used as an attribute in the resource:fetch
tag.

=back

=item * resource:exists

This tag checks to see if the specified resource exists and is
readable. This tag can have two child elements:

=over 2

=item * resource:uri

This is either an xsp:expr or string that contains the URI of
the resource. For convience, this can also be used as an attribute in
the resource:fetch tag.


=item * resource:base

This is either an xsp:expr or string that contains the base URI of
the resource, which is used when resolving relative URIs. For
convience, this can also be used as an attribute in the resource:fetch
tag.

=back

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

L<XML::XSP>, L<Aurora>, L<Aurora::Resource>

=cut

1;

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:resource="http://iterx.org/xsp/aurora/resource/v1"
  version="1.0">

  <xsl:template match="node()[starts-with(namespace-uri(),'http://iterx.org/xsp/aurora/resource')]">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>

  <xsl:template match="resource:fetch" mode="code">
  {
   my ($resource, $uri, %options);
   $resource = $self-&gt;taglib('http://iterx.org/xsp/aurora/resource/v1');
   <xsl:call-template name="aurora.resource.set-options">
     <xsl:with-param name="current" select="current()"/>
   </xsl:call-template>
   $options{page} = $self;
   $options{document} = $document;
   $options{context} = $options-&gt;{context};
   $resource-&gt;fetch($uri, \%options);
  }
  </xsl:template>

  <xsl:template match="resource:is-valid" mode="code">
  {
   my ($resource, $uri, %options);
   $resource = $self-&gt;taglib('http://iterx.org/xsp/aurora/resource/v1');
   <xsl:call-template name="aurora.resource.set-options">
     <xsl:with-param name="current" select="current()"/>
   </xsl:call-template>
   $resource-&gt;is_valid($uri, \%options);
  }
  </xsl:template>


  <xsl:template match="resource:exists" mode="code">
  {
   my ($resource, $uri, %options);
   $resource = $self-&gt;taglib('http://iterx.org/xsp/aurora/resource/v1');
   <xsl:call-template name="aurora.resource.set-options">
     <xsl:with-param name="current" select="current()"/>
   </xsl:call-template>
   $resource-&gt;exists($uri, \%options);
  }
  </xsl:template>

  <xsl:template name="aurora.resource.set-options">
  <xsl:param name="current"/>
   $uri =
   <xsl:choose>
   <xsl:when test="@uri">
    <xsl:call-template name="as-string">
      <xsl:with-param name="string" select="@uri"/>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="$current/resource:uri"/>
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
      <xsl:with-param name="node" select="$current/resource:base"/>
    </xsl:call-template>
   </xsl:otherwise>
   </xsl:choose> || '';
  </xsl:template>

</xsl:stylesheet>





