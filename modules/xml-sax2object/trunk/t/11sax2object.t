use Test;
BEGIN { plan tests =>  3 };

use XML::SAX2Object;

my ($sax2object, $object, $xml);

$sax2object =  XML::SAX2Object->new;
$xml = << 'TEST';
<test><hash>characters</hash></test>
TEST

$object = $sax2object->reader(\$xml);
ok(($object->{test}->{hash} eq 'characters')? 1 : 0);

$sax2object->writer($object,{Output   => \$xml});
ok(($xml eq '<test><hash>characters</hash></test>')? 1 : 0);

$sax2object->namespace(1);
$sax2object->nsmap
  (
   'http://iterx.org/namespace/default' => 'ns2',
   'http://iterx.org/namespace1' => 'ns1',
  );

$xml = << 'TEST';
<test
  xmlns="http://iterx.org/namespace/default"
  xmlns:ns2="http://iterx.org/namespace1">
<ns2:hash>characters</ns2:hash>
</test>
TEST

$object = $sax2object->reader(\$xml);
ok(($object->{'ns2:test'}->{'ns1:hash'} eq 'characters')? 1 : 0);
