use lib 'lib';
use Benchmark;
use XML::Object qw/LibXML/;

eval {
  require XML::Simple;
};

my (@xml, $buf);

while(<DATA>) {
  (($_ =~ /^\s*$/)? do { push @xml, $buf; $buf = ''; } : ($buf .= $_));
}


foreach my $xml (@xml) {
  timethese(1000,
	    {
	     '1:Load (XML::Object)'  => sub {
	       XML::Object->new(Input => \$xml);
	     },
	     '2:Fetch (XML::Object)' => sub {
	       my $o = XML::Object->new(Input => \$xml);
	       for(1..10) { $o->fetch('/dromedaries/species[1]/humps')};
	     },
	     '3:Store (XML::Object)' => sub {
	       my $o = XML::Object->new(Input => \$xml);
	       for(1..10) { $o->store('/dromedaries/species[1]/humps', 'new')};
	     },
	     ((XML::Simple->can('new'))?
	      (
	       '1:Load (XML::Simple)'  => sub { XML::Simple::XMLin($xml) },
	       '2:Fetch (XML::Simple)' => sub {
		 my $o = XML::Simple::XMLin($xml, keeproot => 1);
		 for(1..10) {$o->{dromedaries}->{species}->{1}->{humps}};
	       },
	       '3:Store (XML::Simple)' => sub {
		 my $o = XML::Simple::XMLin($xml, keeproot => 1);
		 for(1..10) { $o->{dromedaries}->{species}->{1}->{humps} = 'new'};
		 XML::Simple::XMLout($o);
	       }) :())
	    });
}

1;
__DATA__
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

<dromedaries>
<species name="1">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="2">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="3">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="4">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="5">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="6">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="7">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
<species name="8">
<humps>1 or 2</humps>
<disposition>Cranky</disposition>
</species>
</dromedaries>

