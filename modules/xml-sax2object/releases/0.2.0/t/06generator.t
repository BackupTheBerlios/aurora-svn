use Test;
BEGIN { plan tests =>  1 };

use XML::SAX;
use XML::SAX::Writer;
use XML::SAX2Object::Generator;

my ($handler, $parser, $xml);
$handler = XML::SAX::Writer->new(Output => \$xml);
$parser = XML::SAX2Object::Generator->new(Handler => $handler);

$parser->parse(Object => {test => 'value1'});
ok(defined $xml);
$xml = undef;

