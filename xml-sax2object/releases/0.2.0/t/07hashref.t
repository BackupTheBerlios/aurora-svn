use Test;
BEGIN { plan tests =>  6 };

use XML::SAX;
use XML::SAX::Writer;
use XML::SAX2Object::Generator;

my ($handler, $parser, $xml);
$handler = XML::SAX::Writer->new(Output => \$xml);
$parser = XML::SAX2Object::Generator->new(Handler => $handler,
					  SkipRoot => 1);

$parser->parse(Object => {test => {key1 => 'value1'}});
ok(defined $xml &&
   $xml eq '<test><key1>value1</key1></test>');
$xml = undef;

$parser->parse(Object => {test => {key1 => 'value1', key2 => 'value2'}});
ok(defined $xml &&
   $xml eq '<test><key1>value1</key1><key2>value2</key2></test>');
$xml = undef;

$parser->parse(Object => {test => {key1 => { key3 => 'value3'},
				   key2 => 'value2'}});
ok(defined $xml &&
   $xml eq '<test><key1><key3>value3</key3></key1><key2>value2</key2></test>');
$xml = undef;

$parser->parse(Object => {test => {key1 => { key3 => 'value3',
					     key4 => 'value4',
					     key5 => undef
					   },
				   key2 => 'value2'}});
ok(defined $xml &&
   $xml eq '<test><key1><key3>value3</key3><key4>value4</key4><key5 /></key1><key2>value2</key2></test>');
$xml = undef;

$parser->skiproot(0);

$parser->parse(Object => {test => {key1 => 'value1'}});
ok(defined $xml &&
   $xml eq '<document><test><key1>value1</key1></test></document>');
$xml = undef;

$parser->rootname('root');

$parser->parse(Object => {test => {key1 => 'value1'}});
ok(defined $xml &&
   $xml eq '<root><test><key1>value1</key1></test></root>');
$xml = undef;
