use Test;

use XML::XSP;

use Aurora;
use Aurora::Context;
use Aurora::Exception qw/:try/;

use HTTP::Request;
use HTTP::Headers;

my ($xsp, $context, $request, $ok);

plan tests => 3;

$xsp = XML::XSP->new(Taglibs => ['XML::XSP::Taglib::Aurora::Event']);
$xsp->start;

$request = HTTP::Request->new
  (GET => 'http://www.iterx.org/test.cgi?name1=value1;name2=value2');

$context = Aurora::Context->new('127.0.0.1' => $request);

$document = <<EOXML;
<?xml version="1.0"?>
<xsp:page language="perl"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:event="http://iterx.org/xsp/aurora/event/v1">

  <data>
    <event:redirect uri="http://iterx.org/"/>
  </data>
</xsp:page>

EOXML

$ok = 0;
eval {
  $page = $xsp->page(\$document);
  try {
    $page->transform(\$document, {context => $context});
  }
  otherwise {
    my ($event);
    $event = shift;

    use Data::Dumper;
    print STDERR Dumper();

    $ok = 1 if (UNIVERSAL::isa($event,'Aurora::Exception::Event') &&
		$event->event == 302 &&
		$event->{-uri} eq 'http://iterx.org/');
  };
};
if($@) {
  print STDERR "\n$@\n";
}
ok($ok);

$ok = 0;
$document = <<EOXML;
<?xml version="1.0"?>
<xsp:page language="perl"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:event="http://iterx.org/xsp/aurora/event/v1">

  <data>
    <event:redirect>
      <uri>http://iterx.org/</uri>
    </event:redirect>
  </data>
</xsp:page>

EOXML

$ok = 0;
eval {
  $page = $xsp->page(\$document);
  try {
    $page->transform(\$document, {context => $context});
  }
  otherwise {
    my ($event);
    $event = shift;
    $ok = 1 if (UNIVERSAL::isa($event,'Aurora::Exception::Event') &&
		$event->event == 302 &&
		$event->{-uri} eq 'http://iterx.org/');
  };
};
if($@) {
  print STDERR "\n$@\n";
}
ok($ok);

$ok = 0;
$document = <<EOXML;
<?xml version="1.0"?>
<xsp:page language="perl"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:event="http://iterx.org/xsp/aurora/event/v1">

  <data>
    <event:throw code="302">
      <uri>http://iterx.org/</uri>
    </event:throw>
  </data>
</xsp:page>

EOXML

$ok = 0;
eval {
  $page = $xsp->page(\$document);
  try {
    $page->transform(\$document, {context => $context});
  }
  otherwise {
    my ($event);
    $event = shift;
    $ok = 1 if (UNIVERSAL::isa($event,'Aurora::Exception::Event') &&
		$event->event == 302 &&
		$event->{-uri} eq 'http://iterx.org/');
  };
};
if($@) {
  print STDERR "\n$@\n";
}
ok($ok);


$xsp->stop;

