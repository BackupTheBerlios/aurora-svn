use Test;
use XML::Object qw/LibXML/;;

my (@xml, $buf);

$buf = '';

while(<DATA>) {
  (($_ =~ /^\s*$/)? do { push @xml, $buf; $buf = ''; } : ($buf .= $_));
}
plan tests => scalar @xml;


while(my $xml = shift @xml) {
  my (@nodes, $original, $new, $key, $value);
  $original =  XML::Object->new(Input => \$xml);
  $new = XML::Object->new;
  $new->deserialize($original->serialize);
  if($new ne $original) {
    print STDERR "\n|",$new,"|\n\n|",$original,"|\n";
  }
  ok($new eq $original);
}

__DATA__
<document><child>text</child></document>

<document><child attribute="value">text</child></document>

<dromedaries>
<species name="1">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="2">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
</dromedaries>

<dromedaries xmlns="urn:camels" xmlns:mam="urn:mammals">
  <species>Camelid</species>
  <mam:legs xml:lang="en" yyy="zzz" a:xxx="foo" xmlns:a="urn:a">4</mam:legs>
</dromedaries>

<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v1">
<elements>
<element1><xsp:expr>1+2</xsp:expr></element1>
<element2 attribute="value">
<xsp:expr>1+2</xsp:expr>
</element2>
<element3>The time is <xsp:expr>1+2</xsp:expr></element3>
<element4>Counting
<xsp:expr>
my ($value);
for (my $i = 0; $i &lt; 10; $i++) {
$value .= "$i.";
}
$value;
</xsp:expr>
</element4>
</elements>
</xsp:page>

