use Test;
BEGIN { plan tests =>  8 };

use XML::Object qw/LibXML/;
my ($xml,$o, $clone, $fragment, $deleted);

$xml = << 'XML';
<?xml version="1.0"?>
<document xmlns="#local" xmlns:remote="#remote">
<remote:child attribute="value">value</remote:child>
</document>
XML

$o =  XML::Object->new(Input => \$xml);

# CLONE
$clone = $o->clone;
ok($o eq $clone);

# FRAGMENTS
ok($fragment = $o->fetch('//remote:child', 1));
ok($fragment->fetch('/remote:child') eq 'value');
ok($deleted = $o->delete('//remote:child',1));
ok($deleted->fetch('/remote:child') eq 'value');
ok($deleted eq $fragment);
ok($o->store('/document', $fragment));
ok($clone->fetch('//remote:child') eq $o->fetch('//remote:child'));

1;
