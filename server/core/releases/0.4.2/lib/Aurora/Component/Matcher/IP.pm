package Aurora::Component::Matcher::IP;

use Aurora::Component::Matcher;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Matcher/;


sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  map {
    $self->{ip}->{$_->{name}}  = $_->{addr};
  } (ref $options{ip} eq "ARRAY") ? @{$options{ip}} : $options{ip};
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  return $self->SUPER::closure({match => $data});
}


sub run {
  my ($self, $context) = @_;
  my ($instance, $remote_ip, $matches);
  $instance = $self->instance;
  $remote_ip = $context->connection->ip;

  foreach my $ip (split /,/, $instance->{match} ) {
    my ($addr, $mask, $not, $failed);
    ($addr, $mask) = split /\//, ($instance->{ip}->{$ip} || next), 2;
    $not = ($addr =~ s/^\!//);
    $failed = 0;

    # must force strings into numeric context
    $addr = [map { $_+=0 } split /\./, $addr];
    $mask = [map { $_+=0 } split /\./, $mask];
    $remote = [map { $_+=0 } split /\./,$remote_ip];
    for (my $i = 0; $i < 4; $i++) {
      if (($addr->[$i] & $mask->[$i]) != ($remote->[$i] & $mask->[$i])) {
	$failed = 1;
	last;
      }
    }
    if($failed == $not) {
      push @{$matches}, $ip;
      last;
    }
  }
  return (((scalar $matches)? 1 : 0), $matches);
}

1;
__END__



=pod

=head1 NAME

Aurora::Component::Matcher::IP - This component matches against
the specified IP address or IP address range.


=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <matchers>
        <matcher name="ip"
	         class="Aurora::Component::Matcher::IP">
           <ip addr="127.0.0.1/255.255.255.255"  name="localhost"/>
           <ip addr="192.168.1.0/255.255.255.0"  name="network" />
        <matcher>
      </matchers>
    </components>
    <mounts>
      <mount matcher:ip="localhost">
        ...
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This component matches against the specified IP address or IP address
range of the client connection.
 
To use the matcher component, the handler should be added to the mount
declaration, specifying the IP address ranges to match against (as a
comma seperated list).


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

=item * B<<ip>>

An IP address entry, composed of a name and and addr entry (the ip
address and subnet mask).

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
