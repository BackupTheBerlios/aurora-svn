package Aurora::Component::Plugin::Authenticator::Module::Cookie;
use strict;

use Digest::MD5 qw/md5_hex/;
use Aurora::Util qw/str2time/;
use Aurora::Server;
use Aurora::Resource;
use Aurora::Exception qw/:try/;
use Aurora::Log;
use Aurora::Context::Cookies;
use Aurora::Component::Plugin::Authenticator::Module;

use vars qw/@ISA/;

@ISA = qw/Aurora::Component::Plugin::Authenticator::Module/;

# need to make more random....
use constant SECRET => (join '', $$, time(), int(rand(99999999)));

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{expires} = str2time($options{expires});
  $self->{secret}  = $options{secret} || SECRET;
  $self->{domain}  = $options{domain} || Aurora::Server->name;
  $self->{path}    = $options{path}   || '/';
  $self->{secure}  = $options{secure} || 0;
  $self->{users}   = $options{users}  || undef;
  $self->{groups}  = $options{groups} || undef;
  $self->{_cache} = {};
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  $data->{expires} = str2time($data->{expires});
  return $self->SUPER::closure($data);
}

sub authenticate {
  my ($self, $context) = @_;
  my ($instance, $request, $cookie, $ticket, $user, $ok);
  logdebug("Authenticator: Running Cookie authentication");
  $instance = $self->instance;
  $request = $context->request;

  $ticket = $request->cookie('ticket');
  $user = $request->cookie('user');

  $ok = (defined  $self->key($context, $ticket, $user))? 1 : 0;
  unless($ok) {
    my ($username);
    $username = $request->param('username');

    if($self->validate(username => $username,
		       password => $request->param('password'))) {
      my ($key);
      logdebug('Authenticator: Validated user ', $username);
      $user = Aurora::Context::Cookies::Cookie->new
	(name    => 'user',
	 value   => $username,
	 expires => $instance->{expires},
	 domain  => $instance->{domain},
	 path    => $instance->{path},
	 secure  => $instance->{secure});
      $ticket = Aurora::Context::Cookies::Cookie->new
	(name    => 'ticket',
	 value   => undef,
	 expires => $instance->{expires},
	 domain  => $instance->{domain},
	 path    => $instance->{path},
	 secure  => $instance->{secure});
      if($key = $self->key($context, $ticket, $user, 1)) {
	$ticket->value($key);
	$context->response->cookie($ticket);
	$context->response->cookie($user);
	$ok = 1;
      }
    }
  }
  return (($ok)? $ok :
	  do { logwarn('Authenticator: Failed to authenticate user ',
		       (defined $user)? $user->value : 'unknown'); 0;});
}

sub validate {
  my ($self, %options) = @_;
  my ($instance, $username, $password, $loader, $users, $groups);
  $instance = $self->instance;
  $username = $options{username};
  $password = $options{password};

  $loader = sub {
    my ($uri) = @_;
    return undef unless defined $uri;
    return try {
      my ($rib);
      if((($rib = $self->{_cache}->{$uri}->[0]) &&
	  Aurora::Resource->is_valid($rib))) {
	return $self->{_cache}->{$uri}->[1];
      }
      else {
	my ($data);
	$data = {};
	if($rib = Aurora::Resource->fetch($uri)) {
	  map {
	    $_ =~ /^(.*?)\s*:\s*(.*?)\s*$/;
	    $data->{$1} = $2;
	  } split /\n/, $rib->object;
	  $self->{_cache}->{$uri} = [$rib, $data];
	  return $data;
	}
      }
    }
    otherwise {
      logwarn('Authenticator: Validation failed - ', shift);
    };
    return undef;
  };

  unless ($username && $password) {
    logwarn('Authenticator: No username and/or password specified');
    return 0;
  }
  $users  = $loader->($instance->{users});
  $groups = $loader->($instance->{groups});

  return 0
    if($instance->{group} &&
       (grep {
	 my ($not, $group);
	 $group = $_; $not = ($group =~ s/^!//) ? 1 : 0;
	 ($groups->{$group} =~/(\A|\,)($username)(\Z|\,)/)? $not : !$not;
       } split /,/, $instance->{group}));

  return 0
    if(($instance->{user} &&
	!($instance->{user} =~ /(\A|\,)($username)(\Z|\,)/)));

  return (((crypt $password, (substr $users->{$username}, 0, 2))
	   eq $users->{$username})? 1 : 0);
}

sub key {
  my ($self, $context, $ticket, $user, $create) = @_;
  my ($instance, $remote, $key, );
  $instance = $self->instance;
  $remote = $context->request->header('X-Forwarded-For');
  if(my $ip = (split /,\s*/, $remote)[-1]) {
    $remote = $ip;
  }
  else {
    $remote = $context->connection->ip;
  }
  $key = md5_hex((join '',
		  $instance->{secret},
		  md5_hex((join '|',
			   $instance->{secret},
			   $remote,
			   ((defined $user)? $user->value : '-'),
			   ((defined $ticket)? $ticket->expires : '-'),
			  ))));

  return (defined $ticket &&
	  ($key eq $ticket->value || $create))? $key : undef;
}

1;


__END__

=pod

=head1 NAME

Aurora::Component::Plugin::Authenticator::Module::Cookie - This module
provides cookie based ticket authentication.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher"
    xmlns:plugin="http://iterx.org/aurora/sitemap/1.0/plugin">
    <components>
      <plugins>
        <plugin name="authenticator"
	   class="Aurora::Component::Plugin::Authenticator">
	  <authenticator name="cookie"
	  class="Aurora::Component::Plugin::Authenticator::Module::Cookie">
	    <users>file:///web/etc/passwd</users>
	    <groups>file:///web/etc/group</groups>
	  </authenticator>
	  <acls>
	    <acl name="administrator" type="cookie"
	      user="administrator"/>
	    <acl name="staff" type="cookie"
	      group="staff"/>
	  </acls>
        </plugin>
      </plugins>
    </components>
    <mounts>
      <mount matcher:uri="^/(\w*)">
        <plugin:authenticator>
	  <access allow="administrator"/>
	</plugin:authenticator>
        ...
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This module provides cookie based ticket authentication. Valid users and
group information used in the authentication process are stored in
flat files.

=head1 MODULE TAGS

=over 2

=item * B<<acls>>

The access control list, a set of rules for controling who can access
what resource. Parameters include:

=over 3

=item * B<group>

A list of valid groups, for which to check if the current user is a
member of for this acl.

=item * B<name>

The name of the acl.

=item * B<type>

The type of authenticator module to use.

=item * B<user>

A list of valid users for this acl.

=back

=item * B<<authenticator>>

This tags causes the plugin to load in a authenticator module, one for
each type of authentication enabled. Parameters for the cookie module
include:

=over 7

=item * B<class>

The authenticator module to use.

=item * B<domain>

Sets the default domain that the cookie should be set to.

=item * B<expires>

Sets the length of time the cookie is valid for.

=item * B<groups>

Specifies the URI of the file containing the group information. The
format of the group file is a group name appearing  first on a line,
followed by a colon, and then a comma seperated list of the members of
the group.


=item * B<path>

Sets the default path that the cookie should be set t.o

=item * B<secure>

Sets the secure flag on the cookie.

=item * B<users>

Specifies the URI of the file containing the users information. The
format of the users file is a user name appearing first on a line,
followed by a colon, and then the crypt encoded password.

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
