use Test;
BEGIN { plan tests => 11};
use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX2Object::Builder;

my ($handler, $parser, $object);
$handler = XML::SAX2Object::Builder->new;
$parser =  XML::SAX::ParserFactory->parser(Handler => $handler);

$object = $parser->parse_string(<< 'TEST');
<test>characters</test>
TEST
ok(($object->{test} eq 'characters')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash>characters</hash>
</test>
TEST
ok(($object->{test}->{hash} eq 'characters')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash>
<key1>characters</key1>
<key2>characters</key2>
</hash>
</test>
TEST
ok(($object->{test}->{hash}->{key1} eq 'characters') &&
   ($object->{test}->{hash}->{key2} eq 'characters')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash>
<key1>characters1<test/>characters2</key1>
<key2>characters3<test/>characters4</key2>
</hash>
</test>
TEST
ok(($object->{test}->{hash}->{key1} eq 'characters1characters2') &&
   ($object->{test}->{hash}->{key2} eq 'characters3characters4')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<array>characters1</array>
<array>characters2</array>
</test>
TEST

ok(($object->{test}->{array}->[0] eq 'characters1' &&
    $object->{test}->{array}->[1] eq 'characters2')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<array><hash>characters1</hash></array>
<array><hash>characters2</hash></array>
<array><hash>characters3</hash></array>
</test>
TEST

ok(($object->{test}->{array}->[0]->{hash} eq 'characters1' &&
    $object->{test}->{array}->[1]->{hash} eq 'characters2' && 
    $object->{test}->{array}->[2]->{hash} eq 'characters3')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash>characters1</hash>
<array><hash>characters2</hash></array>
<array><hash>characters3</hash></array>
</test>
TEST

ok(($object->{test}->{hash} eq 'characters1' &&
    $object->{test}->{array}->[0]->{hash} eq 'characters2' &&
    $object->{test}->{array}->[1]->{hash} eq 'characters3')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<test>
<array>characters1<test/>characters2</array>
<array>characters3<test/>characters4</array>
</test>
TEST

ok(($object->{test}->{array}->[0] eq 'characters1characters2' &&
    $object->{test}->{array}->[1] eq 'characters3characters4')? 1 : 0);

$handler->normalize(0);

$object = $parser->parse_string(<< 'TEST');
<test>
<array><hash>characters 1</hash></array>
<array><hash> characters  2</hash></array>
<array><hash>  characters   3  </hash></array>
</test>
TEST

ok(($object->{test}->{array}->[0]->{hash} eq 'characters 1' &&
    $object->{test}->{array}->[1]->{hash} eq ' characters  2' && 
    $object->{test}->{array}->[2]->{hash} eq '  characters   3  ')? 1 : 0);

$handler->normalize(1);

$object = $parser->parse_string(<< 'TEST');
<test>
<array><hash>characters 1</hash></array>
<array><hash> characters  2</hash></array>
<array><hash>  characters   3  </hash></array>
</test>
TEST

ok(($object->{test}->{array}->[0]->{hash} eq 'characters 1' &&
    $object->{test}->{array}->[1]->{hash} eq 'characters 2' && 
    $object->{test}->{array}->[2]->{hash} eq 'characters 3')? 1 : 0);

$handler->skiproot(1);

$object = $parser->parse_string(<< 'TEST');
<test>
<hash>characters</hash>
</test>
TEST

ok(($object->{hash} eq 'characters')? 1 : 0);
$handler->skiproot(0);


