use Test;

use XML::XSP;

use Aurora;
use Aurora::Context;
use HTTP::Request;
use HTTP::Headers;

$Aurora::DEBUG = 0;

my ($xsp, $context, $request, @files);
@files = (glob 'examples/*.xsp');
plan tests => scalar(@files);

$xsp = XML::XSP->new(Taglibs => ['XML::XSP::Taglib::Aurora::Context']);
$xsp->start;

$request = HTTP::Request->new
  (GET => 'http://www.iterx.org/test.cgi?name1=value1;name2=value2',
   HTTP::Headers->new(
		      Date => 'Thu, 03 Feb 1994 00:00:00 GMT',
		      Content_Type => 'application/x-www-form-urlencoded',
		      User_Agent => 'Test Harness',
		      Cookie  => 'a=value+a ;b=value+b; domain=.iterx.org'
		     )
  );


$context = Aurora::Context->new('127.0.0.1' => $request);
foreach my $in (@files) {
  my ($page, $document, $result);
  local $/ = undef;
  open FILE, $in;

  $document = <FILE>;
  close FILE;

  eval {
    $page = $xsp->page(\$document);
    $result = $page->transform(\$document, {context => $context});
  };
  if($@) {
    print STDERR "\n$@\n";
  }
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
