use ExtUtils::MakeMaker;

#check htmldoc

WriteMakefile
  (
   'NAME'		=> 'Aurora::Component::Pipeline::Serializer::XHML2PDF',
   'VERSION_FROM'	=> 'XHTML2PDF.pm',
   'PREREQ_PM'		=> {
			    Aurora   => '0.4.0',
			   },
   ($] >= 5.005 ?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
