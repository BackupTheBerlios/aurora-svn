package Aurora::Mount;
use strict;


use Aurora::Constants;

use Aurora::Log;
use Aurora::Exception qw/:try/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 id      => $options{id}      || undef,
		 name    => $options{name}    || $options{id},
		 matcher => [((UNIVERSAL::isa($options{matcher},'ARRAY'))?
			      @{$options{matcher}} :
			      (ref $options{matcher})? $options{matcher}: ())],
		 plugin  => [((UNIVERSAL::isa($options{plugin},'ARRAY'))?
			      @{$options{plugin}} :
			      (ref $options{plugin})? $options{plugin} : ())],
		 event   => [((UNIVERSAL::isa($options{event},'ARRAY'))?
			      @{$options{event}} :
			      (ref $options{event})? $options{event} :())],
		}, $class;


  return $self;
}

sub name {
  my ($self) = @_;
  return $self->{name};
}

sub match {
  my ($self, $context) = @_;
  my ($matches,$success, $match);
  foreach (@{$self->{matcher}}) {
    my ($matcher);
    $matcher = &$_;
    ($success, $match) = $matcher->run($context);
    ($success)? $matches->{$matcher->{name}} = $match : return 0;
  }
  return 0 unless $success;
  $context->matches(%{$matches});
  return 1;
}

sub catch {
  my ($self, $context) = @_;
  my ($event);
  $event = $context->response->status;

  foreach (@{$self->{event}}) {
    {
      no strict 'refs';
      my ($type);
      $type = uc &$_->{type};
      $type =~ tr/\-/\_/;
      next unless
	(($type eq 'ANY') ||
	 ($type eq 'ERROR' && $event >= 400) ||
	 (Aurora::Constants->can($type) &&
	  &{(join '::','Aurora::Constants', $type)} == $event));
      return &$_->run($context);
    }
  }
  return $event;
}

sub run {
  throw Aurora::Exception('Abstract Class');
}



1;

__END__

=pod

=head1 NAME

Aurora::Mount - An abstract Aurora::Mount class.

=head1 SYNOPSIS

  use Aurora::Mount;
  use Aurora::MountFactory;

  $factory = Aurora::MountFactory->new;
  $mount = $factory->create(\%mount, \%options);


=head1 DESCRIPTION

This abstract class provides the base class for all Aurora
mounts. Instances of this class are created automatically by the
Aurora::MountFactory, based upon the supplied parameters.

Mounts represent a handler that dictate how a specified type of
request (as determined by the matcher components assigned to this
mount) should be processed. 

=head1 CONSTRUCTOR

All Aurora::Mount instances should be constructed via the
Aurora::MountFactory class.

=head1 ACCESSOR METHODS

=over 1

=item B<name>()

This method returns the mounts name.

=back

=head1 PROCESSING METHODS

=over 3

=item B<catch>($context)

This method checks to see if this mount can "catch" and handle the
context current event code. If this mount can catch the event, the
the mount will process the request and return the result, otherwise it
will return the current event code.

=item B<match>($context)

This method checks to see if this mounts matchers "matches" against
the current context state. If it does, then the method returns true,
signaling to the server that it should run the context using this
mount.

=item B<run>($context)

This method processes the supplied context, as dictated by the mounts
setup and returns the resultant context.

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

L<Aurora>, L<Aurora::MountFactory>, L<Aurora::Mount::Redirect>,
L<Aurora::Mount::Pipeline>
