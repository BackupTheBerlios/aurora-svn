package XML::XSP::Log;
use strict;

use Exporter;
use POSIX qw/strftime/;

use vars  qw/@ISA @EXPORT  @LEVEL $AUTOLOAD/;

@ISA       = qw/Exporter/;
@EXPORT    = qw/logerror logwarn logsay logdebug/;
@LEVEL     = qw/alert critical error error warning
                warning notice notice info info/;
{
  my ($instance);

  sub new {
    my ($class, $handler) = @_;
    my ($self);
    die "The log handler supplied isn't a callback."
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
	    return if $XML::XSP::DEBUG == 0 ||
	      $XML::XSP::DEBUG < $level;
	    print STDERR
	      "[",(strftime '%e %b %H:%M:%S',gmtime()),"][XSP]",
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

XML::XSP::Log - Handles the logging of messages for the XML::XSP module.

=head1 SYNOPSIS

  use XML::XSP::Log;

  logdebug('message');
  logsay('message');
  logwarn('message');
  logerror('message');

=head1 DESCRIPTION

This class handles the logging of all modules messages.

=head1 CONSTRUCTOR

=over 1

=item B<new>($handler)

Construct a new log handler instance. Can optionally supply an external
callback to handle message logging rather than the default builtin
handler.

=back

=head1 EXPORTED METHODS

=over 4

=item B<logdebug>(@messages)

Log a debug message.

=item B<logsay>(@messages)

Log a general purpose message.

=item B<logwarn>(@messages)

Log a warning message.

=item B<logerror>(@messages)

Log an error message.

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

L<XML::XSP>

=cut
