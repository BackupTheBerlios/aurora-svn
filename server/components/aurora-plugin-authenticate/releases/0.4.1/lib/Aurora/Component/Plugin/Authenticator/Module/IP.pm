package Aurora::Component::Plugin::Authenticator::Module::IP;

use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Component::Plugin::Authenticator::Module;
use vars qw/@ISA/;

@ISA = qw/Aurora::Component::Plugin::Authenticator::Module/;

sub authenticate {
  my ($self, $context) = @_;
  my ($remote, $addr, $mask);
  logdebug("Authenticator: Running IP authentication");
  $remote = $context->request->header('X-Forwarded-For');
  if(my $ip = (split /,\s*/, $remote)[-1]) {
    $remote = $ip;
  }
  else {
    $remote = $context->connection->ip;
  }

  ($addr, $mask) = split /\//, $self->instance->{addr}, 2;
  # must force strings into numeric context
  $addr = [map { $_+=0 } split /\./, $addr];
  $mask = [map { $_+=0 } split /\./, $mask];
  $remote = [map { $_+=0 } split /\./,$remote];
  for (my $i = 0; $i < 4; $i++) {
    return 0
      if ($addr->[$i] & $mask->[$i]) != ($remote->[$i] & $mask->[$i]);
  }
  return 1;
}

1;

__END__

=pod

=head1 NAME

Aurora::Component::Plugin::Authenticator::Module::IP - This module
provides IP authentication.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher"
    xmlns:plugin="http://iterx.org/aurora/sitemap/1.0/plugin">
    <components>
      <plugins>
        <plugin name="authenticator"
	   class="Aurora::Component::Plugin::Authenticator">
	  <authenticator name="ip"
	  class="Aurora::Component::Plugin::Authenticator::Module::IP"/>
	  <acls>
	    <acl name="localhost" type="ip" 
	      addr="127.0.0.1/255.255.255.255"/>
	    <acl name="localnet"  type="ip" 
              addr="192.168.1.0/255.255.255.0"/>
	  </acls>
        </plugin>
      </plugins>
    </components>
    <mounts>
      <mount matcher:uri="^/(\w*)">
        <plugin:authenticator>
	  <access allow="localnet,localhost"/>
	</plugin:authenticator>
        ...
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This module provides IP authentication for the Authenticator plugin.

=head1 MODULE TAGS

=over 2

=item * B<<acls>>

The access control list, a set of rules for controling who can access
what resource. Parameters include:

=over 3

=item * B<addr>

The network address and subnet mask to match against.

=item * B<name>

The name of the acl.

=item * B<type>

The type of authenticator module to use.

=back

=item * B<<authenticator>>

This tags causes the plugin to load in a authenticator module, one for
each type of authentication enabled. Parameters include:

=over 1

=item * B<class>

The authenticator module to use.

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

L<Aurora::Component::Plugin::Authenticator>,
L<Aurora::Component::Plugin::Authenticator::Module>
