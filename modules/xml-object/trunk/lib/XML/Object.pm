package XML::Object;
use strict;

use XML::LibXML;
use XML::Object::XPath;
use XML::Object::DriverFactory;

use vars qw/$VERSION $DEBUG/;

$VERSION = qw/0.2.2/;
$DEBUG = 0;

use overload ('""'  => sub { shift->as_string(@_); },
	      'cmp' => sub {
		no warnings;
		my ($self, $object) = @_;
		my (@a, @b, $count);
		return -1 unless UNIVERSAL::isa($object, __PACKAGE__);
		@a = $self->serialize;
		@b = $object->serialize;
		$count = (scalar @a > scalar @b)? scalar @a : scalar @b;
		for(my $i = 0; $i < $count; $i++) {
		  my ($value);
		  $value = $a[$i] cmp $b[$i];
		  return $value if $value;
		}
		return 0;
	      });

sub import {
  my ($class);
  $class = shift;
  map {
    XML::Object::DriverFactory->create(Driver => $_) ||
	XML::Object::DriverFactory->create
	    (Driver => (join '::', 'XML::Object::Driver', $_))
	  } @_;
  return 1;
}


sub new {
  my ($class, %options) = @_;
  my ($self, $driver, $document, $object);

  unless($driver = XML::Object::DriverFactory->create(%options)) {
    die "Object creation failed, invalid driver!";
  }

  $document = ((ref $options{Input} && ref $options{Input} ne 'SCALAR')?
	       $options{Input} :
	       $driver->parse($options{Input}));

  $object = {
	     Tied    => ($options{Tied} || 0),
	     Vivify  => ($options{Vivify} || 1),
	     _dom    => $document,
	     _driver => $driver,
	     _cache  => undef,
	    };

  (($object->{Tied})?
   (tie %{$self}, $class, $object):
   ($self = $object));
  return bless $self, $class;
}

sub fetch {
  my ($self, $key, $as_object) = @_;
  if(defined $self->{_cache} &&
     exists $self->{_cache}->{$key} &&
     !$as_object) {
    return $self->{_cache}->{$key};
  }
  return ((defined $self->{_dom} && defined $self->{_driver})?
	  $self->{_driver}->fetch($self, $key, $as_object) :  undef);
}

sub exists {
  my ($self, $key) = @_;
  if(defined $self->{_cache} && exists $self->{_cache}->{$key}) {
    return 1;
  }
  return ((defined $self->{_dom} && defined $self->{_driver})?
	  $self->{_driver}->exists($self => $key) :
	  0);
}

sub store {
  my ($self, $key, $value) = @_;
  return 0 unless $self->{Vivify} || $self->exists($key);
  if(defined $self->{_dom} && defined $self->{_driver} &&
     $self->{_driver}->store($self, $key, $value)) {
    $self->{_cache} = undef;
    return 1;
  }
  return 0;
}

sub keys {
  my ($self) = @_;
  $self->serialize unless defined $self->{_cache};
  return ($self->{_cache})? keys %{$self->{_cache}} : undef;
}

sub delete {
  my ($self, $key, $as_object) = @_;
  my (@values);
  if(defined $self->{_dom} && defined $self->{_driver}) {
    @values = $self->{_driver}->delete
      ($self, $key, $as_object);
    $self->{_cache} = undef if scalar @values;
  }
  return ((wantarray)? @values :
	  ((scalar @values) < 2)? $values[0] : \@values);
}

sub clear {
  my ($self) = @_;
  if($self->{_driver}) {
    $self->{_cache} = undef;
    $self->{_dom} = $self->{_driver}->parse;
    return 1;
  }
  return 0;
}

sub namespace {
  my ($self);
  $self = shift;
  return (($self->{_driver})?
	  $self->{_driver}->namespace($self, @_) :
	  undef);
}

sub clone {
  my ($self) = @_;
  my ($clone);
  %{$clone} = %{$self};
  if($self->{_driver}) {
    $clone->{_dom} = $self->{_driver}->clone($self->{_dom});
  }
  return bless $clone, ref $self;
}

sub serialize {
  my ($self) = @_;
  unless(defined $self->{_cache}) {
    if(defined $self->{_dom} && defined $self->{_driver}) {
      my ($dom, %cache);
      $dom = $self->{_dom};
      %cache = $self->{_driver}->serialize($self);
      $self->{_cache} = \%cache;
    }
  }
  return (($self->{_cache})?
	  (map { ($_, $self->{_cache}->{$_}) }
	   sort { $a cmp $b } CORE::keys %{$self->{_cache}}) : undef );
}

sub deserialize {
  my ($self, @pairs) = @_;
  if($self->clear) {
    my ($key, $value);
    while(($key, $value) = splice @pairs, 0, 2) {
      $self->store($key, $value);
    }
    return 1;
  }
  return 0;
}

sub as_string {
  my ($self) = @_;
  return (($self->{_driver})?
	  $self->{_driver}->as_string($self->{_dom}) :
	  undef);
}

sub as_dom{
  my ($self, $clone) = @_;
  return (($self->{_driver})?
	  (($clone)? $self->{_driver}->clone($self->{_dom}) : $self->{_dom}) :
	  undef);
}

sub as_sax{
  my ($self);
  $self = shift;
  return (($self->{_driver})?
	  $self->{_driver}->as_sax($self->{_dom}, @_) :
	  undef);
}

sub TIEHASH  {
  my ($class, $self) = @_;
  return bless $self, $class;
}

sub EXISTS {
  my ($self, $key) = @_;
  return $self->exists($key);
}

sub FETCH {
  my ($self, $key) = @_;
  return ((UNIVERSAL::isa((caller)[0], __PACKAGE__))?
	  $self->{$key} : $self->fetch($key));
}

sub STORE {
  my ($self, $key, $value) = @_;
  return ((UNIVERSAL::isa((caller)[0], __PACKAGE__))?
	  ($self->{$key} = $value) : $self->store($key, $value));
}


sub DELETE {
  my ($self, $key) = @_;
  return $self->delete($key);
}

sub CLEAR {
  my ($self);
  return $self->clear;
}

sub FIRSTKEY {
  my ($self) = @_;
  my ($temp);
  $self->keys unless defined $self->{_cache};
  $temp = CORE::keys %{$self->{_cache}};
  return scalar each %{$self->{_cache}};
}

sub NEXTKEY {
  my ($self) = @_;
  return scalar each %{$self->{_cache}};
}

sub DESTROY {}

1;

__END__

=pod

=head1 NAME

XML::Object - This library provides a simple mechanism for
transparently accessing an XML documents and messages.

=head1 SYNOPSIS

  use XML::Object qw/LibXML/;

  # OO API
  $o = XML::Object->new(Input => \$xml);

  $bool = $o->exists('/document/child');

  $value = $o->fetch('/document/child');
  $fragment = $o->fetch('/document/child', 1);
  $clone = $o->clone;

  $o->store('/document/child', $value);
  $o->store('/document/child', $fragment);

  $value = $o->delete('/document/child');
  $fragment = $o->delete('/document/child', 1);
  $o->clear;

  @keys = $o->keys;

  $xml = $o->as_string;
  $dom = $o->as_dom;
  $xml = $o->as_sax(Handler => XML::SAX::Writer->new);

  ($clone eq $o) && do { print 'document semantically the same' };

  # Tied Hash Interface
  $o = XML::Object->new(Tied => 1, Input => \$xml);

  $value = $o->{'/document/child'};
  $o->{'/document/child', 'value'};
  $value = delete $o->{'/document/child'};
  @keys = keys %{$o->{'/document/child'}};

=head1 DESCRIPTION

This library provides a simple wrapper around an XML document,
enabling access to the document as if it was a native Perl
object. It provides an excellent way to quickly integrate ad-hoc
querying and manipulation of XML fragments under Perl, without needing
to write custom parsers, etc. Features include:

=over 6

=item * Object Orientated API

=item * Optional Tied Hash API

=item * Namespace Support 

=item * Support for creation/handling of XML::Object fragments

=item * Auto vivify node paths

=item * Directly alters the underlying input XML document

=back

Given that the library provides direct access to the underlying XML
document (without parsing it into some itermediate state), it is best
suited for situations where only limited querying or maniplulation is
required. If large documents need to be handled or intensive
read/write access to the document is required, then you are probably
better off using either SAX or something like XML::Simple.

XML::Object comes with support for the following underlying XML
document types:

=over 1

=item * LibXML 

=back

However, it should be fairly trival to add support for additional
drivers.

When importing this class into a new package, you have the option to
provide a list of default drivers that XML::Object should use. This
list should contain either the full package name for the driver or
just the last part of the package name (if it's a built in
driver). The first driver specified is always taken to be the absolute
default driver to be used.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Construct a new XML::Object instance. It takes a number of optional
parameters for controlling the behaviour of the library:

=over 3

=item B<Driver> 

Force the library to use a specific underlying driver. If no value is
supplied, then the Library will either use the driver appropriate for
the input data (if a DOM is supplied) or use the specified default
driver.

=item B<Input> 

This specifies the source of the input data. The data should either be
an XML DOM, a scalar reference to a string containing the XML document
or a URI. If no input source is specified, then a empty XML document
is created.

=item B<Tied>

Activates the Tied Hash API, by default this is disabled.

=item B<Vivify>

Activates auto vivify node paths, to automatically create the correct
XML path for the value to be stored. By default this option is enabled. 

=back


=head1 ACCESSOR METHODS

=over 8

=item * B<exists>($xpath)

Tests if the specified xpath node path exists within the underlying
document, returning the total number of node matches.

=item * B<clear>()

Deletes the entire contents of the underlying document.

=item * B<clone>()

Creates an clone of the current XML::Object.

=item * B<delete>($xpath, [$as_fragment])

Deletes the node and child nodes for the specified xpath returning the
deleted node values (this does not include the string values of any
child elements).  If the as_fragment flag is set to true, then this
method will return XML::Object fragment(s) for this node and any
children.

=item * B<fetch>($xpath, [$as_fragment])

Fetches the node value(s) for the specified xpath (this does not
include the string values of any child elements). If the as_fragment
flag is set to true, then this method will return XML::Object
fragment(s) for this node and any children.

=item * B<keys>()

This returns a list of keys corresponding to the xpaths for all the
nodes within the current document that have a value.

=item * B<store>($xpath, $value)

Sets the value of the node(s) for the specified xpath. If the value is
another XML::Object, then all child nodes are replaced by the supplied
fragment otherwise just the string value for the current node is
changed.

If vivify mode is enabled and the entirety or part of the specified
xpath doesn't exist then XML::Object will automatically construct the
path. However, this will only succeed if the supplied xpath maps to one
unique node location within the document. Also, at present only the
following xpath functions are valid:

=over 5

=item * last

=item * local-name

=item * position

=item * name

=item * namespace-uri

=back

When creating paths, XML::Object will always create a new node if
there no node that matches the xpath precisely.

=item * B<namespace>($namespace, [$prefix])

If just a namespace URI is provided, then this method will return the
value of any associated prefixes. Otherwise, if both a namespace and
prefix is supplied, then this will set the underlying namespace to
this prefix.

=back

=head1 PROCESSING METHODS

=over 3

=item B<as_dom>()

This returns an object corresponding to the underlying DOM object as
used by the current XML::Object driver.

=item B<as_string>()

This returns the current XML document as a string.

=item B<as_sax>(%options)

This enables the current XML::Object to be used to as a generator
within a SAX2 pipeline. This method takes one option:

=over 1

=item B<Handle>

The SAX2 handler to use.

=back

=back

=head1 THANKS

To James Clark publishing a Yacc XPath grammar and Barrie Slaymaker
for providing XML::Filter::Dispatcher, the grammer parser of which I
stole.

=head1 LICENCE & AUTHOR

You may use this module under the terms of the Artistic or GNU Pulic
licenses your choice. Also, a portion of XML::Filter::Dispatcher::Parser
is covered by:

  The Parse::Yapp module and its related modules and shell scripts are
  copyright (c) 1998-1999 Francois Desarmenien, France. All rights
  reserved.

  You may use and distribute them under the terms of either the GNU
  General Public License or the Artistic License, as specified in the
  Perl README file.

(c)2002-2004 Darren Graves (darren@iterx.org), All rights reserved.

=head1 SEE ALSO

XML::SAX.

=cut
