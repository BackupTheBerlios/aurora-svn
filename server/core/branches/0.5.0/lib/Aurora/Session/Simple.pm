package Aurora::Session::Simple;
use strict;

use Symbol;
use Fcntl qw/:DEFAULT/;
use Digest::MD5 qw/md5_hex/;



use MLDBM qw/DB_File Storable/;
use MLDBM::Sync;

use Storable qw//;

use Aurora::Server;
use Aurora::Session;
use Aurora::Session::SIB;

use Aurora::Util::File qw/mkpath/;

use Aurora::Log;
use Aurora::Exception qw/:try/;


use vars qw/@ISA/;
@ISA = qw/Aurora::Session/;

use constant SECRET => md5_hex(join '', $$, time(), int(rand(1000)));

# need to add session reaper (similar to cache reaper)

sub new {
  my ($class, %options) = @_;
  my ($self, $root, $secret);
  $root = $options{root} || 'file:///tmp/aurora/session';
  ($root =~ s/^file:\/\///) ||
    throw Aurora::Exception::Error
      (-text => (join '','Invalid session cache root ', $options{root}));

  try {
    unless (-d $root) {
      mkpath($root, 0700);
    }
    if ($options{'purge-on-start'} =~ /(y|yes|1)/i) {
      logsay ('Purging old session data');
      map { unlink (join '/',$root,$_) }
	qw/session.db session.db.lock session.db.secret/;
    }
    if(-f (join '',$root,'/session.db.secret')) {
      sysopen FILE, (join '',$root,'/session.db.secret'), O_RDONLY;
      sysread FILE, $secret, 32;
      close FILE;
    }

    $self = bless {
		   secret => ($secret || SECRET),
		   dbm    => undef,
		   root   => $root,
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
  logsay('Creating session cache ', $root);
  try {
    my (@stat);
    $root = $self->{root};
    @stat = stat $root;
    $dbm = tie (%cache,
		'MLDBM::Sync',
		(join '/',$root,'session.db'),
		O_CREAT|O_RDWR, 0600) ||
		  throw Aurora::Exception::Error
		    (-text => (join '','Failed to create cache ', $!));

    unless(-f (join '/',$root,'session.db.secret')) {
      sysopen FILE, (join '',$root,'/session.db.secret'),
	O_WRONLY|O_CREAT, 0600;
      syswrite FILE, $self->{secret};
      close FILE;
    }

    $self->{dbm} = $dbm;
  }
  otherwise {
    logerror(shift);
    return 0;
  };
  return 1;
}

sub key {
  my ($self, %options) = @_;
  my ($remote, $user, $key);
  $key = md5_hex((join '', $self->{secret},
                  md5_hex((join '',
                           $self->{secret},
                           $options{ip},
			   ($options{user} || 'anonymous'),
			   ($options{version} || 0),
                          ))));
  return $key
}

sub fetch {
  my ($self, $sid) = @_;
  my ($sib);
  $sib = $self->{dbm}->FETCH($sid);
  return (defined $sib)? Storable::thaw($sib) : undef;
}

sub store {
  my ($self, $sib) = @_;
  if(defined $sib) {
    my ($sid, $clone);
    $sid = $sib->id;
    $self->{dbm}->STORE($sid, Storable::freeze($sib));
  }
  return $sib;
}

sub lock {
  # need to do lock for row!!!
  return 1;
}

sub unlock {
  # need to do unlock for row!!!
  return 1;
}


sub remove {
  my ($self, $sid) = @_;
  $sid = $sid->id if UNIVERSAL::isa($sid, 'Aurora::Session::SIB');
  if ($sid && $self->{dbm}->EXISTS($sid)) {
    $self->{dbm}->DELETE($sid);
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
  $self->{dbm}->UnLock;
  return 1;
}

sub sib {
  my ($self) = shift;
  # set default expires
  return Aurora::Session::SIB->new(@_);
}


1

__END__

=pod

=head1 NAME

Aurora::Session::Simple - A simple session store for Aurora.

=head1 DESCRIPTION

This class provides a simple session implementation for Aurora. The
sessionis based around DBM dile store.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new session store. Optional parameters are:

=over 2

=item * root

Sets the path of where the session store should be stored.

=item * purge-on-start

If this option is enabled, then any existing session will be
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

L<Aurora>, L<Aurora::Session>, L<Aurora::Session::SIB>
