package Aurora::Log;

use strict;
use Exporter;
use POSIX qw/strftime/;


use Aurora::Exception qw/:try/;

use vars  qw/@ISA @EXPORT @LEVEL $AUTOLOAD/;
@ISA       = qw/Exporter/;
@EXPORT    = qw/logerror logwarn logsay logdebug/;
@LEVEL     = qw/alert critical error error warning
                warning notice notice info info/;

{
  my ($instance);

  sub new {
    my ($class, $handler) = @_;
    my ($self);
    throw Aurora::Exception("The log handler supplied isn't a callback.")
      unless ref $handler eq 'CODE';

    $self = bless {
		   handler => $handler
		  }, $class;

    $instance ||= $self;
    return $self;
  }

  sub DESTROY { }

  sub AUTOLOAD {
    my ($self, $level, $found, $function);
    $self = (caller)[0];
    $level = 0;
    $found = 0;
    ($function) = ($AUTOLOAD =~ /::([^:]*)$/);
    if(grep {$level++ unless $found;
	     ($function eq $_)? ($found = 1) : 0} @EXPORT) {
      $level = 1+ ($level * 2);
    UNSAFE: {
	no strict 'refs';
	*{$AUTOLOAD} = ($instance)?
	  sub { $instance->{handler}->((caller)[0], $level, @_);  } :
	    sub {
	    my ($pkg, @errors);
	    $pkg = (caller)[0];
	    @errors = @_;
	    return if
	      (ref $self &&
	       (${(join '', ref $self, '::DEBUG')} || 10) < $level) ||
		$Aurora::DEBUG == 0 ||
		  $Aurora::DEBUG < $level;
	    print STDERR
	      "[",(strftime '%e %b %H:%M:%S',gmtime()),"]",
		"[Aurora]",
		  "[",uc($LEVEL[$level]),"] ",
		    @errors, ((ref $errors[-1] ||
			       ($errors[-1] || '') !~ /\n$/)? "\n" : '');
	  };
      }
      if(my $code = $self->can($function)) {
	return $code->(@_);
      }
    }
    die (join '','Can\'t locate object method "',$function,
	 '" via package "',ref $self,'"',"\n");
  }
}
1;
__END__

=pod

=head1 NAME

Aurora::Log - Helper functions to assist in dealing with message
logging.

=head1 SYNOPSIS

  use Aurora::Log;

  logerror("An error message");
  logwarn("A warning");
  logsay("A message");
  logdebug("A debug message");

=head1 DESCRIPTION

Aurora::Log contains a set of helper functions to assist in how Aurora
messages to the system logs. The verbosity of the messages logged are
controlled by the debug level of the component and the parent Aurora
server.

=head1 FUNCTIONS

=over 4

=item B<logdebug>(@messages)

This function logs the messages to the debug channel.

=item B<logerror>(@messages)

This function logs the messages to the error channel.

=item B<logsay>(@messages)

This function logs the messages specified.

=item B<logwarn>(@messages)

This function logs the messages to the warn channel.


=back

=head1 AUTHOR/LICENCE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston,
MA  02111-1307, USA.

(c)2001-2004 Darren Graves (darren@iterx.org), All Rights Reserved.

=head1 SEE ALSO

L<Aurora>
