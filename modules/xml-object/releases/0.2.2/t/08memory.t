use Test;
BEGIN {
  if($^O eq 'linux' && $ENV{MEMORY_TEST}) {
    plan tests => 2;
  }
  else {
    print "# Skipping test on this platform\n";
    plan tests => 0;
  }
}

if($^O eq 'linux' && $ENV{MEMORY_TEST}) {
  use XML::Object qw/LibXML/;
  use vars qw/$TOTAL/;

  my ($xml);
  local $/ = undef;
  $xml = <DATA>;

  {
    my ($object, $new);
    $object = XML::Object->new(Input => \$xml);
    $object = undef;
    check(1);
    for (1..1000) {
      $object = XML::Object->new(Input => \$xml);
      $object = undef;
    }
    $delta = check();
    for (1..5000) {
      $object = XML::Object->new(Input => \$xml);
      $object = undef;
    }
    ok((abs($delta - check()) < 5)? 1 : 0);

    $object = XML::Object->new(Input => \$xml);
    $new = XML::Object->new;
    $new->deserialize($object->serialize);
    $new = undef;
    check(1);
    for (1..100) {
      $new = XML::Object->new;
      $new->deserialize($object->serialize);
      $new = undef;
    }
    $delta = check();
    for (1..500) {
      $new = XML::Object->new;
      $new->deserialize($object->serialize);
      $new = undef;
    }
    ok((abs($delta - check()) < 5)? 1 : 0);
    $object = undef;

  };

  sub check {
    my ($reset) = @_;
    my (%mem, $delta);
    $delta = 0;
    if (open(FILE, "/proc/self/statm")) {
      @mem{qw(Total Resident Shared)} = split /\s+/, <FILE>;
      close FILE;
      if ($reset) {
	$TOTAL = $mem{Total};
      }
      elsif ($TOTAL != $mem{Total}) {
	$delta = $mem{Total} - $TOTAL;
	$TOTAL = $mem{Total};
      }
      warn("\nMem Total: $mem{Total} Shared: $mem{Shared} Delta: $delta\n")
	unless $delta < 5;
    }
    return $delta || 0;
  }
}
1;

__DATA__
<?xml version="1.0"?>
<dromedaries>
  <species>Camelid</species>
  <legs value="4"/>
</dromedaries>
