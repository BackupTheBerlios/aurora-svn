use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;

require 5.006;

my $prerequisites = <<EOT;
Module                                  Prerequisites               Default
--------------------------------------- --------------------------- -------
Apache/mod_perl server (apache)         mod_perl 1.26               [no]
                                        Apache::Request
--------------------------------------- --------------------------- -------
Apache2/mod_perl server (apache2)       mod_perl 1.99               [no]
                                        Apache::Request 2.02
--------------------------------------- --------------------------- -------
Zeus/mod_perl server (zeus)             mod_perl 1.26               [no]
--------------------------------------- --------------------------- -------
Cache support (cache)                   Digest::MD5                 [yes]
                                        MLDBM 2.00
                                        MLDBM::Sync 0.25
                                        Storable
--------------------------------------- --------------------------- -------
Charset conversion support (charset)    Text::Iconv                 [no]
--------------------------------------- --------------------------- -------
Compression support (compress)          Compress::Zlib 1.13         [no]
--------------------------------------- --------------------------- -------
DBI connection pools (dbi-pool)         DBI 1.2                     [no]
--------------------------------------- --------------------------- -------
Session support (session)               Digest::MD5                 [no]
                                        MLDBM 2.00
                                        MLDBM::Sync 0.25
                                        Storable
--------------------------------------- --------------------------- -------
Core                                    Error 0.13                   yes
                                        Time::HiRes
                                        HTTP::Request
                                        HTTP::Response
                                        LWP::UserAgent
                                        XML::LibXML 1.31
                                        XML::LibXSLT 1.31
                                        XML::SAX2Object 0.0.5
--------------------------------------- --------------------------- -------
EOT

my $helptext = <<EOT;
Usage: perl Makefile.PL <options>

Possible options are:
  --noprompt            Disable interactive dialog
  --help, -?            Display this help text

  [Do not] install prerequisites for appropriate module:

  --install-all                              --all
EOT


my(%options, %config, %prerequisites, %build, $prompt, $help, $all, $auto);

$build{C} = [];
$build{XS} = {};

foreach (split "\n", $prerequisites) {
  next unless /\(([\w- ]+)?\).*\[(yes|no)\]/;
  $config{$1} = ($2 eq 'no')? 0 : 1;
  $options{"install-$1|$1!"} = \$config{$1} unless $2 eq 'core';
  $helptext .= sprintf "  --[no]install-%-28s --[no]%s\n", $1, $1;
}

GetOptions('prompt!'          => \$prompt,
	   'help|?'           => \$help,
	   'install-all|all!' => \$all,
	   %options);

if($help) {
  print $helptext;
  exit;
}
$prerequisites =~ s/\(([\w- ]+)?\)(.*)\[(yes|no)\]
                   /sprintf "(%s)%s[%s]",$1,$2,(($config{$1} || $all)?
						'yes' : 'no')/egx;

print <<EOT, $prerequisites;

We are about to install Aurora and for your convenience will provide
you with list of modules and prerequisites, so you'll be able to choose
only modules you need for your configuration.

EOT


$auto = ((!$prompt)?
	 prompt("\nDo you want to proceed with this configuration?" => 'yes')
	 =~ /^\s*y/i : 0);

foreach (split /(^[-\s]+$)/m, $prerequisites) {
  print unless $auto;
  if (/^\w+/m &&
      (/\s+(yes)\s*$/m ||
        /\[(yes|no)\]/ &&
          ($auto ||
	   prompt("\nDo you plan to use this module?", $1) =~ /^\s*(y)/i))) {
    if($1 =~ /^y/) {
      my (@errors, @modules);
      map {
	if(/^.{40}([\w\:]+)\s*([\d\.]+)?/) {
	  eval { "require $1;" };
	SWITCH: {
	    $@ && do {
	      push @errors, $1;
	      last SWITCH;
	    };
	    $1 eq "mod_perl" && do {
	      require Apache::src;
	      $build{INC} = Apache::src->new->inc;
 	      $build{OBJECT} = '$(O_FILES)';
              delete $build{XS};
	      delete $build{C};
	    };
	    do {
	      push @modules, $1;
	      $prerequisites{$1} = $2 || 0;
	      last SWITCH;
	    };
	  }
        }
      } split /\n/;
      if(scalar @errors) {
	my ($module);
	($module) = ($_ =~ /(.+?)\s*\(/);
	print if $auto;
	print ("\nModule configuration failed, missing libaries:\n",
	       (join ',', @errors),"\n");
	if(!$prompt &&
	   $module &&
	   prompt("\nDo you want to continue disable this module?" => 'yes')
	   =~ /^\s*y/i) {
	  map { delete $prerequisites{$_} } @modules;
	}
	else {
	  exit;
	}
      }
    }
  }
}

WriteMakefile(NAME         => 'Aurora',
 	      VERSION_FROM => 'lib/Aurora.pm',
 	      PREREQ_PM    => \%prerequisites,
	      %build);
