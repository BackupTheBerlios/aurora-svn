use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'XML::XSP::Taglib::Aurora::Context',
   'VERSION_FROM'	=> 'Context.pm',
   'PREREQ_PM'		=> {
			    XML::XSP => '0.4.0',
			    Aurora   => '0.4.0'
			   },
   ($] >= 5.005 ?
    ( AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
