use Test;
BEGIN { plan tests => 8 };
use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX2Object::Builder;

my ($handler, $parser, $object);
$handler = XML::SAX2Object::Builder->new();
$parser =  XML::SAX::ParserFactory->parser(Handler => $handler);


$object = $parser->parse_string(<< 'TEST');
<test>
<hash attribute1="value" attribute2="value"/>
</test>
TEST
ok(($object->{test}->{hash}->{attribute1} eq 'value') &&
   ($object->{test}->{hash}->{attribute2} eq 'value')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash attribute1="value" attribute2="value">characters</hash>
</test>
TEST
ok(($object->{test}->{hash} eq 'characters')? 1 : 0);


$object = $parser->parse_string(<< 'TEST');
<test>
<hash >
<key1>characters</key1>
<key2>characters</key2>
</hash>
</test>
TEST
ok(($object->{test}->{hash}->{key1} eq 'characters') &&
   ($object->{test}->{hash}->{key2} eq 'characters')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash attribute1="value" attribute2="value">
<key1>characters1<test/>characters2</key1>
<key2>characters3<test/>characters4</key2>
</hash>
</test>
TEST
ok(($object->{test}->{hash}->{attribute1} eq 'value') &&
   ($object->{test}->{hash}->{attribute2} eq 'value') &&
   ($object->{test}->{hash}->{key1} eq 'characters1characters2') &&
   ($object->{test}->{hash}->{key2} eq 'characters3characters4')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<array attribute1="value1" attribute2="value2"/>
<array attribute1="value3" attribute2="value4"/>
</test>
TEST

ok(($object->{test}->{array}->[0]->{attribute1} eq 'value1') &&
   ($object->{test}->{array}->[0]->{attribute2} eq 'value2') &&
   ($object->{test}->{array}->[1]->{attribute1} eq 'value3') &&
   ($object->{test}->{array}->[1]->{attribute2} eq 'value4')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<array attribute="value"><hash>characters1</hash></array>
<array attribute="value"><hash>characters2</hash></array>
</test>
TEST

ok(($object->{test}->{array}->[0]->{attribute} eq 'value') &&
   ($object->{test}->{array}->[1]->{attribute} eq 'value') &&
   ($object->{test}->{array}->[0]->{hash} eq 'characters1') &&
   ($object->{test}->{array}->[1]->{hash} eq 'characters2')? 1 : 0);

$handler->normalize(1);
$object = $parser->parse_string(<< 'TEST');
<test>
<array attribute1="value 1" attribute2="value 2 "/>
<array attribute1=" value  3" attribute2=" value  4 "/>
</test>
TEST

ok(($object->{test}->{array}->[0]->{attribute1} eq 'value 1') &&
   ($object->{test}->{array}->[0]->{attribute2} eq 'value 2') &&
   ($object->{test}->{array}->[1]->{attribute1} eq 'value 3') &&
   ($object->{test}->{array}->[1]->{attribute2} eq 'value 4')? 1 : 0);

$handler->normalize(0);
$object = $parser->parse_string(<< 'TEST');
<test>
<array attribute1="value 1" attribute2="value 2 "/>
<array attribute1=" value  3" attribute2=" value  4 "/>
</test>
TEST

ok(($object->{test}->{array}->[0]->{attribute1} eq 'value 1') &&
   ($object->{test}->{array}->[0]->{attribute2} eq 'value 2') &&
   ($object->{test}->{array}->[1]->{attribute1} eq 'value 3') &&
   ($object->{test}->{array}->[1]->{attribute2} eq 'value 4')? 1 : 0);
