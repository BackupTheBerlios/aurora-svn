use Test;
BEGIN { plan tests => 7 };

use XML::XSP;

my ($processor, $document, $page, $result);
$processor = XML::XSP->new();

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<test><xsp:expr>1+2</xsp:expr></test>
</xsp:page>
XML

$page = $processor->page('#local1' => \$document);
ok(ref $page);

$result = $page->transform(\$document);
ok(stringify($result) eq '<?xmlversion="1.0"?><test>3</test>');

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<testing><xsp:expr>1+2</xsp:expr></testing>
</xsp:page>
XML

$result = $page->transform(\$document);
ok(stringify($result) eq '<?xmlversion="1.0"?><testing>3</testing>');

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<test><node><xsp:expr>1+2</xsp:expr></node><node>string</node></test>
</xsp:page>
XML

$result = $page->transform(\$document);
ok(stringify($result) eq 
   '<?xmlversion="1.0"?><test><node>3</node><node>string</node></test>');

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<test><node><xsp:expr>1+2</xsp:expr></node>
<node><xsp:expr>2+3</xsp:expr></node></test>
</xsp:page>
XML

$page = $processor->page('#local2' => \$document);
ok(ref $page);

$result = $page->transform(\$document);
ok(stringify($result) eq 
   '<?xmlversion="1.0"?><test><node>3</node><node>5</node></test>');

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<test><node><xsp:expr>1+2</xsp:expr></node>
<xsp:expr>2+3</xsp:expr></test>
</xsp:page>
XML

$result = $page->transform(\$document);
ok(stringify($result) eq 
   '<?xmlversion="1.0"?><test><node>3</node>5</test>');


sub stringify {
  my ($document) = @_;
  my ($str);
  $str = $document->toString;
  $str =~ s/\s//g;
  return $str;
}