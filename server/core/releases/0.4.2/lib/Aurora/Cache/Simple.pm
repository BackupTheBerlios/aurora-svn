package Aurora::Cache::Simple;
use strict;

use Symbol;
use Fcntl qw/:DEFAULT :flock/;

use MLDBM qw/DB_File Storable/;
use MLDBM::Sync;


use Aurora::Server;
use Aurora::Log;
use Aurora::Exception qw/:try/;

use Aurora::Util::File qw/rmtree mkpath/;

use Aurora::Cache;
use Aurora::Cache::Simple::OIB;

use vars qw/@ISA/;
@ISA = qw/Aurora::Cache/;

sub new {
  my ($class, %options) = @_;
  my ($self, $top, $root);
  $root = $options{root} || 'file:///tmp/aurora/cache';

  ($root =~ s/^file:\/\///) ||
    throw Aurora::Exception::Error
      (-text => (join '','Invalid cache root ', $options{root}));

  try {
    unless (-d $root) {
      mkpath($root, 0700);
    }

    if ($options{'purge-on-start'} =~ /(y|yes|1)/i) {
      logsay ('Purging old cache data');
      map { rmtree $_ if $_ =~ /^$root\/(\w\w|cache.db|cache.db.lock)$/ }
	glob (join '/',$root,'*');
    }

    $self = bless {
		   dbm   => undef,
		   root  => $root,
		   locks => undef
		  }, $class;
    return ($self->init(%options))? $self : undef;
  }
  otherwise {
    logerror(shift);
    return undef;
  };
}


sub init {
  my ($self, %options) = @_;
  my ($root, $dbm, %cache);
  try {
    my (@stat);
    $root = $self->{root};
    logsay('Creating cache ', $root);
    @stat = stat $root;
    $dbm = tie (%cache,
		'MLDBM::Sync',
		(join '/',$root,'cache.db'),
		O_CREAT|O_RDWR, 0600) ||
		  throw Aurora::Exception::Error
		    (-text => (join '','Failed to create cache ', $!));
    $self->{dbm} = $dbm;
  }
    otherwise {
      logerror(shift);
      return 0;
    };
  return 1;
}



sub fetch {
  my ($self, $oid) = @_;
  my ($oib);
  $oib = $self->{dbm}->FETCH($oid);
  return $oib;
}

sub store {
  my ($self, $oib, $object) = @_;
  if ((defined $oib && defined $object) ||
      (defined $oib && $oib->ref)) {
    my ($path, $file, $oid);
    $oid = $oib->id;
    if (defined $object) {
      $path =(join '/',
	      $self->{root} ,
	      substr($oid, 0, 2),
	      substr($oid, 2, 2),
	      substr($oid, 4, 2));
      $file = (join '/', $path, $oid);
      (mkpath $path,0700) unless -d $path;
      sysopen(FILE,
	      $file,
	      O_WRONLY|O_CREAT|O_TRUNC|O_BINARY);
      syswrite(FILE, $object);
      close(FILE);
      $oib->ref(join '', 'file://', $file);
    }
    $self->{dbm}->STORE($oid, $oib);
  }
  return $oib;
}

sub lock {
  my ($self, $mode, $oid) = @_;
  $mode ||= 'READ';
  return 0 unless defined $oid;

  unless (defined $self->{locks}->{$oid}) {
    my ($path);
    $path =(join '/',
	    $self->{root},
	    substr($oid, 0, 2),
	    substr($oid, 2, 2),
	    substr($oid, 4, 2));

    (mkpath $path,0700) unless -d $path;

    $self->{locks}->{$oid} = [gensym(), undef];
    sysopen($self->{locks}->{$oid}->[0],
	    (join '',$path, '/',$oid,'.lock'),
	    O_CREAT|O_RDONLY);
  }
  return 1 if ($self->{locks}->{$oid}->[1] || '') eq $mode;

  if (uc $mode eq 'READ') {
    flock($self->{locks}->{$oid}->[0], LOCK_SH);
  }
  else {
    unless(defined $self->{locks}->{global}) {
      my ($path);
      $path = $self->{root};
      (mkpath $path,0700) unless -d $path;

      $self->{locks}->{global} = [gensym(), undef];
      sysopen($self->{locks}->{global}->[0],
	      (join '',$path, '/cache.lock'),
	      O_CREAT|O_RDONLY);
    }

    flock($self->{locks}->{global}->[0], LOCK_EX);
    unless(flock($self->{locks}->{$oid}->[0], LOCK_EX|LOCK_NB)) {
      flock($self->{locks}->{$oid}->[0], LOCK_SH)
	if $self->{locks}->{$oid}->[1] eq 'READ';
      $self->unlock('global');
      return 0;
    }
    $self->unlock('global');
  }
  $self->{locks}->{$oid}->[1] = $mode;
  return 1;
}

sub unlock {
  my ($self, $oid) = @_;
  map {
    close $self->{locks}->{$_}->[0];
    delete $self->{locks}->{$_};
  } ($oid)? $oid : keys  %{$self->{locks}};
  return 1;
}

sub remove {
  my ($self, $oid) = @_;
  $oid = $oid->id if UNIVERSAL::isa($oid, 'Aurora::Cache::OIB');
  if ($oid && $self->{dbm}->EXISTS($oid)) {
    my ($path);
    $path =(join '/',
	    $self->{root},
	    substr($oid, 0, 2),
	    substr($oid, 2, 2),
	    substr($oid, 4, 2));
    $self->{dbm}->DELETE($oid);
    unlink (join '/', $path, $oid);
    return 1;
  }
  return 0;
}


sub clear {
  my ($self) = @_;
  my ($root);
  $root = $self->{root};
  $self->{dbm}->Lock;
  $self->{dbm}->CLEAR;
  map { rmtree $_ if $_ =~ /^$root\/\w\w$/ } glob (join '/',$root,'*');
  $self->{dbm}->UnLock;
  return 1;
}


sub oib {
  my ($self) = shift;
  return Aurora::Cache::Simple::OIB->new(@_);
}


1;

__END__

=pod

=head1 NAME

Aurora::Cache::Simple - A simple file based cache for Aurora.

=head1 DESCRIPTION

This class provides a simple file based caching mechanism for
Aurora. For increased performance, DBM index files are used to store
the cache objects metadata.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new cache. Optional parameters are:

=over 2

=item * root

Sets the path of where the cache data should be stored.

=item * purge-on-start

If this option is enabled, then any existing cache data will be
deleted when the server is started.

=back

=back

=head1 PROCESSING METHODS

See the base class for documentation on the processing methods.

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

L<Aurora>, L<Aurora::Cache>, L<Aurora::Cache::Simple::OIB>
