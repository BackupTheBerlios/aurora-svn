use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'Aurora::HTTPD',
   'VERSION_FROM'	=> 'lib/Aurora/HTTPD.pm',
   'PREREQ_PM'		=> {
			    Aurora => '0.4.2',
			    POE    => '0.1901',
			   },
   'EXE_FILES' => [ 'bin/aurora-httpd' ],
   'dist' => { 'COMPRESS' => 'gzip -v -9 -f', 'SUFFIX' => '.gz' },
   ($] >= 5.005 ?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
   );

1;
