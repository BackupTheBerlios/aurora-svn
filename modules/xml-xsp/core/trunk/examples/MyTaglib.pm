package MyTaglib;

use strict;

use XML::XSP::Taglib;
use vars qw/@ISA $NS/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://itex.org/xsp/mytaglib/v1';

sub new {
  my ($class, %options) = @_;
  return bless \%options, $class;
}

1;

__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:mytaglib="http://itex.org/xsp/mytaglib/v1"
  version="1.0">

<xsl:template match="node()[namespace-uri() = 'http://itex.org/xsp/mytaglib/v1']">
<xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
</xsl:template>

<xsl:template match="mytaglib:hello" mode="code">
'hello world'
</xsl:template>




</xsl:stylesheet>
