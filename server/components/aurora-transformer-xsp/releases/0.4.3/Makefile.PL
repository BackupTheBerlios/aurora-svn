use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'Aurora::Component::Pipeline::Transformer::XSP',
   'VERSION_FROM'	=> 'XSP.pm',
   'PREREQ_PM'		=> {
			    Aurora   => '0.4.0',
			    XML::XSP => '0.4.0'
			    },
   ($] >= 5.005 ?
    ( AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
