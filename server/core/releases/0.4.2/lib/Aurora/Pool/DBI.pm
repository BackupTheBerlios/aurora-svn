package Aurora::Pool::DBI;
use strict;

use DBI;

use Aurora::Log;
use Aurora::Pool;
use Aurora::Exception qw/:try/;

use vars qw/@ISA/;

@ISA = qw/Aurora::Pool/;

use constant ATTRIBUTES => qw/PrintError
                              RaiseError
                              LongReadLen
                              LongTruncOk/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{driver} = $options{driver} ||
    throw Aurora::Exception('No driver supplied');
  $self->{db} = $options{db} || undef;
  $self->{username} = $options{username} || undef;
  $self->{password} = $options{password} || undef;
  $self->{attributes} = ((UNIVERSAL::isa($options{attributes}, 'HASH'))?
			 {(map {((exists $options{lc $_})?
				 ($_ => $options{lc $_}) : ())} ATTRIBUTES )} :
			 {});
  return $self;
}

sub start {
  my ($self) = @_;
  my ($dsn);
  $dsn = (join ':', 'dbi', $self->{driver}, $self->{db});
  $self->{_dbh} =
    (DBI->connect_cached($dsn,
			 $self->{username},
			 $self->{password},
			 {%{$self->{attributes}},
			  (($self->{attributes}->{PrintError})?
			   (HandleError => sub {
			      my ($error, $dbh);
			      ($dbh->{RaiseError})? logwarn($error) :
				throw Aurora::Exception::Error
				  ("DBI error - ", $error);
			      return 0;}) : ())}) ||
     throw Aurora::Exception
     ((join '',
       'DBI: Database connection failed - ',
       $DBI::errstr)));
}

sub stop {
  my ($self) = @_;
  $self->{_dbh}->disconnect if $self->{_dbh};
  $self->{_dbh} = undef;
}

sub get {
  my ($self) = @_;
  $self->start unless $self->{_dbh};
  return $self->{_dbh};
}

sub put {
  my ($self, $dbh) = @_;
  $dbh = undef;
  return undef;
}


1;

__END__


=pod

=head1 NAME

Aurora::Pool::DBI - A database connection Pool.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0">
    <pools>
      <pool name="mydb" class="Aurora::Pool::DBI">
        <driver>Pg</driver>
	<db>dbname="mydb"</db>
	<username>user</username>
	<password>pass</password>
	<attributes printerror="1"/>
      </pool>
    </pools>
  </sitemap>


=head1 DESCRIPTION

This object provides a reusable pool of database connections for
a specific database.

=head1 TAGS

=over 1

=item B<<pool>>

This tag creates a new pool. The pool tag  can take the following
options:

=over 7

=item * B<attributes>

Additional DBI attributes to be passed to the underlying driver. Valid
attributes are printerror, raiseerror, longreadlen & longtrunok.

=item * B<class>

The class of the pool to create.

=item * B<db>

The data source string, specifing the database to use. The exact
nature of this parameter, is dependant on the DBI driver used.

=item * B<driver>

The name of the DBI driver to use.

=item * B<password>

The authentication password to use when accessing the database.

=item * B<name>

The name of the DBI pool.


=item * B<username>

The username to access the database as.


=back

=back

=head1 CAVEATS

The current implementation of Aurora::Pool::DBI provides no support
for customising the number of instances created. At present, one
connection is created for every forked Aurora instance.

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

L<Aurora>, L<Aurora::PoolFactory>, L<Aurora::Pool>, L<DBI>
