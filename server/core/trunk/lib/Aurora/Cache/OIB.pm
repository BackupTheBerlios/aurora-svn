package Aurora::Cache::OIB;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Resource::RIB;

use vars qw/@ISA/;

@ISA = qw/Aurora::Resource::RIB/;


sub dependancy { throw Aurora::Exception('Abstract Class' ) }

1;

__END__

=pod

=head1 NAME

Aurora::Cache::OIB - An abstract Aurora::Cache::OIB class.

=head1 SYNOPSIS


  $cache = Aurora->cache;
  $cache->oib(%options);

  @ribs = $cache->dependancy($id)


=head1 DESCRIPTION

This abstract class provides the base class for all Aurora cache
object instances. It is based around an Aurora resource identification
block providing a portable reference to a local or remote resource.

=head1 PROCESSING METHODS

In addition to the base processing methods, this class also
implements:

=over 1

=item B<dependancy>([$id])

This method returns the list of resource id blocks this cached object
is dependant on. If an id is supplied, then only the resource id block
matching the value will be returned.

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

L<Aurora>, L<Aurora::Resource::RIB>
