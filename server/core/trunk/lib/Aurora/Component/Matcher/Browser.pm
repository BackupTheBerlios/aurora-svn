package Aurora::Component::Matcher::Browser;

use Aurora::Context;
use Aurora::Component::Matcher;
use Aurora::Exception qw/:try/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Matcher/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  map {
    $self->{browser}->{$_->{name}}  = qr/$_->{useragent}/;
  } ((ref $options{browser} eq "ARRAY")?
     @{$options{browser}} : $options{browser});
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  return $self->SUPER::closure({match => $data});
}

sub run {
  my ($self, $context) = @_;
  my ($instance, $useragent, $matches);
  $instance = $self->instance;
  if($useragent = $context->request->header('User-Agent')) {
    map {
      push @{$matches}, $_ if exists $instance->{browser}->{$_} &&
	$useragent =~ /$instance->{browser}->{$_}/
      } split /,/, $instance->{match};
  }
  return (((scalar $matches)? 1 : 0), $matches);
}


1;
__END__

=pod

=head1 NAME

Aurora::Component::Matcher::Browser - This component matches against
the clients  user-agent.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <matchers>
        <matcher name="browser"
	         class="Aurora::Component::Matcher::Browser">
          <browser name="mozilla5" useragent="^Mozilla/5.0"/>
          <browser name="ie5" useragent="MSIE 5.\d+"/>
        </matcher>
      </matchers>
    </components>
    <mounts>
      <mount matcher:browser="mozilla5">
        ...
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This component matches against the current clients  HTTP user-agent
field.

To use the matcher component, the handler should be added to the mount
declaration, specifying the predefined browser name.


=head1 COMPONENT TAGS

=over 1

=item B<<matcher>>

This tag signals to the sitemap to create a new matcher
component. Options for this tag are:

=over 3

=item * B<class>

The class of the event to create

=item * B<name>

The name of the created component

=item * B<<browser>>

A browser entry, composed of a name and a useragent field. The
useragent field is a regex, which will be applied to the HTTP
user-agent field, to determine a match for this browser entry.

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
