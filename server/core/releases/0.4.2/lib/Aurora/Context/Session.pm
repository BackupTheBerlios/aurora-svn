package Aurora::Context::Session;
use strict;

use Aurora::Server;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use constant  RESTORED     => 0;
use constant  NEW          => 1;
use constant  MODIFIED     => 2;
use constant  INVALIDATED  => 3;


# need to lock session so that other processes can't access it!
# option to upgrade session from anonymous->user???
# asession => anonymous
# usession => user session

sub new {
  my ($class, $context, $options) = @_;
  my ($self, $request, $response, $store, $user, $cookie, $sib, $state);
  $request = $context->request;
  $response = $context->response;
  $store = Aurora::Server->session;
  $user = $context->connection->user;

  if($cookie = $request->cookie(($user)? 'usession' : 'asession')) {
    $sib = $store->fetch($cookie->value);
    if(defined $sib) {
      my ($key);
      # if server recognises user, then user authentication is responsibe for
      # security of cookie/IP address of sender, etc!

      $key = $store->key(((defined $user)?
			  (user => $user) :
			  (ip   => $context->connection->ip,
			   date => $sib->version)),
			);
    SWITCH: {
	($sib->id ne $key) && do {
	  logwarn('Bogus session key: ip=', $context->connection->ip,
		  ' user=', $context->connection->user);
	  $sib = undef;
	  last SWITCH;
	};
	(!$sib->is_valid) && do {
	  logsay('Removing stale session ', $sib->id);
	  $store->remove($sib);
	  $sib = undef;
	  last SWITCH;
	};
	do {
	  $sib->date(time());
	  $state = MODIFIED;
	  last SWITCH
	};
      };
    }
    else {
      logsay('Removing invalid cookie');
      $cookie->expires(-1);
      $response->cookie($cookie);
    }
  }

  if(!defined $sib && $options->{create} =~ /1|yes|y/i) {
    my ($date, $expires, $sid);
    $date = time();
    $sid = $store->key(((defined $user)?
			(user => $user) :
			(ip   => $context->connection->ip,
			 date => $date)),
		      );
    $sib = $store->sib(
		       id   => $sid,
		       date => $date,
		       user => $user,
		      );
    $state = NEW;
    throw Aurora::Exception::Error
      (-text => "Session creation failed") unless $sib;
  }

  $self = bless {
		 context  => $context,
		 state    => $state,
		 sib      => $sib
		}, $class;

  return $self;
}

sub id {
  my ($self) = @_;
  return $self->{sib}->id if $self->{sib};
}

sub create_date {
  my ($self) = @_;
  return $self->{sib}->version if $self->{sib};
}

sub last_access {
  my ($self) = @_;
  return $self->{sib}->date if $self->{sib};
}

sub user {
  my ($self) = @_;
  return $self->{sib}->user if $self->{sib};
}

sub expires {
  my ($self, $expires) = @_;
  return unless $self->{sib};
  return ((defined $expires)?
	  $self->{sib}->expires($expires) :
	  $self->{sib}->expires);
}

sub is_new {
  my ($self) = @_;
  return ($self->{state} == NEW) ? 1 : 0;
}


sub is_valid {
  my ($self) = @_;
  return $self->{sib}->is_valid if $self->{sib};
}

sub get {
  my ($self, $name) = @_;
  return undef if $self->{state} == INVALIDATED;
  return $self->{sib}->object->{$name};
}

sub put {
  my ($self, $name, $value) = @_;
  return undef if $self->{state} == INVALIDATED;
  $self->{state} = MODIFIED unless $self->{state} == NEW;
  if (!defined $value) {
    delete $self->{sib}->object->{$name}
  }
  else {
    $self->{sib}->object->{$name} = $value;
  }
  return $value;
}

sub save {
  my ($self, %options) = @_;
  my ($store, $response, $sib, $domain);

  return 1 if $self->{state} == INVALIDATED ||
    $self->{state} == RESTORED;

  $store = Aurora::Server->session;
  $response = $self->{context}->response;
  $sib = $self->{sib};
  $sib->expires($options{expires}) if defined $options{expires};
  $domain = $options{domain} ||
    $self->{context}->request->uri->host;
  # do we want to apply it to all subdomains?
  $domain = substr($domain, index($domain,'.'))
    if $domain =~ tr/\./\./ > 1;
  $store->store($sib);
  # refresh cookie - should limit to not every request
  $response->cookie
    (name    => (($sib->user)? 'usession' : 'asession'),
     value   => $sib->id,
     domain  => $domain,
     expires => $sib->expires,
     path    => '/',
    );

  $self->{state} = RESTORED;
  return 1;
}

sub restore {
  my ($self) = @_;
  unless($self->{state} == NEW || $self->{state} == INVALIDATED) {
    my ($store, $sib);
    $store = Aurora::Server->session;
    $sib = $store->fetch($self->{sib}->id);
    if($sib) {
      $self->{state} = RESTORED;
      $self->{sib} = $sib;
    }
    return 1;
  }
  return 0;
}

sub invalidate {
  my ($self) = @_;
  unless($self->{state} == INVALIDATED) {
    my ($store, $sid);
    $sid = $self->{sib}->id;
    $store = Aurora::Server->session;
    unless($self->{state} == NEW) {
      my ($cookie);
      $cookie = $self->{context}->request->cookie
	(($self->{sib}->user)? 'usession' : 'asession');
      $cookie->expires(-1) if $cookie;
      $store->remove($sid);
    }
    $self->{state} = INVALIDATED;
    $self->{sib} = undef;
    return 1;
  }
  return 0;
}

sub DESTROY {
  my ($self) = @_;
  $self->{context} = undef;
  $self->SUPER::DESTROY if $self->can('SUPER::DESTROY');
}

1;

__END__

=pod

=head1 NAME

Aurora::Context::Session - the user session object for the current
process.


=head1 SYNOPSIS

  use Aurora::Context::Session;

  $session = Aurora::Context::Session->new
    ($context, { create => 1});

  $id = $session->id;
  $create_date = $session->create_date;
  $last_access = $session->last_access;
  $expires = $session->expires;
  $user = $session->user;

  $param = $session->get('myparam');
  $session->put('myparam','myvalue');

  $session->invalidate;
  $is_new = $session->is_new;
  $is_valid = $session->is_valid;
  $session->restore;
  $session->save;

=head1 DESCRIPTION

Aurora::Context::Session provides a wrapper to Auroras persistent user
session store. 

=head1 CONSTRUCTOR

=over 2

=item B<new>($context, [\%options])

Constructs a new Aurora user session object, where the context is the
current process context. The optional options hash can contain a
create parameter, to signify whether a new session should be created
if it doesn't currently exist within the session store.

=back

=head1 ACCESSOR METHODS

=over 7

=item B<create_date>()

Returns the creation date for the current session.

=item B<expires>([$expires])

Returns the length of time that should pass without the session being
accessed before the session should invalidated. If the expires
parameter is provided, then the expires time for the session is set to
that value.

=item B<get>($name)

This method returns the current value for the named parameter, stored
within this session.

=item B<id>()

Returns the value of the current session id.

=item B<last_access>()

Returns the date when this session was last accessed.

=item B<put>($name, $value)

This method sets the named session parameter to the value provided.

=item B<user>()

Returns the username of the user currently associated with this
session or undef if this is an anonymous session.

=back

=head1 PROCESSING METHODS

=over 5

=item B<invalidate>()

This invalidates the current session and causes the session to be
removed from the persistent session store.

=item B<is_new>()

Returns true if the session has just been created and has still be
saved to the persistant session store.

=item B<is_valid>()

This returns true if the current session is still valid, i.e it has
not expired or been invalidated.

=item B<restore>()

This resets all local changes to the session, since it was last taken
from the persistent session store.

=item B<save>()

This saves the changes to current sessions state to the persistent
session store.

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

L<Aurora>, L<Aurora::Context>, L<Aurora::Session>

