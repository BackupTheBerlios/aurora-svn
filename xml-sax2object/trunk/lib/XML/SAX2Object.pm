package XML::SAX2Object;
use strict;

use XML::SAX;
use XML::SAX::Writer;
use XML::SAX::ParserFactory;

use IO::Handle;

use XML::SAX2Object::Builder;
use XML::SAX2Object::Generator;

use vars qw/$VERSION/;
$VERSION = '0.2.0';

sub new  {
  my ($class, %options) = @_;
  return bless {
		SkipRoot     => ((defined $options{SkipRoot})?
				 $options{SkipRoot} : undef),
		RootName     => ((defined $options{RootName})?
				 $options{RootName} : undef),
		Namespace    => ((defined $options{Namespace})?
				 $options{Namespace} : 0),
		NamespaceIgnore => ((defined $options{NamespaceIgnore})?
				    $options{NamespaceIgnore} : 0),
		NamespaceExpand => ((defined $options{NamespaceExpand})?
				    $options{NamespaceExpand} : 0),
		NamespaceMap => ((UNIVERSAL::isa
				  ($options{NamespaceMap},'HASH'))?
				$options{NamespaceMap} : {}),
		Normalize    => ((defined $options{Normalize})?
				 $options{Normalize} :1 ),
		Dictionary   => ((UNIVERSAL::isa
				  ($options{Dictionary},'HASH'))?
				 $options{Dictionary} : {}),
		Pluralize    => ((defined $options{Pluralize})?
				 $options{Pluralize} :1 )
	       }, $class;
}

sub skiproot {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{SkipRoot} = $value : $self->{SkipRoot});
}

sub normalize {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{Normalize} = $value : $self->{Normalize});
}

sub rootname {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{RootName} = $value : $self->{RootName});
}

sub namespace {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{Namespace} = $value : $self->{Namespace});
}

sub nsmap {
  my ($self);
  $self = shift;
  if(scalar @_ > 1) {
    my ($ns, $prefix);
    while(($ns, $prefix) = splice @_,0,2) {
      $self->{NamespaceMap}->{$ns} = $prefix;
    }
    return;
  }
  return ((scalar @_)?
	  $self->{NamespaceMap}->{$_[0]} :
	  ((wantarray)?
	   %{$self->{NamespaceMap}} :
	   $self->{NamespaceMap}));
}

sub nsexpand {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{NamespaceExpand} = $value : $self->{NamespaceExpand});
}

sub nsignore {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{NamespaceIgnore} = $value : $self->{NamespaceIgnore});
}

sub pluralize {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{Pluralize} = $value : $self->{Pluralize});
}

sub dictionary {
  my ($self);
  $self = shift;
  if(scalar @_ > 1) {
    my ($plural, $singular);
    while(($plural,$singular) = splice @_,0,2) {
      $self->{Dictionary}->{$plural} = $singular;
    }
    return;
  }
  return ((scalar @_)?
	  $self->{Dictionary}->{$_[0]} :
	  ((wantarray)?
	   %{$self->{Dictionary}} :
	   $self->{Dictionary}));
}

sub reader {
  my ($self, $source, $options) = @_;
  my ($handler, $parser);
  $options ||= {};

  $handler = XML::SAX2Object::Builder->new
    (%{$self});
  $parser =  XML::SAX::ParserFactory->parser
    (Handler => $handler);
 SWITCH: {
    (!ref $source) && do {
      $options->{Source}->{SystemId} = $source;
      last SWITCH;
    };
    (UNIVERSAL::isa($source,'IO::Handle')) && do {
      binmode($source);
      $options->{Source}->{ByteStream} = $source;
      last SWITCH;
    };
    do {
      $options->{Source}->{String} = $$source;
      last SWITCH;
    };
  };

  return $parser->parse(%{$options});
}

sub writer {
  my ($self, $object, $options) = @_;
  my ($handler, $parser);
  $options ||= {};
  $handler = XML::SAX::Writer->new(%{$options});
  $parser = XML::SAX2Object::Generator->new(%{$self},
					    %{$options},
					    Handler => $handler);
  return $parser->parse(Object => $object);
}

1;
__END__

=pod

=head1 NAME

XML::SAX2Object - A Perl library for building Objects from SAX2 based events
and vice versa (i.e generating SAX2 events from an Object).

=head1 SYNOPSIS

  use XML::SAX2Object;
  $sax2object =  XML::SAX2Object->new;

  # read in XML from string reference
  $object = $sax2object->reader(\$xml);

  # write out XML from perl object
  $xml = $sax2object->writer($object);

=head1 DESCRIPTION

XML::SAX2Object provides a mechanism for building a Perl datastructure
from SAX2 events and for the reverse process. XML::SAX2Object acts as a
simple API to the underlying SAX2 generator and builder, for situations
where you do not need to bother with setting up your own custom SAX
pipeline.

The mapping of XML to Perl datastructure follow a set of simple rules:

=over 4

=item *

Elements are represented as a HASH, with the element name acting as the
key and the children of the element, it's value.

=item *

Child elements that have the same name, have their values represented
as an ARRAY.

=item *

All Attributes are represented as key/value pairs within the currents
elements HASH. These values will be overwritten if there is a child of
the current element with the same name or the children of the element are
to be represented as an ARRAY.

=item *

If the pluralize mode is enabled, child elements will automatically be
represented as an ARRAY, if the current elements name is the inflection of
the childs name.

=back

It should be noted that the mapping between XML and Perl datastructure
is lossy, with data that doesn't fall under the mapping scheme being
discarded. Therefore, XML::SAX2Object should only be used in situations
where you have control over the XML structure, or it has been checked that
no valuable data is lost in the building process.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%hash)

Construct a new XML::SAX2Object instance. It takes a number of optional
parameters for controlling the behaviour of the underlying SAX2 builder and
generator:

- SkipRoot

- RootName

- Namespace

- NamespaceExpand

- NamespaceMap

- Normalize

- Pluralize

- Dictionary

Their behaviour is covered in the description of the applicable accessor
method for each of the option.

=back


=head1 ACCESSOR METHODS

=over 8

=item * B<skiproot>(bool) [reader/writer]

Skip processing the root node of the document. When enabled, a reader
will ignore the root document node of the incomming XML file, while a
writer will not write out the default root node specified by the
RootName option.

By default this is disabled.

=item * B<rootname>(string) [writer]

Set the name for the root node of the output document. This root node will
only be output if the SkipRoot option is disabled.

The default value is 'document'.

=item * B<namespace>(bool) [reader/writer]

Enable namespace support within XML::SAX2Object. For the reader, this will
result in the namespace prefix information being retained, while for the
writer this information will correctly create the correct namespace
declarations. The exact behaviour exhibited, is alterable by the
NamespaceExpand and NamespaceMap options.

By default this is disabled.

=item * B<nsexpand>(bool) [reader/writer]

In conjuction with namespace support enabled, will result in the element
prefix being expanded to display the full namespace URI.

By default this is disabled.


=item * B<nsignore>(bool) [reader/writer]

In conjuction with namespace support enabled, will result in all elements
that have not been declared by the namespace map being ignored.

By default this is disabled.

=item * B<nsmap>(%hash) [reader/writer]

This sets up the namespace mapping of prefixes to namespace URIs to be
used when processing the data.

=item * B<normalize>(bool) [reader]

When enabled, all whitespace read will be normalized.

By default this is enabled.

=item * B<pluralize>(bool) [reader/writer]

When enabled, this will automatically cause inflected names to be
represented as arrays. Currently, only partial English language is
supported natively.

By default this is enabled.

=item * B<dictionary>(%hash) [reader/writer]

This sets up a default mapping of plural words to singular words. This
is used when in pluralize mode, to look up user defined words.

=back

=head1 PROCESSING METHODS

=over 2

=item B<reader>($source, $options)

The reader method accepts a source reference and an optional hash
of configuration options. The source reference can either a URI,
a file handle or a reference to string containing the XML source. It
will then preceed to process and return a Perl datastructure representing
the XML source.

=item B<writer>($object, $options)

This accepts a Perl datastructure and an optional hash of configuration
options. The optional hash can also contain an Output option, which
dictates where the output XML is written. The Output option can either be
a file handle, file name or a scalar reference. The writer method then
takes object and outputs an XML representation of the datastructure.

By default this method returns a string representing the data structure
as XML, unless an output option is specified.

=back

=head1 LICENCE & AUTHOR

This module is released under the Perl Artistic Licence and
may be redistributed under the same terms as perl itself.

(c)2002-2004 Darren Graves (darren@iterx.org), All rights reserved.

=head1 SEE ALSO

XML::SAX2Object::Generator, XML::SAX2Object::Builder & XML::SAX.

=cut
