use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'XML::XSP::Taglib::Aurora::Resource',
   'VERSION_FROM'	=> 'Resource.pm',
   'PREREQ_PM'		=> {
			    XML::XSP => '0.4.1',
			    Aurora   => '0.4.0',
			    Aurora::Component::Pipeline::Transformer::XSP => '0.4.2'
			   },
   ($] >= 5.005 ?
    ( AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
