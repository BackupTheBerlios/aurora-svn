use Test;
BEGIN { plan tests => 20 };

use XML::Object qw/LibXML/;;
my ($o, $xml);

$xml = << 'XML';
<?xml version="1.0"?>
<ns:document xmlns:ns="#local">
  <ns:child attribute="value1" ns:attribute="value2">value</ns:child>
</ns:document>
XML

$o =  XML::Object->new(Input => \$xml);

ok($o->fetch('/ns:document/ns:child') eq 'value');
ok($o->fetch('/ns:document/ns:child/@attribute') eq 'value1');
ok($o->fetch('/ns:document/ns:child/@ns:attribute') eq 'value2');
ok($o->fetch((join '',
	      '/ns:document/node()[namespace-uri() = \'#local\' ',
	      'and local-name() = \'child\']')) eq 'value');

ok($o->store('/ns:document/ns:child/element', 'new'));
ok($o->delete('/ns:document/ns:child/element') eq 'new');
ok($o->store('/ns:document/ns:child/ns:element', 'new'));
ok($o->delete((join '',
	       '/ns:document/ns:child/node()[namespace-uri() = \'#local\' ',
	       'and local-name() = \'element\']')) eq 'new');
ok($o->store('/ns:document/ns:child/@ns:attribute', 'new'));
ok($o->delete((join '',
	       '/ns:document/ns:child/@*[namespace-uri() = \'#local\' ',
	       'and local-name() = \'attribute\']')) eq 'new');

ok($o->namespace('#local') eq 'ns');
ok(!defined $o->namespace('#remote'));
ok($o->namespace('#remote' => 'remote'));
ok($o->namespace('#remote') eq 'remote');
ok($o->store('/ns:document/ns:child/remote:element', 'new'));
ok($o->delete('/ns:document/ns:child/remote:element') eq 'new');
ok($o->store('/ns:document/ns:child/node()[name() = "new:element" and namespace-uri()="#new"]', 'new'));
ok($o->delete('/ns:document/ns:child/node()[name() = "new:element" and namespace-uri()="#new"]') eq 'new');

$o->clear;
$o->namespace('#local' => 'local');
ok($o->store('/local:document', 'new'));
ok($o->fetch('/local:document') eq 'new');


