use Test;
BEGIN { plan tests =>  17 };

use XML::Object qw/LibXML/;;
my ($o, $xml);

$xml = << 'XML';
<?xml version="1.0"?>
<document><child attribute="value">value</child></document>
XML

$o =  XML::Object->new(Tied => 1, Input => \$xml);

# EXISTS
ok(exists $o->{'/document/child'});
ok(exists $o->{'/document/child/@attribute'});
ok(!exists $o->{'/document/child/bogus'});
ok(exists $o->{'//node()|@*'});

# FETCH
ok($o->{'/document/child'} eq 'value');
ok(!defined $o->{'/document/child/bogus'});
ok($o->{'/document/child/@attribute'} eq 'value');
ok(scalar @{$o->{'//node()|@*'}} == 3);

# STORE
$o->{'/document/child/@attribute'} = 'new';
ok($o->{'/document/child/@attribute'} eq 'new');
$o->{'/document/child/text()'} = 'new';
$o->{'/document/child'} = 'new';
ok($o->{'/document/child'} eq 'new');
$o->{'/document/child/node'} = 'new';
ok($o->{'/document/child/node'} eq 'new');

# KEYS
ok(scalar keys %{$o} == 3);

# DELETE
ok(delete $o->{'/document/child/@attribute'} eq 'new');
ok(delete $o->{'/document/child/text()'} eq 'new');
delete $o->{'/document/child/node'};
ok(!defined delete $o->{'/document/child'});

#CMP
my ($a, $b);
$a = XML::Object->new(Tied => 1, Input => \$xml);
$b = XML::Object->new(Tied => 1, Input => \$xml);
ok($a eq $b);
delete $a->{'/document/child/@attribute'};
ok($a ne $b);
