package Aurora::Component::Plugin::Authenticator;

use strict;

use Aurora::Context;
use Aurora::Constants qw/:response/;
use Aurora::Component::Plugin;
use Aurora::Exception qw/:try/;
use Aurora::Log;

use vars qw/@ISA $VERSION/;
@ISA = qw/Aurora::Component::Plugin/;

$VERSION = '0.4.1';

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);

  logsay("Authenticator: Registering authentication modules");
  map {
    my ($class, $code);
    $class = $_->{class};

    logdebug("Authenticator: Creating authentication module ", $class);
    unless($code = $class->can('new')){
      my ($file);
      $file = $class;
      $file =~ s/::/\//g;
      require (join '', $file, '.pm');
      $code = $class->can('new');
    }

    ($code)?
      $self->{_authenticators}->{($_->{name} || $_->{class})} =
	$code->($class, %{$_}) :
	  logwarn("Authenticator: Failed to create authentication module",
		  $class);

  } ((UNIVERSAL::isa($options{authenticator}, 'ARRAY'))?
      @{$options{authenticator}} : $options{authenticator});

  logsay("Authenticator: Registering ACLs");
  map {
    my ($authenticator, $acl);
    $acl = $_;
    logdebug("Authenticator: Creating ACL ", $acl->{name});
    if($authenticator = $self->{_authenticators}->{$acl->{type}}) {
      $self->{_acls}->{$acl->{name}} = $authenticator->closure($acl);
    }
    else {
      logwarn('Authenticator: Invalid authenticator ', $acl->{type});
    }

  } (ref $options{acls} eq "ARRAY")? @{$options{acls}} : $options{acls};
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  my ($rules);
  map {
    my ($rule);
    $rule = $_;
    map {
      my ($type);
      $type = $_;
      map {
	push @{$rules}, {$type => $self->{_acls}->{$_}};
      } (split /,/, $rule->{$type});
    } keys %{$rule};

  } ((UNIVERSAL::isa($data->{access},'ARRAY'))?
     @{$data->{access}} : $data->{access});

  return $self->SUPER::closure({_rules => $rules});
}

sub start {
  my ($self) = @_;
  map {$_->start() if $_->can('start')} values %{$self->{authenticators}};
  return 1;
}

sub run {
  my ($self, $context) = @_;
  my ($instance, @rules);
  $instance = $self->instance;
  @rules = ((UNIVERSAL::isa($instance->{_rules},'ARRAY'))?
	    @{$instance->{_rules}} : $instance->{_rules});

  foreach my $rule (@rules) {
    my ($type);
    ($type) = (keys %{$rule});
  SWITCH: {
      # need to sort out authenticate calls and where errors are generated!!
      # since the results depend on whether allow or deny called!!!
      ($type eq "allow") && do {
	throw Aurora::Exception::Event(-event=> FORBIDDEN,
				       -text => "Invalid ACL")
	  if !defined &{$rule->{$type}};
	return 1 if &{$rule->{$type}}->authenticate($context);
	last SWITCH;
      };
      ($type eq "deny" && defined $rule->{$type}) && do {
	throw Aurora::Exception::Event(-event=> FORBIDDEN,
				       -text => "Invalid ACL")
	  if !defined &{$rule->{$type}};
	throw Aurora::Exception::Event(-event=> FORBIDDEN,
				       -text => "Access not authorised")
	  if &{$rule->{$type}}->authenticate($context);
	last SWITCH;
      };
      do  {
	throw Aurora::Exception::Error
	  ('Unsupported access rule ',$type);
      };
    };
  }
  logwarn("Authenticator: No access rules matched");
  throw Aurora::Exception::Event(-event=> FORBIDDEN,
				 -text => "Access not authorised");
}

sub stop {
  my ($self) = @_;
  map {$_->stop() if $_->can('stop')} values %{$self->{authenticators}};
  return 1;
}

1;

__END__


=pod

=head1 NAME

Aurora::Component::Plugin::Authenticator - This plugin provides user
authentication support to Aurora.

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

This plugin forces a user to authenticate themselves with the main
server, before being able to access a mounts content. Authenticator
modules are used to provide the different kinds of authentication
support.


=head1 COMPONENT TAGS

=over 1

=item B<<plugin>>

This tag signals to the sitemap to create a new plugin
component. Options for this tag are:

=over 4

=item * B<<acls>>

The access control list, a set of rules for controling who can access
what resource.

=item * B<<authenticator>>

This tags causes the plugin to load in a authenticator module, one for
each type of authentication enabled. 

=item * B<class>

The class of the plugin to create.

=item * B<name>

The name of the plugin component instance.

=back

=back

=head1 MOUNT TAGS

=over 1

=item B<<plugin>>

This tag sets a plugin for the current mount pipeline. Options for
this tag are:

=over 2

=item * B<<access>>

This sets which acls should be used to allow or deny access to this
mount. Parameters for this tag are either:

=over 2

=item * B<allow>

A list of acls, which if any one evaluates as successful, will allow
that user to access the rest of the mount.

=item * B<deny>

A list of acls, which if any one evaluates as successful, will deny
that user to access the rest of the mount.

=back

=item * B<name>

The name of the plugin component to use.

=back

By default, if none of the access rules succeed, then the plugin
denies access.

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

L<Aurora>, L<Aurora::Component>, L<Aurora::Component::Plugin>,
L<Aurora::Component::Plugin::Authenticator::Module>
