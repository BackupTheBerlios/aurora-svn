package Aurora::Component;
use strict;

use Storable qw/freeze/;
use Digest::MD5 qw/md5_hex/;

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

sub closure {
  my ($self, $data) = @_;
  my ($instance, $private);
  $data ||= {};
  throw Aurora::Exception::Error("Not a component instance")
    unless UNIVERSAL::isa($self, 'Aurora::Component');
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

sub name {
  my ($self) = @_;
  return $self->{name};
}

sub instance { throw Aurora::Exception::Error("Abstract Class") }

sub start    { throw Aurora::Exception::Error("Abstract class") }

sub run      { throw Aurora::Exception::Error("Abstract class") }

sub stop     { throw Aurora::Exception::Error("Abstract class") }


sub DESTROY {
  my ($self) = @_;
  $self->stop() if ref $self;
}


1;
__END__

=pod

=head1 NAME

Aurora::Component - An abstract component class.

=head1 SYNOPSIS

  use Aurora::ComponentFactory;

  $factory = Aurora::ComponentFactory->new;
  $component = $factory->create();

  $component->id;
  $component->name;

  $component->start;
  $closure = $component->closure($instance);
  $instance = &$closure->instance;
  &$closure->run($context);

  $component->stop;


=head1 DESCRIPTION

This abstract class provides the base class for all Aurora
components. Instances of this class are created automatically by the
Aurora::ComponentFactory, based upon the supplied parameters.

Components under Aurora represent a generic part within the processing
pipeline to generate the response. Valid types of components under
Aurora are:

=over 4

=item * Event

Event components determine what the next processing step should be,
once the event has been caught by a mount.

=item * Matcher

Matcher components determine if a mount should process the current
context.

=item * Plugin

Plugins are components that should be run for every request, but do
directly not effect the response. Plugins include authentication and
log handlers.

=item * Pipeline

Pipeline components are used to process the current context and
generate the response.

=back


=head1 CONSTRUCTOR

All Aurora::Component instances should be constructed via the
Aurora::ComponentFactory class.

=head1 ACCESSOR METHODS

=over 3

=item B<id>()

This method returns the components id.

=item B<instance>()

This method returns the current instance data for the current object
instance.

=item B<name>()

This method returns the components name.

=back

=head1 PROCESSING METHODS

=over 4

=item B<closure>(\%data)

Creates a closure, wrapping the supplied instance data to form an
instance component object.

=item B<run>($context)

This method processes the current context and returns a success code.

=item B<start>()

This method causes the components to start and initialise any
persistent state or connections.

=item B<stop>()

This method causes the components within to stop and cleanup any
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

L<Aurora>, L<Aurora::Component::Event>, L<Aurora::Component::Plugin>,
L<Aurora::Component::Pipeline>, L<Aurora::Component::Matcher>
