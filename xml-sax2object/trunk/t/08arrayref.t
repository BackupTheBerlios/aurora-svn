use Test;
BEGIN { plan tests =>  8 };

use XML::SAX;
use XML::SAX::Writer;
use XML::SAX2Object::Generator;

my ($handler, $parser, $xml);
$handler = XML::SAX::Writer->new(Output => \$xml);
$parser = XML::SAX2Object::Generator->new(Handler   => $handler,
					  Pluralize => 0,
					  SkipRoot  => 1);

$parser->parse(Object => {test => {key1 => ['value1', 'value2']}});
ok(defined $xml &&
   $xml eq '<test><key1>value1</key1><key1>value2</key1></test>');
$xml = undef;

$parser->parse(Object => {test => ['value1', 'value2']});
ok(defined $xml &&
   $xml eq '<test>value1</test><test>value2</test>');
$xml = undef;

$parser->parse(Object => [{key1 => 'value1'}, {key2 => 'value2'}]);
ok(defined $xml &&
   $xml eq '<key1>value1</key1><key2>value2</key2>');
$xml = undef;

$parser->parse(Object => {test => [['value1'], ['value2']]});
ok(defined $xml &&
   $xml eq '<test>value1</test><test>value2</test>');
$xml = undef;

$parser->parse(Object => [[{key1 => 'value1'}], [{key2 => 'value2'}]]);
ok(defined $xml &&
   $xml eq '<key1>value1</key1><key2>value2</key2>');
$xml = undef;

$parser->skiproot(0);

$parser->parse(Object => {test => ['value1', 'value2']});
ok(defined $xml &&
   $xml eq '<document><test>value1</test><test>value2</test></document>');
$xml = undef;


$parser->parse(Object => [{key1 => 'value1'}, {key2 => 'value2'}]);
ok(defined $xml &&
   $xml eq '<document><key1>value1</key1><key2>value2</key2></document>');
$xml = undef;

$parser->rootname('root');

$parser->parse(Object => {test => ['value1', 'value2']});
ok(defined $xml &&
   $xml eq '<root><test>value1</test><test>value2</test></root>');
$xml = undef;
