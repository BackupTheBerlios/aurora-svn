package Aurora::Cache::Simple::OIB;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use Aurora::Cache::OIB;
use Aurora::Resource;

use vars qw/@ISA $AUTOLOAD/;
@ISA = qw/Aurora::Cache::OIB/;


sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{id} = ($options{id}||
		 throw Aurora::Exception::Error
		 ('No id specified'));
  $self->{incomming} = ($options{dependancy} || []);
  return $self;
}


sub dependancy {
  my ($self, $id) = @_;
  if(defined $id) {
    for(my $i = (scalar(@{$self->{incomming}}) -1); $i >= 0; $i--) {
      return $self->{incomming}->[$i]->[1]
	if $self->{incomming}->[$i]->[0] eq $id;
    }
    throw Aurora::Exception
      ("Invalid cache object, component data has changed");
  }
  return ((wantarray)?
	  @{$self->{incomming}} : $self->{incomming});
}


sub ref {
  my ($self, $ref) = @_;
  return (defined $ref)? $self->{object}->{ref} = $ref :  $self->{object}->{ref};
}

1;



__END__


=pod

=head1 NAME

Aurora::Cache::Simple::OIB - A cache object ID block for a simple file
cache.

=head1 DESCRIPTION

This class provides an object ID block, to store the content metadata
for a simple file based caching mechanism.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new cache object ID block instance. Valid options are:

=over 4

=item * id

Sets the id for this cache object. This option is mandatory.

=item * dependancy

This option takes a list of RIBs, and sets the list of resources this
cache object is dependant upon.

=item * expires

Sets an optional expires time (in seconds), after which this OIB
becomes in valid.

=item * type 

A hash describing the resources metadata. This is usually represented
using HTTP header fields.


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

L<Aurora>, L<Aurora::Cache::OIB>
