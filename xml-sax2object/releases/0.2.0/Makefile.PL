use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'XML::SAX2Object',
   'VERSION_FROM'	=> 'lib/XML/SAX2Object.pm',
   'PREREQ_PM'		=> {
			    XML::SAX         => '0.05',
			    XML::SAX::Base   => '1.03',
			    XML::SAX::Writer => '0.39'
			   },
   ($] >= 5.005 ?
    ( AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
