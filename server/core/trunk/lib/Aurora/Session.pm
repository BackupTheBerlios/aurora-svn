package Aurora::Session;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

sub new {
  my ($class, %options) = @_;
  throw Aurora::Exception::Error('Abstract Class');
}

sub key {
  throw Aurora::Exception::Error('Abstract Class');
}

sub fetch {
  throw Aurora::Exception::Error('Abstract Class');
}

sub store {
  throw Aurora::Exception::Error('Abstract Class');
}

sub remove {
  throw Aurora::Exception::Error('Abstract Class');
}

sub lock {
  throw Aurora::Exception::Error('Abstract Class');
}

sub clear {
  throw Aurora::Exception::Error('Abstract Class');
}

sub sib {
  throw Aurora::Exception::Error('Abstract Class');
}


1;
__END__

=pod

=head1 NAME

Aurora::Session - An abstract session class.

=head1 SYNOPSIS

  use Aurora;
  Aurora->new(uri => "aurora.conf");
  $session = Aurora->session;

  $sid = $session->key($context);
  $session->lock(READ => $sid);
  if($oib = $session->fetch($sid)) {
   ...
  }
  else {
    $session->lock(WRITE => $sid);
    ...
    $session->store($session->sib(%data));
  }
  $session->unlock($oid);


=head1 DESCRIPTION

This abstract class provides the base class for all Aurora session
instances.


=head1 PROCESSING METHODS

=over 6

=item B<clear>()

This method removes all session items from the current session store.

=item B<fetch>($sid)

The fetch method returns the session for the given session id. If no
session is found, then this method returns undef.

=item B<lock>($mode, $sid)

This method locks the specifed session id, restricting access to the
session by other processes. The mode dictates the type of lock to be
obtained, valid modes are READ or WRITE.

=item B<sib>(%options)

This method creates a session object that is suitable to be stored in
the current session store from the supplied data.

=item B<remove>($sid)

This method removes the session for the supplied session id from the
current session store.

=item B<store>($sib)

The store method adds the supplied seeion object to the current
session store.

=item B<unlock>($oid)

This method unlocks the specifed session id, enabling free access to
the object by other processes.

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

L<Aurora>, L<Aurora::Session::SIB>
