use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'Aurora::Component::Plugin::Authenticator',
   'VERSION_FROM'	=> 'lib/Aurora/Component/Plugin/Authenticator.pm',
   'PREREQ_PM'		=> {
			    Aurora      => '0.2.0',
			    Digest::MD5 => 0
			   },
   ($] >= 5.005 ?
    (AUTHOR     => 'Darren Graves <darren@iterx.org>') : ()),
  );
