package Aurora::Resource::RIB;
use strict;

use Digest::MD5 qw/md5_hex/;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Resource;

# should add option to stash cached version of object (for HTTP objects)
# with some kind of cache aging/refresh methods wrapped around it!

{
  my ($data);

  sub new {
    my ($class, %options) = @_;
    my ($self, $now);
    $now = time();
    $self = bless {
		   uri        => ($options{uri}),
		   version    => ((defined $options{type} &&
				   defined $options{type}->{last_modified})?
				  $options{type}->{last_modified} : $now),
		   date       => ((defined $options{type} &&
				   defined $options{type}->{date})?
				  $options{type}->{date} : $now),
		   expires    => ((defined $options{expires})?
				  $options{expires}:
				  (defined $options{type} &&
				   defined $options{type}->{expires})?
				  $options{type}->{expires}: undef),
		   object     => {
				  type => ($options{type} || {}) ,
				  ref  => ($options{ref} || undef),
				 },
		  }, $class;
    # Stop instances clobering each others cached data.
    # Can't think of a better way to do this atm!
    $data->{$self} = $options{data} if $options{data};
    return $self;
  }

  sub id {
    my ($self) = @_;
    $self->{id} = md5_hex($self->{uri}) unless $self->{id};
    return $self->{id};
  }

  sub date {
    my ($self, $date) = @_;
    return (defined $date)? $self->{date} = $date : $self->{date};
  }

  sub expires {
    return shift->{expires};
  }

  sub uri {
    return shift->{uri};
  }

  sub version {
    return shift->{version};
  }

  sub type {
    my ($self, $name, $value) = @_;
    if(defined $value) {
      $name =~ s/\_/\-/g;
      $self->{object}->{type}->{$name} = $value;
      return;
    }
    return (defined $name)?
      do{$name =~ s/\_/\-/g; $self->{object}->{type}->{$name}} :
	((wantarray)? %{$self->{object}->{type}} : $self->{object}->{type});
  }

  sub ref {
    shift->{object}->{type};
  }

  # should figure out reference type, and then do appropriate thingy
  sub object {
    my ($self) = @_;
    my ($object);
  SWITCH: {
      ($object = $data->{$self}) && do {
	# should add TTL stuff
	#$object = $data;
	last SWITCH;
      };
      (!defined  $self->{object}->{ref} ||
       $self->{object}->{ref} =~ /^\w+:\/\//) && do {
	 my ($uri);
	 $uri = $self->{object}->{ref} || $self->{uri};
	 $object = Aurora::Resource->object($uri);
	 $data->{$self} = $object;
	 last SWITCH;
       };
      do {
	$object = $self->{object}->{ref};
	last SWITCH;
      };
    }
    ;
    return $object;
  }

  sub is_valid {
    my ($self) = @_;
    my ($expires);
    $expires = $self->{expires};
    if (defined $expires &&
	(($expires + $self->{date}) > time())) {
      return 1;
    }
    if (Aurora::Resource->is_valid($self)) {
      $self->{date} = time();
      return 2;
    }
    return 0;
  }

  sub DESTROY {
    my ($self) = @_;
    delete $data->{$self};
  }

}
1;

__END__

=pod

=head1 NAME

Aurora::Resource::RIB - A resource identification block

=head1 SYNOPSIS

  use Aurora::Resource::RIB;

  $rib = Aurora::Resource::RIB->new
          (uri  => $uri,
	   type => {'content-length' => 1024,
		    'content-type' => 'text/html',
		    'last-modified' => 1016466597});

  $id  = $rib->id;
  $uri = $rib->uri;

  if($rib->is_valid) {
    $data = $rib->object;
  }


=head1 DESCRIPTION

The RIB (resource identification block) object provides a portable
reference to a remote or local file resource in addition to providing
a wrapper to its metadata.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Constructs a new RIB instance. Valid options are:

=over 5

=item * uri

Sets the uri for this resource. This option is mandatory.

=item * expires

Sets an optional expires time (in seconds), after which this RIB
becomes invalid.

=item * type 

A hash describing the resources metadata. This is usually represented
using HTTP header fields.

=item * ref

A reference to the source file for this resource.

=item * data

The actual contents of the source file for this resource.

=back

=back

=head1 ACCESSOR METHODS

=over 8

=item B<date>()

This method returns the creation date for the resource.

=item B<expires>()

This method returns the period of time that this object will remain
valid for.

=item B<id>()

This method returns the unique id for the object.

=item B<object>()

The object method returns the contents of the underlying resource.

=item B<ref>()

This method returns a reference pointing to the underlying resource.

=item B<type>($name)

This method return the metadata value for the name of the supplied
header.

=item B<uri>()

This method returns the URI of the resource.

=item B<version>()

This method returns the version number of the RIB representing this
resource. If two RIBs share the same ID and version, the both should
point to the same underlying resource.

=back

=head1 PROCESSING METHODS

=over 1

=item B<is_valid>()

This method checks to see if the underlying resource has changed since
this object was instantiated.

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

L<Aurora>, L<Aurora::Resource>
