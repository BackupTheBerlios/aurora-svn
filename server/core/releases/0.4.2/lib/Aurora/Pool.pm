package Aurora::Pool;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 id      => ($options{id}   || undef),
		 name    => ($options{name} || $class),
		},$class;
  return $self;
}

sub id {
  my ($self) = @_;
  return $self->{id};
}

sub name {
  my ($self) = @_;
  return $self->{name};
}


sub start    { throw Aurora::Exception::Error("Abstract class") }

sub get      { throw Aurora::Exception::Error("Abstract class") }

sub put      { throw Aurora::Exception::Error("Abstract class") }

sub stop     { throw Aurora::Exception::Error("Abstract class") }


sub DESTROY {
  my ($self) = @_;
  $self->stop() if ref $self;
}


1;
__END__

=pod

=head1 NAME

Aurora::Pool - An abstract pool class.

=head1 SYNOPSIS

  use Aurora::PoolFactory;

  $factory = Aurora::PoolFactory->new;
  $pool = $factory->create({class => "Aurora::Pool::DBI"});

  $pool->id;
  $pool->name;

  $pool->start;
  $dbh = $pool->get;
  $pool->put($dbh);
  $pool->stop;


=head1 DESCRIPTION

This abstract class provides the base class for all Aurora
pools. Instances of this class are created automatically by the
Aurora::PoolFactory, based upon the supplied parameters.

Pools are collection of objects, where you want to be able control
the number of instances available and promote object reuse. This is
commonly used to control the number of database connections, where
usually only a small number of concurent connections are needed.

=head1 CONSTRUCTOR

All Aurora::Pool instances should be constructed via the
Aurora::PoolFactory class.

=head1 ACCESSOR METHODS

=over 2

=item B<id>()

This method returns the pools id.

=item B<name>()

This method returns the pools name.

=back

=head1 PROCESSING METHODS

=over 4

=item B<get>()

This method returns an object instance from the current pool of
available objects.

=item B<put>($object)

This method returns the supplied object to the pool of available
objects.

=item B<start>()

This method causes the pool to start and initialise any persistent
state or connections.


=item B<stop>()

This method causes the pool to stop and cleanup any persistent state
or connections.

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

L<Aurora>, L<Aurora::PoolFactory>, L<Aurora::Pool::DBI>
