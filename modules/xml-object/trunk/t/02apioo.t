use Test;
BEGIN { plan tests =>  21 };

use XML::Object qw/LibXML/;;
my ($o, $xml);

$xml = << 'XML';
<?xml version="1.0"?>
<document><child attribute="value">value</child></document>
XML

$o =  XML::Object->new(Input => \$xml);

# EXISTS
ok($o->exists('/document/child'));
ok($o->exists('/document/child/@attribute'));
ok(!$o->exists('/document/child/bogus'));
ok($o->exists('//node()|@*') == 3);

# FETCH
ok($o->fetch('/document/child') eq 'value');
ok(!defined $o->fetch('/document/child/bogus'));
ok($o->fetch('/document/child/@attribute') eq 'value');
ok(scalar @{$o->fetch('//node()|@*')} == 3);

# STORE
ok($o->store('/document/child/@attribute', 'new'));
ok($o->fetch('/document/child/@attribute') eq 'new');
ok($o->store('/document/child/text()','new'));
ok($o->store('/document/child','new'));
ok($o->fetch('/document/child') eq 'new');
ok($o->store('/document/child/node','new'));
ok($o->fetch('/document/child/node') eq 'new');

# KEYS
ok(scalar $o->keys == 3);

# DELETE
ok($o->delete('/document/child/@attribute') eq 'new');
ok($o->delete('/document/child/text()') eq 'new');
$o->delete('/document/child/node');
ok(!defined $o->delete('/document/child'));

#CMP
my ($a, $b);
$a = XML::Object->new(Input => \$xml);
$b = XML::Object->new(Input => \$xml);
ok($a eq $b);
$a->delete('/document/child/@attribute');
ok($a ne $b);
