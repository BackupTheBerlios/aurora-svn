use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'XML::XSP::Taglib::Param',
   'VERSION_FROM'	=> 'Param.pm',
   'PREREQ_PM'		=> {
			    XML::XSP => '0.4.0'
			   },
   ($] >= 5.005 ?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
