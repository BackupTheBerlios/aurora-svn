package Aurora::Component::Plugin::Authenticator::Module;

use strict;

use Storable qw/freeze/;
use Digest::MD5 qw/md5_hex/;

use Aurora::Exception qw/:try/;
use Aurora::Log;


sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 id      => ($options{id}   || undef),
		 name    => ($options{name} || $class),
		},$class;
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  my ($instance, $private);
  $data ||= {};
  throw Aurora::Exception::Error("Not a component instance")
    unless UNIVERSAL::isa($self, __PACKAGE__);
  throw Aurora::Exception::Error("Invalid data, not a HASH")
    unless UNIVERSAL::isa($data, 'HASH');

  $instance = {(map {(index($_,'_') == 0)?
		       () : ($_ => $self->{$_}); } keys %{$self}),
	       (map {((index($_,'_') == 0)?
		      do{ $private->{$_} = $data->{$_}; ();} :
		      ($_ => $data->{$_})); } keys %{$data})};

  $instance->{checksum} = md5_hex(freeze($instance));
  $instance->{id} = ((defined $instance->{id})?
		     (join ':', $instance->{checksum}, $instance->{id}) :
		     $instance->{checksum});
  $instance = {%{$instance}, %{$private}} if defined $private;
  return sub {
    no strict;
    no warnings;
    *instance = sub { return $instance };
    *id = sub { return $instance->{id} };
    return $self;
  }
}

sub id {
  my ($self) = @_;
  return $self->{id};
}

sub start {}

sub authenticate {
  throw Aurora::Exception::Error('Abstract class');
}

sub stop  {}

1;

__END__
=pod

=head1 NAME

Aurora::Component::Plugin::Authenticator::Module - An abstract
authenticator module class.

=head1 DESCRIPTION

This abstract class provides the base class for all authenticator
modules, each support a different kind of authentication.

=head1 CONSTRUCTOR

All Aurora::Component::Plugin::Authenticator::Mount instances should
be constructed via the Aurora::Component::Plugin::Authenticator class.

=head1 ACCESSOR METHODS

=over 2

=item B<id>()

This method returns the modules id.

=item B<instance>()

This method returns the current instance data for the current object
instance.

=back

=head1 PROCESSING METHODS

=over 4

=item B<authenticate>($context)

This method authenticates the supplied context, returning true if the
authentications succeeds.

=item B<closure>(\%data)

Creates a closure, wrapping the supplied instance data to form a
module instance.


=item B<start>()

This method causes the module to start and initialise any
persistent state or connections.

=item B<stop>()

This method causes the module within to stop and cleanup any
persistent state or connections.

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

L<Aurora::Component::Plugin::Authenticator>,
L<Aurora::Component::Plugin::Authenticator::Module::IP>,
L<Aurora::Component::Plugin::Authenticator::Module::Cookie>