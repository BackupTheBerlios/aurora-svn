use Test;
BEGIN { plan tests =>  1 };

use XML::Object qw/LibXML/;

my ($o, $xml);

$xml = << 'XML';
<?xml version="1.0"?>
<document></document>
XML

$o =  XML::Object->new(Input => \$xml);
ok (ref $o);
