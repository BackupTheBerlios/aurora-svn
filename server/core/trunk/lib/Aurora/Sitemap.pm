package Aurora::Sitemap;

use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;

use Aurora::Config;
use Aurora::ComponentFactory;
use Aurora::MountFactory;
use Aurora::PoolFactory;

sub new {
  my ($class, %options) = @_;
  my ($self);

  $self = bless {
		 pool       => {},
		 component  => {},
		 mount      => [],
		 factories  => {
				pool      => Aurora::PoolFactory->new,
				component => Aurora::ComponentFactory->new,
				mount     => Aurora::MountFactory->new,
			       }
		}, $class;


  try {
    my ($config);
    if(defined $options{uri}) {
      logsay("Reading configuration ", $options{uri});
      $config = Aurora::Config->reader($options{uri});
      $config = $config->{sitemap};
    }
    else {
      $config = \%options;
    }

    logsay("Registering pools");
    map {
      my ($pool);
      $pool = $self->{factories}->{pool}->create($_);
      $self->register(pool => $pool) if $pool;
    } @{$config->{pools}} if ref $config->{pools};

    logsay("Registering components");
    map {
      my ($component);
      $component = $self->{factories}->{component}->create($_);
      $self->register(component => $component) if $component;
    } map { (ref $_ eq 'ARRAY')? @{$_} : $_ } values %{$config->{components}};

    logsay("Mounting mounts");
    map {
      my ($mount);
      $mount = $self->{factories}->{mount}->create($_, {sitemap => $self});
      $self->register(mount => $mount) if $mount;
    } @{$config->{mounts}};

  }
  otherwise {
    logwarn(shift);
    logwarn("Configuration error");
    return undef;
  };
  return $self;
}



sub start {
  my ($self) = @_;
  map {
    try {
      $_->start();
    }
    otherwise {
      logwarn(shift);
      logwarn("Start failed");
    };
  } ($self->pool, $self->component);
}

sub run {
  my ($self, $context) = @_;
  my ($name);
  logdebug("Finding mount for current context");
  $name = $context->request->name;
  foreach my $mount ($self->mount) {
    if((defined $name && $mount->name eq $name) ||
       (!defined $name && $mount->match($context))) {
      logdebug("Mount ",$mount->name ," matches");
      return $mount;
    };
  }
  throw Aurora::Exception::Event(-event => NOT_FOUND,
				 -text  => "No matching mount found");
}

sub stop {
  my ($self) = @_;
  map {
    try {
      $_->stop();
    }
    otherwise {
      logwarn(shift);
      logwarn("Stop failed");
    };
  } ($self->component,$self->pool);
}


sub pool {
  my ($self, $name) = @_;
  return ($name)? $self->{pool}->{$name} : values %{$self->{pool}};
}

sub mount {
  my ($self, $name) = @_;
  if ($name) {
    map {
      return $_ if $_->{name} eq $name;
    } @{$self->{mount}};
    return undef;
  }
  return @{$self->{mount}};
}

sub component {
  my ($self, $name) = @_;
  return ($name)? $self->{component}->{$name} : values %{$self->{component}};
}


############################################################

sub register {
  my ($self, $type, $object) = @_;
  return unless $type && $object;
  if(ref $self->{$type}) {
    my ($name);
    $name = $object->name;
    logsay('Registering ', $type, ' ', $name);
    if(ref $self->{$type} eq 'ARRAY') {
      push @{$self->{$type}}, $object;
    }
    else {
      logwarn('Replacing existing registered ',$name)
	if $self->{$type}->{$name};
      $self->{$type}->{$name} = $object;
    }
    return 1;
  }
  else {
    logerror('Invalid object type ',$type);
  }
  return 0;
}

sub deregister {
  my ($self, $type, $object) = @_;
  return unless $type && $object;
  if(ref $self->{$type}) {
    my ($name);
    $name = (ref $object)? $object->name : $object;
    logsay('DeRegistering ', $type, ' ', $name);
    if(ref $self->{$type} eq 'ARRAY') {
      $self->{$type} =  grep {
	($_->{name} eq $name)? do { $object = $_; 0;} : 1;
      } @{$self->{$type}};
      return $object;
    }
    else {
      logsay("Deregistering ", $name);
      return ($self->{type}->{$name})? delete $self->{type}->{$name} : undef;
    }
    return 1;
  }
  else {
    logerror('Invalid object type ',$type);
  }
  return 0;
}




1;
__END__

=pod

=head1 NAME

Aurora::Sitemap - An Aurora sitemap.

=head1 SYNOPSIS

  use Aurora::Sitemap;

  $sitemap = Aurora::Sitemap->new(uri => 'aurora.conf');
  $sitemap->register(component => $component);

  $component = $sitemap->component('component-name');
  $mount = $sitemap->mount('mount-name');

  $sitemap->start;
  $sitemap->run($context);
  $sitemap->stop;

=head1 DESCRIPTION

This object provides the current sitemap for virtual host domain,
which specifies how incomming requests are mapped to a mount and then
subsequently processed.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new sitemap instance. The options hash can either
contain a uri parameter, which points to an external XML file
specifying the sitemap or all of the configuration parameters
describing the sitemap.

=back

=head1 ACCESSOR METHODS

=over 3

=item B<component>($name)

This method returns the component that is associated with the supplied
name within this sitemap.

=item B<mount>($name)

This method returns the mount that is associated with the supplied
name within this sitemap.

=back

=head1 PROCESSING METHODS

=over 5

=item B<deregister>($type, $object)

Deregister the object instance of the specifed type (component or
mount) with the current sitemap.

=item B<register>($type, $object)

Register the object instance of the specifed type (component or mount)
with the current sitemap.

=item B<run>($context)

This method processes the current request and returns the mount that
matches this context.

=item B<start>()

This method causes all the components within the current instance to
start and initialise any persistent state or connections.

=item B<stop>()

This method causes all the components within the current instance to
stop and cleanup any persistent state or connections.


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

L<Aurora>, L<Aurora::Mount>, L<Aurora::Component>
