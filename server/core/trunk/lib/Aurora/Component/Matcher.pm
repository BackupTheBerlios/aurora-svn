package Aurora::Component::Matcher;
use strict;

use Aurora::Component;
use Aurora::Exception qw/:try/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component/;

sub start {}

sub run   { throw Aurora::Exception::Error("Abstract class") }

sub stop  {}

1;
__END__
=pod

=head1 NAME

Aurora::Component::Matcher - An abstract matcher component class.

=head1 DESCRIPTION

This abstract class provides the base class for all Aurora matcher
components. Instances of this class are created automatically by the
Aurora::ComponentFactory, based upon the supplied parameters.

Matcher components are used to determine if a mount should process the
current context.

=head1 CONSTRUCTOR

All Aurora::Component::Matcher instances should be constructed via the
Aurora::ComponentFactory class.

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

L<Aurora>, L<Aurora::Component>
