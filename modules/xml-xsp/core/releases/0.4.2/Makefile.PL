use ExtUtils::MakeMaker;

WriteMakefile
(
 'NAME'		=> 'XML::XSP',
 'VERSION_FROM'	=> 'lib/XML/XSP.pm',
 'PREREQ_PM'	=> {
		    Error        => 0,
		    Digest::MD5  => 0,
		    XML::LibXML  => 1.49,
		    XML::LibXSLT => 1.49
		   },
 ($] >= 5.005 ?
   (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),

);


1;
