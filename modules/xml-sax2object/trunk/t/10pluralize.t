use Test;
BEGIN { plan tests =>  6 };

use XML::SAX;
use XML::SAX::Writer;
use XML::SAX2Object::Generator;

my ($handler, $parser, $xml);
$handler = XML::SAX::Writer->new(Output => \$xml);
$parser = XML::SAX2Object::Generator->new(Handler   => $handler,
					  SkipRoot  => 1);

$parser->parse(Object => {keys => ['value1', 'value2']});
ok(defined $xml &&
   $xml eq '<keys><key>value1</key><key>value2</key></keys>');
$xml = undef;

$parser->parse(Object => {tests => ['value1', 'value2']});
ok(defined $xml &&
   $xml eq '<tests><test>value1</test><test>value2</test></tests>');
$xml = undef;


$parser->parse(Object => {tests => [['value1'], ['value2']]});
ok(defined $xml &&
   $xml eq '<tests><test>value1</test><test>value2</test></tests>');
$xml = undef;

$parser->parse(Object => {leaves => [['value1'], ['value2']]});
ok(defined $xml &&
   $xml eq '<leaves><leaf>value1</leaf><leaf>value2</leaf></leaves>');
$xml = undef;

$parser->parse(Object => {test => ['value1', 'value2']});
ok(defined $xml &&
   $xml eq '<test>value1</test><test>value2</test>');
$xml = undef;

$parser->dictionary(bar => 'foo');
$parser->parse(Object => {bar => [['value1'],['value2']]});

ok(defined $xml &&
   $xml eq '<bar><foo>value1</foo><foo>value2</foo></bar>');
$xml = undef;
