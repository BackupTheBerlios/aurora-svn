use Test;
BEGIN { plan tests => 48 };

use XML::Object qw/LibXML/;;
my ($o, $xml);

$xml = << 'XML';
<?xml version="1.0"?>
<document><child name="value">value</child></document>
XML

$o =  XML::Object->new(Input => \$xml);

# Nodes
ok($o->store('/document/child/element', 'new'));
ok($o->delete('/document/child/element') eq 'new');
ok($o->store('document/child/element', 'new'));
ok($o->delete('document/child/element') eq 'new');
ok($o->store('./document/child/element', 'new'));
ok($o->delete('./document/child/element') eq 'new');
ok($o->store('/document/child/@attribute', 'new'));
ok($o->delete('/document/child/@attribute') eq 'new');
ok($o->store('/document/child/element/text()', 'new'));
ok($o->delete('/document/child/element') eq 'new');

# Axis
ok($o->store('/document/child/../child/element', 'new'));
ok($o->delete('/document/child/element') eq 'new');
ok($o->store('/document/child/./element', 'new'));
ok($o->delete('/document/child/element') eq 'new');
ok($o->store('/document/child/attribute::attribute', 'new'));
ok($o->delete('/document/child/@attribute') eq 'new');
ok($o->store('/document/child/child::element', 'new'));
ok($o->delete('/document/child/element') eq 'new');
ok($o->store('/document/child/parent::child/child/element', 'new'));
ok($o->delete('/document/child/element') eq 'new');
ok($o->store('/document/child/self::node()/element', 'new'));
ok($o->delete('/document/child/element') eq 'new');

# Predicates
ok($o->store('/document/child[@name="value"]/element', 'new'));
ok($o->delete('/document/child[@name="value"]/element') eq 'new');
ok($o->store('/document/child[@new="value"]/element', 'new'));
ok($o->delete('/document/child[@new="value"]/element') eq 'new');
ok(!defined $o->delete('/document/child[@new]'));
ok($o->store('/document/child[element/@new="value"]/element',
	     'new'));
ok($o->delete('/document/child/element[@new="value"]') eq 'new');
ok(!defined $o->delete('/document/child[2]'));
ok($o->store('/document/child[@name="test"][2]/element', 'new'));
ok($o->delete('/document/child[3]/element') eq 'new');
ok(!defined $o->delete('/document/child[3]'));
ok(!defined $o->delete('/document/child[2]'));
ok($o->store('/document/child[@new="value" and @old="value"]','new'));
ok($o->delete('/document/child[@new="value" and @old="value"]') eq 'new');


# Functions
ok($o->store('/document/node()[name() = "child"]/element', 'new'));
ok($o->delete('/document/node()[name() = "child"]/element') eq 'new');
ok($o->store('/document/node()[local-name() = "child"]/element', 'new'));
ok($o->delete('/document/node()[local-name() = "child"]/element') eq 'new');
ok($o->store('/document/node()[name() = "child" and position() = 1]/element', 'new'));
ok($o->delete('/document/node()[name() = "child" and position() = 1]/element') eq 'new');
ok($o->store('/document/child[position() = 2]/element', 'new'));
ok($o->delete('/document/child[position() = 2]/element') eq 'new');
ok(!defined $o->delete('/document/child[position() = 2]'));
ok($o->store('/document/child[2]', 'new'));
ok($o->store('/document/child[last()]/element', 'new'));
ok($o->delete('/document/child[2]') eq  'new');


