use Test;
BEGIN { plan tests => 4 };

use XML::XSP;
use XML::XSP::PageFactory;
use XML::XSP::DriverFactory;
use XML::XSP::TaglibFactory;



my ($driver, $taglib, $processor, $document, $page);

$driver = XML::XSP::DriverFactory->create('XML::XSP::Driver::LibXSLT');
ok(ref $driver);

$taglib = XML::XSP::TaglibFactory->create('XML::XSP::Taglib::Core');
ok(ref $taglib);

$processor = XML::XSP->new;

$document = << 'XML';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<test><xsp:expr>1+2</xsp:expr></test>
</xsp:page>
XML

$page = XML::XSP::PageFactory->create($processor, \$document);
ok(ref $page);

$document = $processor->driver->document(\$document);
$page = XML::XSP::PageFactory->create($processor, '#local2' => $document);
ok(ref $page);

# add test for filehandle
