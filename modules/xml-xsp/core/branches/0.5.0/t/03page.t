use Test;
BEGIN { plan tests => 9 };

use XML::XSP;

my ($processor, $document, $page, $result);
$processor = XML::XSP->new();

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<test><xsp:expr>1+2</xsp:expr></test>
</xsp:page>
XML

$document = $processor->driver->document(\$document);

$page = $processor->page('#local-a' => $document);
ok(ref $page);

$result = $page->transform($document);
ok(ref $result);
ok(stringify($result) eq '<?xmlversion="1.0"?><test>3</test>');


$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<xsp:element name="element"></xsp:element>
</xsp:page>
XML

$document = $processor->driver->document(\$document);

$page = $processor->page('#local-b' => $document);
ok(ref $page);

$result = $page->transform($document);
ok(ref $result);
ok(stringify($result) eq '<?xmlversion="1.0"?><element/>');

$document = << 'XML';
<?xml version="1.0"?>
<root>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<xsp:element name="element"></xsp:element>
</xsp:page>
</root>
XML

$document = $processor->driver->document(\$document);

$page = $processor->page('#local-c' => $document);
ok(ref $page);

$result = $page->transform($document);
ok(ref $result);
ok(stringify($result) eq '<?xmlversion="1.0"?><root><element/></root>');


sub stringify {
  my ($document) = @_;
  my ($str);
  $str = $document->toString;
  $str =~ s/\s//g;
  return $str;
}
