use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'XML::XSP::Taglib::Util',
   'VERSION_FROM'	=> 'Util.pm',
   'PREREQ_PM'		=> {
			    XML::XSP => '0.4.1',
 		            LWP::UserAgent => 0
			   },
   ($] >= 5.005 ?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
