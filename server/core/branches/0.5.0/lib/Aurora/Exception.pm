package Aurora::Exception;
use Error;
use vars qw/@ISA/;
@ISA = qw/Error::Simple/;

package Aurora::Exception::Event;
use Aurora::Constants qw/:response/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Exception/;

sub new {
  my ($class, $self, %options);
  $class = shift;
  %options = (scalar @_ < 2)? ('-text' => @_) : @_;
  local $Error::Depth = $Error::Depth + 1;
  $self = $class->SUPER::new((defined $options{-text})?
			     $options{-text} : '');
  $self->{-event} = ((defined $options{-event})?
		     $options{-event} : SERVER_ERROR);
  return $self;
}

sub event {
  my $self = shift;
  return (exists $self->{'-event'})? $self->{'-event'} : undef;
}

package Aurora::Exception::Error;
use Aurora::Constants qw/:response/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Exception::Event/;

sub event { return SERVER_ERROR }

package Aurora::Exception::Redirect;
use Aurora::Constants qw/:response/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Exception::Event/;

sub new {
  my ($class, $self, %options);
  $class = shift;
  %options = (scalar @_ < 2)? ('-text' => @_) : @_;
  local $Error::Depth = $Error::Depth + 1;
  $self = $class->SUPER::new((defined $options{-text})?
			     $options{-text} : '');
  $self->{-event} = ((defined $options{-event})?
		     $options{-event} : REDIRECT);
  $self->{-uri} = $options{-uri};
  return $self;
}


sub uri {
  my $self = shift;
  return (exists $self->{'-uri'}) ? $self->{'-uri'} : undef;
}

sub event { return REDIRECT }

package Aurora::Exception::Declined;
use Aurora::Constants qw/:response/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Exception::Event/;

sub event { return DECLINED }

package Aurora::Exception::OK;
use Aurora::Constants qw/:response/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Exception::Event/;

sub event { return OK }

1;

__END__

=pod

=head1 NAME

Aurora::Exception - Error/Exception handler for Aurora

=head1 SYNOPSIS

  use Aurora::Log;
  use Aurora::Exception qw/:try/;

  try {
    ...
      throw Aurora::Exception::Error("An error has occurred");

  }
  otherwise {
    logerror(shift);
  }


=head1 DESCRIPTION

Aurora::Exception provides a simple way to handle errors and
exceptions under Aurora, based around the Error package.

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

L<Aurora>, L<Error>
