use Test;
BEGIN { plan tests => 2 }
END   { ok($loaded) }

use Aurora;
$loaded++;
ok(1);
