package Aurora::Component::Matcher::Method;

use Aurora::Context;
use Aurora::Component::Matcher;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Matcher/;


sub closure {
  my ($self, $data) = @_;
  return $self->SUPER::closure({match => (uc $data)});
}


sub run {
  my ($self, $context) = @_;
  my ($instance, $method);
  $instance = $self->instance;
  $method = $context->request->method;
  return (grep {
    my ($value, $not);
    $value = $_; $not = ($value =~s/^!//)? 1 : 0;
    ($value eq $method)? !$not : $not;
  } split /,/, ($instance->{match}))? 1 : 0;
}


1;
__END__

=pod

=head1 NAME

Aurora::Component::Matcher::Method - This component matches against
the specified HTTP method.


=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <matchers>
        <matcher name="method"
	         class="Aurora::Component::Matcher::Method"/>
      </matchers>
    </components>
    <mounts>
      <mount matcher:method="GET,POST">
        ...
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This component matches against the specifed HTTP method.

To use the matcher component, the handler should be added to the mount
declaration, specifying the method(s) to match against (as a comma
seperated list).


=head1 COMPONENT TAGS

=over 1

=item B<<matcher>>

This tag signals to the sitemap to create a new matcher
component. Options for this tag are:

=over 2

=item * B<class>

The class of the event to create

=item * B<name>

The name of the created component

=back

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

L<Aurora>, L<Aurora::Component>, L<Aurora::Component::Matcher>
