package XML::XSP::Exception;
use Error;
use overload  '""' => 'stringify';

use vars qw/@ISA/;
@ISA = qw/Error::Simple/;

sub stringify {
  my $self = shift;
  defined $self->{'-text'} ? $self->{'-text'} : "Died";
}


1;
__END__

=pod

=head1 NAME

XML::XSP::Exception - A class to handle module exceptions.

=head1 SYNOPSIS

  use XML::XSP::Exception qw/:try/;

  try {
   ...
   throw XML::XSP::Exception('Error');
  }
  catch XML::XSP::Exception with {
    ...
  }
  otherwise {
    ...
  };

=head1 DESCRIPTION

This class handles exceptions generated within the XML::XSP module.
Read the description for the "Error" package for further details.

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

L<XML::XSP>, L<Error>

=cut
