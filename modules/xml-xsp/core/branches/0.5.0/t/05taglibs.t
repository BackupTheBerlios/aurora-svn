use Test;
BEGIN { plan tests => 6 };

use lib 'examples';
use MyTaglib;
use XML::XSP;

my ($processor, $taglib, $document, $page, $result);
$processor = XML::XSP->new(Taglibs => ['MyTaglib']);
ok(ref $processor);
$taglib = $processor->taglib($MyTaglib::NS);
ok(ref $taglib);

$processor = XML::XSP->new(Taglibs => ['MyTaglib' => {name => 'value'}]);
ok(ref $processor);
$taglib = $processor->taglib($MyTaglib::NS);
ok(ref $taglib && $taglib->{name} eq 'value');

$document = << "XML";
<?xml version="1.0"?>
<xsp:page language="perl"
xmlns:xsp="http://apache.org/xsp/core/v1"
xmlns:test="$MyTaglib::NS">
<test><test:hello/></test>
</xsp:page>
XML

$page = $processor->page('#local' => \$document);
ok(ref $page);
$result = $page->transform(\$document);
ok(stringify($result) eq '<?xmlversion="1.0"?><test>helloworld</test>');

sub stringify {
  my ($document) = @_;
  my ($str);
  $str = $document->toString;
  $str =~ s/\s//g;
  return $str;
}
