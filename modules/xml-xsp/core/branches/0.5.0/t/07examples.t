use Test;
use XML::XSP;
use XML::XSP::Exception qw/:try/;

my ($xsp, @files);
@files = (glob 'examples/*.xsp');
plan tests => scalar(@files);

$xsp = XML::XSP->new;
$xsp->start;

foreach my $in (@files) {
  my ($page, $document, $result);
  local $/ = undef;
  open FILE, $in;
  $document = <FILE>;
  close FILE;
  try {
    $page = $xsp->page($in => \$document);
    $result = $page->transform(\$document);

  }
  otherwise {
    print STDERR shift;
  };

  if($result) {
    my ($out, $diff);
    $out = (join '', substr($in, 0, ((length $in) - 3)), 'out');
    open FILE, "> $out.tmp";
    print FILE $result->toString;
    close FILE;
    if(-e $out) {
      open FILE, "diff -b -B $out $out.tmp |";
      $diff = <FILE>;
      close FILE;
      print STDERR $diff if $diff;
      ok(!$diff);
    }
    else {
      print STDERR "\ncreating $out - check validity by hand\n";
      open FILE, "> $out";
      print FILE $result->toString;
      close $out;
      ok(0);
    }
    unlink "$out.tmp";
    next;
  }
  ok(0);
}
$xsp->stop;



