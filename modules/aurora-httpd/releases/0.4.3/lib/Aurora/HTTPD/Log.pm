package Aurora::HTTPD::Log;
use strict;

use Exporter;
use Aurora::Log;
use FileHandle;
use POSIX qw/strftime/;

use vars  qw/@ISA @EXPORT @LEVEL/;
@ISA    = qw/Aurora::Log Exporter/;
@EXPORT = qw/logerror logwarn logsay logdebug logaccess/;

{
  my ($instance);

  sub new {
    my ($class, %options) = @_;
    my ($access);
    unless(defined $instance) {
      my ($error, $access);
      if($options{ErrorLog} =~ s/^(file:\/\/\/|\/)/\//) {
	open STDERR, ">>$options{ErrorLog}" ||
	  logerror("Failed to open error log: ", $!);
      }
      elsif($options{ErrorLog}) {
	logerror("Invalid error log location: ", $options{ErrorLog});
      }
      if($options{AccessLog} =~ s/^(file:\/\/\/|\/)/\//) {
	$access = FileHandle->new;
	open $access, ">>$options{AccessLog}" ||
	  logerror("Failed to open access log: ", $!);
	autoflush $access, 1;
      }
      elsif($options{AccessLog}) {
	logerror("Invalid access log location: ", $options{AccessLog});
      }

      $instance = bless { access => $access }, $class;
    }
    return $instance;
  }

  sub logaccess {
    my ($vhost, $remote, $query, $status, $referer, $useragent) = @_;
    if(defined $instance) {
      my ($fh);
      if($fh = $instance->{access}) {
	print $fh
	  (join ' ', ($vhost || '-'),
	   ($remote|| '-'),
	   ('- -'),
	   ("[",(strftime '%d/%b/%y:%H:%M:%S %z',gmtime()),"]"),
	   (($query)? "\"$query\"" : '-'),
	   ($status || '-'),
	   (($referer)? "\"$referer\"" : '-'),
	   (($useragent)? "\"$useragent\"" : '-'),"\n");
      }
    }
  }
}
1;
