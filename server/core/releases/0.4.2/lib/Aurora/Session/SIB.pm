package Aurora::Session::SIB;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

sub new {
  my ($class, %options) = @_;
  my ($self, $now);
  $now = time();
  $self = bless {
		 id       => ((defined $options{id})?
			      $options{id} : undef),
		 version  => ((defined $options{date})?
			      $options{date} : $now),
		 date     => ((defined $options{date})?
			      $options{date} : $now),,
		 expires  => ((defined $options{expires})?
			      $options{expires} : undef),,
		 user     => ((defined $options{user})?
			      $options{user} : undef),
		 object   => ((defined $options{object})?
			      $options{object} : {}),
		}, $class;
  return $self;
}

sub id {
  return shift->{id};
}

sub date {
  my ($self, $date) = @_;
  return (defined $date)? $self->{date} = $date : $self->{date};
}

sub expires {
  my ($self, $time) = @_;
  return (defined $time)? $self->{expires} = $time : $self->{expires};
}

sub version {
  return shift->{version};
}

sub user {
  return shift->{user};
}

sub object {
  return shift->{object};
}

sub is_valid {
  my ($self) = @_;
  my ($expires);
  $expires = $self->{expires};
  if (defined $expires &&
      (($expires + $self->{date}) > time())) {
    return 1;
  }
  return (defined $expires)? 0 : 1;
}

1;

__END__

=pod

=head1 NAME

Aurora::Session::SIB - A session identification block

=head1 SYNOPSIS

  use Aurora::Session::SIB;

  $sib = Aurora::Session::SIB->new
          (id      => $id,
	   date    => $date,
	   expires => $expires,
	   user    => $user,
	   object  => $object);

  $id  = $sib->id;

  if($sib->is_valid) {
    $data = $sib->object;
  }


=head1 DESCRIPTION

The SIB (session identification block) object provides a portable
session object.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new SIB instance. Valid options are:

=over 5

=item * date

Sets the create date for this resource, by default this is set to the
current time.

=item * expires

Sets an optional expires time (in seconds), after which this SIB
becomes invalid.

=item * id

This sets the session id for the object. This option is mandatory.

=item * object

This sets the session data object.

=item * user

This sets the user who owns this object.

=back

=back

=head1 ACCESSOR METHODS

=over 5

=item B<date>()

This method returns the last access date for this session.

=item B<expires>()

This method returns the period of time that this session will remain
valid for.

=item B<id>()

This method returns the session id.

=item B<object>()

This method returns the session data object.


=item B<version>()

This method returns the version number of the SIB.


=back

=head1 PROCESSING METHODS

=over 1

=item B<is_valid>()

This method checks to see if the session has expired.

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

L<Aurora>, L<Aurora::Session>
