package Aurora::Cache;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

sub new {
  my ($class, %options) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub fetch {
  my ($self, $context) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub store {
  my ($self, $context) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub lock {
  my ($self, $context) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub unlock {
  my ($self, $context) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub remove {
  my ($self, $context) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub clear {
  my ($self) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub oib {
  my ($self) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}


1;

__END__

=pod

=head1 NAME

Aurora::Cache - An abstract cache class.

=head1 SYNOPSIS

  use Aurora;
  Aurora->new(uri => "aurora.conf");
  $cache = Aurora->cache;

  $cache->lock(READ => $oid);
  if($oib = $cache->fetch($oid)) {
   ...
  }
  else {
    $cache->lock(WRITE => $oid);
    ...
    $cache->store($cache->oib(%data), $content);
  }
  $cache->unlock($oid);


=head1 DESCRIPTION

This abstract class provides the base class for all Aurora cache
instances.

=head1 PROCESSING METHODS

=over 6

=item B<clear>()

This method removes all cache items from the current cache.

=item B<fetch>($oid)

The fetch method returns the cache item for the given object id. If no
item is found, then this method returns undef.

=item B<lock>($mode, $oid)

This method locks the specifed object id, restricting access to the
object by other processes. The mode dictates the type of lock to be
obtained, valid modes are READ or WRITE.

=item B<oib>(%options)

This method creates a cache object that is suitable to be stored in
the current cache from the supplied data.

=item B<remove>($oid)

This method removes the cache item for the supplied object id from the
current cache.

=item B<store>($oib, $content)

The store method adds the supplied cache object and associated content
to the current cache.

=item B<unlock>($oid)

This method unlocks the specifed object id, enabling free access to
the object by other processes.

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

L<Aurora>, L<Aurora::Cache::OIB>
