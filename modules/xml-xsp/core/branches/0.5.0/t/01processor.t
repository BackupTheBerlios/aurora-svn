use Test;
BEGIN { plan tests => 5 };

use XML::XSP;
use XML::XSP::Log;

my ($processor, $log, $callback);

$callback = sub {
  my ($pkg, $level, @errors) = @_;
  $log .= (join '',$level, @errors);
};

$processor = XML::XSP->new(
			   LogHandler => $callback,
			   Debug => 10
			  );
ok(ref $processor);

$log = undef;
logdebug('test');
ok($log eq '9test');
$log = undef;
logsay('test');
ok($log eq '7test');
$log = undef;
logwarn('test');
ok($log eq '5test');
$log = undef;
logerror('test');
ok($log eq '3test');
