use Test;
BEGIN { plan tests => 7 };
use XML::SAX;
use XML::SAX::ParserFactory;
use XML::SAX2Object::Builder;


my ($handler, $parser, $object);
$handler = XML::SAX2Object::Builder->new(Namespace => 1);
$parser =  XML::SAX::ParserFactory->parser(Handler => $handler);

$object = $parser->parse_string(<< 'TEST');
<test xmlns="http://iterx.org/namespace">
<hash attribute1="value" attribute2="value">
<key>value</key>
</hash>
</test>
TEST
ok(($object->{test}->{hash}->{key} eq 'value') &&
   ($object->{test}->{hash}->{attribute1} eq 'value') &&
   ($object->{test}->{hash}->{attribute2} eq 'value')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<ns:test xmlns:ns="http://iterx.org/namespace">
<ns:hash attribute1="value" attribute2="value">
<ns:key>value</ns:key>
</ns:hash>
</ns:test>
TEST

ok(($object->{'ns:test'}->{'ns:hash'}->{'ns:key'} eq 'value') &&
   ($object->{'ns:test'}->{'ns:hash'}->{'attribute1'} eq 'value') &&
   ($object->{'ns:test'}->{'ns:hash'}->{'attribute2'} eq 'value')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<n1:test xmlns:n1="http://iterx.org/namespace1"
         xmlns:n2="http://iterx.org/namespace2">
<n1:hash n2:attribute1="value" n2:attribute2="value">
<n2:key>value</n2:key>
</n1:hash>
</n1:test>
TEST

ok(($object->{'n1:test'}->{'n1:hash'}->{'n2:key'} eq 'value') &&
   ($object->{'n1:test'}->{'n1:hash'}->{'n2:attribute1'} eq 'value') &&
   ($object->{'n1:test'}->{'n1:hash'}->{'n2:attribute2'} eq 'value')? 1 : 0);


$handler->nsmap
  (
   'http://iterx.org/namespace/default' => '#default',
   'http://iterx.org/namespace1' => 'n3',
   'http://iterx.org/namespace2' => 'n4'
  );

$object = $parser->parse_string(<< 'TEST');
<n1:test xmlns:n1="http://iterx.org/namespace1"
         xmlns:n2="http://iterx.org/namespace2">
<n1:hash n2:attribute1="value" n2:attribute2="value">
<n2:key>value</n2:key>
</n1:hash>
</n1:test>
TEST

ok(($object->{'n3:test'}->{'n3:hash'}->{'n4:key'} eq 'value') &&
   ($object->{'n3:test'}->{'n3:hash'}->{'n4:attribute1'} eq 'value') &&
   ($object->{'n3:test'}->{'n3:hash'}->{'n4:attribute2'} eq 'value')? 1 : 0);


$object = $parser->parse_string(<< 'TEST');
<n1:test xmlns:n1="http://iterx.org/namespace/default"
         xmlns:n2="http://iterx.org/namespace2">
<n1:hash n2:attribute1="value" n2:attribute2="value">
<n2:key>value</n2:key>
</n1:hash>
</n1:test>
TEST

ok(($object->{'test'}->{'hash'}->{'n4:key'} eq 'value') &&
   ($object->{'test'}->{'hash'}->{'n4:attribute1'} eq 'value') &&
   ($object->{'test'}->{'hash'}->{'n4:attribute2'} eq 'value')? 1 : 0);

$handler->nsignore(1);

$object = $parser->parse_string(<< 'TEST');
<n1:test xmlns:n1="http://iterx.org/namespace/default"
         xmlns:n2="http://iterx.org/namespace3">
<n1:hash n1:attribute1="value" n2:attribute2="value">
<n2:key>value</n2:key>
</n1:hash>
</n1:test>
TEST

ok((!exists $object->{'test'}->{'hash'}->{'key'} &&
    !exists $object->{'test'}->{'hash'}->{'n4:attribute2'} &&
    $object->{'test'}->{'hash'}->{'attribute1'} eq 'value')? 1 : 0);

$object = $parser->parse_string(<< 'TEST');
<n1:test xmlns:n1="http://iterx.org/namespace/default"
         xmlns:n2="http://iterx.org/namespace3">
<n1:hash>
<n2:key><n1:value>string</n1:value></n2:key>
</n1:hash>
</n1:test>
TEST

ok((!exists $object->{'test'}->{'hash'}->{'key'} &&
    $object->{'test'}->{'hash'}->{'value'} eq 'string')? 1 : 0);

