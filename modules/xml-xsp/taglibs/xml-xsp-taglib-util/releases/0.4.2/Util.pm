package XML::XSP::Taglib::Util;
use strict;

use LWP;
use POSIX;
use Cwd qw/cwd/;

use LWP::UserAgent;

use XML::XSP;
use XML::XSP::Taglib;

use vars qw/@ISA $NS $VERSION/;
@ISA = qw/XML::XSP::Taglib/;

$NS = 'http://apache.org/xsp/util/v1';
$VERSION = '0.4.2';

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 base => ($options{Base} ||
			  (join '', 'file://', cwd()))
		}, $class;
  return $self;
}

sub resource {
  my ($self, $page, $document, $uri) = @_;
  my ($xml, $fragment);
  $uri = (join '/',$self->{base}, $uri)
    if $self->{base} && $uri !~ /^(\w+):\/\// ;
  $uri =~ s/([^:\/])\/\//$1\//g;
 SWITCH: {
    ($uri =~ /^file:\/\// || $uri !~ /:\/\// ) && do {
      my ($file);
      $file = (index($uri, 'file://') != -1)? substr($uri,7) : $uri;
      $file = substr($file, 0, index($file, '#')) if index($file, '#') != -1;
      if(-e $file) {
        local $/ = undef;
        open FILE, $file;
        $xml = <FILE>;
        close FILE;
        last SWITCH;
      }
    };
    ($uri =~ m/^http(s)?:\/\//) && do {
      my ($agent, $request, $response);
      $agent = LWP::UserAgent->new();
      $agent->timeout(15);
      $request = HTTP::Request->new(HEAD => $uri);
      $response = $agent->request($request);
      if($response->is_success) {
	$xml = $response->content;
      }
      last SWITCH;
    };
  };

  if($xml =~ /^\s*\<\?xml(.*?)\?\>/) {
    $xml = $page->driver->document(\$xml);
    $fragment = $xml->documentElement;
  }
  else {
    $fragment = $document->createTextNode($xml);
  }
  return $fragment;
}



1;

__END__
=pod

=head1 NAME

XML::XSP::Taglib::Util - An implementation of the XSP Util Taglib for
XML::XSP.

=head1 SYNOPSIS

  # To load Taglib into XML::XSP
  use XML::XSP;
  $xsp = XML::XSP->new(taglibs => ['XML::XSP::Taglib::Util']);

  # Example of usage in an XSP Document
  <?xml version="1.0"?>
  <xsp:page language="perl"
    xmlns:xsp="http://apache.org/xsp/core/v1"
    xmlns:util="http://apache.org/xsp/util/v1">
    <files>
     <timestamp><util:time format="%Y-%m-%dT%H:%M+00:00"/></timestamp>
    <local>
      <util:include-file>
       <util:name>file:///tmp/file.xml</util:name>
     </util:include-file>
    </local>
    <remote>
      <util:include-uri>
        <util:href>http://localhost/file.xml</util:href>
      </util:include-uri>
    </remote>
   </files>
  </xsp:page>

=head1 DESCRIPTION

This module provides an implementation of the XSP Util Taglib for
XML::XSP. The XSP Util Taglib adds a few general purpose tags for
dealing with displaying the time and for including external documents
within the current one.

=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::TaglibFactory class. This Taglib takes the following
optional parameters:

=over 1

=item * Base

Set the base directory or URI for all relative URIs supplied. By
default this is set to the current work directory.

=back

=head1 XSP TAGS

=over 3

=item * util:time

Display the current time. Takes an optional format attribute, which
specifies the POSIX::strftime format that the time should display as.

=item * util:include-file

The util:include-file tag imports a file from the local filesystem and
inserts the content into the current document. This tag can have one
child element:

=over 1

=item * util:name

util:name is either an xsp:expr or string that contains the path of
the file to be included.

=back


=item * util:include-uri

The util:include-uri tag imports a file from a remote location and
it's content into inserted into the current document. This tag can
have one child element:

=over 1

=item * util:href

util:href is either an xsp:expr or string that contains the URI of the
file to be included.

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

L<XML::XSP>

=cut

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:util="http://apache.org/xsp/util/v1"
  version="1.0">

  <xsl:template match="node()[namespace-uri() = 'http://apache.org/xsp/util/v1']">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>

  <xsl:template match="util:time" mode="code">
  POSIX::strftime('<xsl:value-of select="@format"/>', localtime);
  </xsl:template>

  <xsl:template match="util:include-file" mode="code">
  {
  <xsl:if test="util:name">
   my ($util);
   $util = $self-&gt;taglib('http://apache.org/xsp/util/v1');
    $util-&gt;resource
    ($self,$document,
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="util:name"/>
    </xsl:call-template>
   );
  </xsl:if>
  }
  </xsl:template>

  <xsl:template match="util:include-uri" mode="code">
  {
  <xsl:if test="util:href">
    my ($util);
    $util = $self-&gt;taglib('http://apache.org/xsp/util/v1');
    $util-&gt;resource
    ($self,$document,
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="util:href"/>
    </xsl:call-template>
    );
  </xsl:if>
  }
  </xsl:template>

</xsl:stylesheet>
