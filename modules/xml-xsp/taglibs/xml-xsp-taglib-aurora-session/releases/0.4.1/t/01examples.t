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

$xsp = XML::XSP->new(Taglibs => ['XML::XSP::Taglib::Aurora::Session']);
$xsp->start;

$request = HTTP::Request->new
  (GET => 'http://www.iterx.org/test.cgi?name1=value1;name2=value2',
   HTTP::Headers->new(
		      Date => 'Thu, 03 Feb 1994 00:00:00 GMT',
		      Content_Type => 'application/x-www-form-urlencoded',
		      User_Agent => 'Test Harness',
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


package Aurora::Session::NULL;
no warnings;
use Aurora::Session::SIB;
use Aurora::Session::Simple;

use Storable qw/freeze thaw/;

sub new {
  my ($class) = @_;
  @Aurora::Session::NULL::ISA = qw/Aurora::Session::Simple/;
  return bless {
		secret   => '123456',
		sessions => {}
	       }, $class;
}

sub fetch {
  my ($self, $sid) = @_;
  return (exists $self->{sessions}->{$sid})?
    thaw $self->{sessions}->{$sid} : undef;
}

sub store {
  my ($self, $sib) = @_;
  $self->{sessions}->{$sib->id} = freeze $sib;
  return $sib;
}

sub remove {
  my ($self, $sid) = @_;
  $sid = $sid->id if UNIVERSAL::isa($sid, 'Aurora::Session::SIB');
  delete $self->{sessions}->{$sid};
  return;
}

sub sib {
  my ($self) = shift;
  return Aurora::Session::SIB->new(@_);
}

package Aurora::Server;
no warnings;
{
  my ($session);
  sub session {
    unless(defined $session) {
      # create new session store
      $session = Aurora::Session::NULL->new;
    }
    return $session;
  }
}

1;
