package Aurora::ComponentFactory;

use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

{
  my ($ID);

  sub new {
    my ($class, %options) = @_;
    return bless {}, $class;
  }

  sub create {
    my ($self, $component, $options) = @_;
    try {
      my ($class, $object);
      $class = $component->{class} ||
	throw Aurora::Exception::Error("No class specified!");

      logdebug("Creating ", $class);
      if(!$class->can('new')){
	my ($file);
      	$file = $class;
	$file =~ s/::/\//g;
	require (join '',$file,'.pm');
      }
      $object = ($class->can('new'))?
	$class->new(id => (join '', 'Component-', ++$ID), %{$component}) :
	  throw Aurora::Exception::Error
	    ("Can't create component instance");
      $self->{$object->id} = $object;
      return $object;
    }
    otherwise {
      logwarn("Component creation failed: ", shift);
      return undef;
    };
  }

  sub delete {
    my ($self, $id) = @_;
    return (exists $self->{$id})? do {delete $self->{$id}; 1;} : 0;
  }

  sub get {
    my ($self, $id) = @_;
    return (defined $id)? $self->{$id} : values %{$self};
  }
}

1;
__END__

=pod

=head1 NAME

Aurora::ComponentFactory - A factory for dynamically loading and creating
Aurora Component instances.

=head1 SYNOPSIS

  use Aurora::ComponentFactory;
  $factory = Aurora::ComponentFactory->new;

  $component = $factory->create
  ({class => 'Aurora::Component::Matcher::URI', name => 'myuri'});

  $component => $factory->get('myuri');

  $factory->delete($component->id);


=head1 DESCRIPTION

This class provides a helper factory to assist in dynamically loading
and creating of Aurora Components.

=head1 CONSTRUCTOR

=over 1

=item B<new>()

Constructs a new component factory instance.

=back

=head1 PROCESSING METHODS

=over 3


=item B<create>(\%component)

This method constructs a new component instance based upon the
supplied hash reference containing the component parameters.

=item B<delete>($id)

This method deletes from memory the component instance for the
supplied component id.

=item B<get>($id)

This method returns a reference to the component instance for the
supplied component id.

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

L<Aurora>, L<Aurora::Component>
