use Test;
BEGIN { plan tests =>  1 };

use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX2Object::Builder;

my ($handler, $parser, $xml);
$handler = XML::SAX2Object::Builder->new;
$parser =  XML::SAX::ParserFactory->parser(Handler => $handler);

$object = $parser->parse_string(<< 'TEST');
<test/>
TEST
ok((defined $object)? 1 : 0);

