use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'XML::XSP::Taglib::ESQL',
   'VERSION_FROM'	=> 'lib/XML/XSP/Taglib/ESQL.pm',
   'PREREQ_PM'		=> {
			    DBI      => '1.13',
			    XML::XSP => '0.2.0'
			   },
   ($] >= 5.005 ?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
