package Aurora::Component::Pipeline;
use strict;

use Aurora::Component;
use Aurora::Constants qw/:internal/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component/;

sub start {}

sub stop  {}

sub cache { return 0; }

sub is_valid {
  my ($self, $context, $oib) = @_;
  my ($instance, $dependancy);
  $instance = $self->instance;
  if($oib->expires &&
     (($oib->date + $oib->expires) > time())) {
    return OK;
  }
  $instance = $self->instance;
  $dependancy = $oib->dependancy($instance->{id});
  if(defined $dependancy && ref $dependancy eq "ARRAY") {
    return DELETE
      if grep { ($_->is_valid)? 0 : 1 } @{$dependancy};
  }
  return DECLINED;
}

1;
__END__

=pod

=head1 NAME

Aurora::Component::Pipeline - An abstract pipeline component class.

=head1 DESCRIPTION

This abstract class provides the base class for all Aurora pipeline
components. Instances of this class are created automatically by the
Aurora::ComponentFactory, based upon the supplied parameters.

Pipeline components are used to process the current context and
generate the response. There are three types of pipeline component:

=over 3

=item * producer

Every pipeline must specify a producer component. This type of
component is responsible for creating the source XML document for the
pipeline.

=item * transformer

A pipeline can zero or more different transformer components, with
which the current XML document can be manipulated and altered.

=item * serializer

Every pipeline must specify a serializer component. This type of
component is responsible for serializing the resultant document, to
its native format.

=back


=head1 CONSTRUCTOR

All Aurora::Component::Pipeline instances should be constructed via
the Aurora::ComponentFactory class.

=head1 ACCESSOR METHODS

In addition to the base accessor methods, this class also implements:

=over 1

=item B<cache>()

This method returns whether the current pipeline component results can
be cached or not.

=back

=head1 PROCESSING METHODS

In addition to the base processing methods, this class also
implements:

=over 1

=item B<is_valid>($context, $oib)

This method checks if for the context supplied that the cached object
for this component is currently valid.

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
