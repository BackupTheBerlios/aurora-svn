use ExtUtils::MakeMaker;
WriteMakefile
  (NAME		=> 'XML::Object',
   VERSION_FROM	=> 'lib/XML/Object.pm',
   PREREQ_PM	=> {
		    'XML::LibXML' => 1.52,
		   },
   (($] >= 5.005)?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()));
