use Test;
BEGIN {
  if($^O eq 'linux' && $ENV{MEMORY_TEST}) {
    plan tests => 3;
  }
  else {
    print "# Skipping test on this platform\n";
    plan tests => 0;
  }
}

if($^O eq 'linux' && $ENV{MEMORY_TEST}) {
  use XML::XSP;
  use vars qw/$TOTAL/;

  my ($xsp, @files);

  $xsp = XML::XSP->new;
  $xsp->start;

  {
    my ($page, $document, $out, $in, $delta);
    local $/ = undef;
    $document = << 'EOF';
<?xml version="1.0"?>
<xsp:page language="perl" xmlns:xsp="http://apache.org/xsp/core/v2">
<tests>
  <test><xsp:expr>1+2</xsp:expr></test>
</tests>
</xsp:page>
EOF

    $page = $xsp->page(\$document);
    $page = undef;

    check(1);
    for (1..1000) {
      $page = $xsp->page(\$document);
      $page = undef;
    }

    $delta = check();
    for (1..5000) {
      $page = $xsp->page(\$document);
      $page = undef;
    }

    ok((abs($delta - check()) < 5)? 1 : 0);

    $page = $xsp->page(\$document);
    $page = undef;
    check(1);
    for (1..1000) {
      $page = $xsp->page('#local' => \$document);
      $page = undef;
    }

    $delta = check();
    for (1..5000) {
      $page = $xsp->page('#local' =>\$document);
      $page = undef;
    }

    ok((abs($delta - check()) < 5)? 1 : 0);

    $page = $xsp->page(\$document);
    $in = $page->driver->document(\$document);
    $out = $page->transform($in);
    $in = $out = undef;
    check(1);
    for (1..1000) {
      $in = $page->driver->document(\$document);
      $out = $page->transform($in);
      $in = $out = undef;
    }

    $delta = check();
    for (1..5000) {
      $in = $page->driver->document(\$document);
      $out = $page->transform($in);
      $in = $out = undef;
    }
    ok((abs($delta - check()) < 5)? 1 : 0);
    $page = undef;
  }
  $xsp->stop;

  sub check {
    my ($reset) = @_;
    my (%mem, $delta);
    if (open(FILE, "/proc/self/statm")) {
      @mem{qw(Total Resident Shared)} = split /\s+/, <FILE>;
      close FILE;
      if ($reset) {
	$TOTAL = $mem{Total};
      } elsif ($TOTAL != $mem{Total}) {
	$delta = $mem{Total} - $TOTAL;
	$TOTAL = $mem{Total};
      }
      warn("\nMem Total: $mem{Total} Shared: $mem{Shared} Delta: $delta\n")
	if $delta;
    }
    return $delta || 0;
  }
}
1;
