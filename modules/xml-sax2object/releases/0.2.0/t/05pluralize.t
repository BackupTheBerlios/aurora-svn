use Test;
BEGIN { plan tests =>  6 };

use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX2Object::Builder;

my ($handler, $parser, $object);
$handler = XML::SAX2Object::Builder->new();
$parser =  XML::SAX::ParserFactory->parser(Handler => $handler);


$object = $parser->parse_string(<< 'TEST');
<tests>
  <test attribute="value"/>
</tests>
TEST

ok(($object->{tests}->[0]->{attribute} eq 'value')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<leaves>
  <leaf attribute="value"/>
</leaves>
TEST

ok(($object->{leaves}->[0]->{attribute} eq 'value')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<tests>
  <test>value1</test>
</tests>
TEST

ok(($object->{tests}->[0] eq 'value1')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<tests>
  <test>value1</test>
  <test>value2</test>
</tests>
TEST

ok(($object->{tests}->[0] eq 'value1' &&
    $object->{tests}->[1] eq 'value2' )? 1 : 0);


$object = $parser->parse_string(<< 'TEST');
<tests>
<test><hash>characters1</hash></test>
</tests>
TEST

ok(($object->{tests}->[0]->{hash} eq 'characters1')? 1 : 0);

$handler->dictionary(bar => 'foo');
$object = $parser->parse_string(<< 'TEST');
<foo>
  <bar attribute="value"/>
</foo>
TEST

ok(($object->{foo}->[0]->{attribute} eq 'value')? 1 : 0);

