use Test;
BEGIN { plan tests =>  6 };

use XML::SAX;
use XML::SAX::Writer;
use XML::SAX2Object::Generator;

my ($handler, $parser, $xml);
$handler = XML::SAX::Writer->new(Output => \$xml);

$parser = XML::SAX2Object::Generator->new
  (Handler  => $handler,
   Namespace => 1,
   Pluralize => 0,
   NamespaceMap => {
		    '#default' => 'http://iterx.org/namespace/default',
		    'ns'       => 'http://iterx.org/namespace',
		    'ns1'      => 'http://iterx.org/namespace1',
		    'ns2'      => 'http://iterx.org/namespace2'
		   },
   SkipRoot => 1);


$parser->parse(Object => {'ns:test' => {'ns:key1' => ['value1', 'value2']}});
ok(defined $xml &&
   $xml eq "<ns:test xmlns:ns='http://iterx.org/namespace'><ns:key1>value1</ns:key1><ns:key1>value2</ns:key1></ns:test>");
$xml = undef;

$parser->parse(Object => {'ns1:test' => {'ns2:key1' => ['value1', 'value2']}});
ok(defined $xml &&
   $xml eq "<ns1:test xmlns:ns1='http://iterx.org/namespace1'><ns2:key1 xmlns:ns2='http://iterx.org/namespace2'>value1</ns2:key1><ns2:key1 xmlns:ns2='http://iterx.org/namespace2'>value2</ns2:key1></ns1:test>");
$xml = undef;

$parser->parse(Object => {'ns1:test' => {'ns2:key1' =>
					 { 'ns1:test' => 'value1'}}});
ok(defined $xml &&
   $xml eq "<ns1:test xmlns:ns1='http://iterx.org/namespace1'><ns2:key1 xmlns:ns2='http://iterx.org/namespace2'><ns1:test>value1</ns1:test></ns2:key1></ns1:test>");
$xml = undef;


$parser->parse(Object => {'ns1:test' => {'key1' => ['value1', 'value2']}});
ok(defined $xml &&
   $xml eq "<ns1:test xmlns:ns1='http://iterx.org/namespace1'><key1 xmlns='http://iterx.org/namespace/default'>value1</key1><key1 xmlns='http://iterx.org/namespace/default'>value2</key1></ns1:test>");
$xml = undef;

$parser->nsexpand(1);
$parser->parse(Object => {'{http://iterx.org/namespace1}test' =>
			  {'{http://iterx.org/namespace/new}key1' =>
			   ['value1', 'value2']}});

ok(defined $xml &&
   $xml eq "<ns1:test xmlns:ns1='http://iterx.org/namespace1'><ns3:key1 xmlns:ns3='http://iterx.org/namespace/new'>value1</ns3:key1><ns3:key1 xmlns:ns3='http://iterx.org/namespace/new'>value2</ns3:key1></ns1:test>");
$xml = undef;

$parser->nsexpand(0);
$parser->nsignore(1);

$parser->parse(Object =>
	       {'ns1:test' => {
			       'unknown:key1' => 'value',
			       'ns1:key2' => 'value',
			       'unknown:key3' => {'ns1:key1' => 'value'}
			      }});
ok(defined $xml &&
   $xml eq "<ns1:test xmlns:ns1='http://iterx.org/namespace1'><ns1:key2>value</ns1:key2><ns1:key1>value</ns1:key1></ns1:test>");
$xml = undef;
