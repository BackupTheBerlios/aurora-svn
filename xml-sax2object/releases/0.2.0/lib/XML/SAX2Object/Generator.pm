package XML::SAX2Object::Generator;
use strict;

use XML::SAX::Base;
use XML::SAX2Object::Inflect qw/singular plural/;
use vars qw/@ISA/;
@ISA = qw/XML::SAX::Base/;

use constant NS_XML   => 'http://www.w3.org/XML/1998/namespace';
use constant NS_XMLNS => 'http://www.w3.org/2000/xmlns/';

sub new {
  my ($class, %options) = @_;
  my ($self);
  $class = shift;
  $self = $class->SUPER::new(@_);
  $self->{SkipRoot} = ((defined $options{SkipRoot})?
		       $options{SkipRoot} : 1);
  $self->{RootName} = ($options{RootName} || 'document');
  $self->{Namespace} = ((defined $options{Namespace})?
			$options{Namespace} : 0);
  $self->{NamespaceExpand} = ((defined $options{NamespaceExpand})?
			      $options{NamespaceExpand} : 0);
  $self->{NamespaceIgnore}  = ((defined $options{NamespaceIgnore})?
			      $options{NamespaceIgnore} : 0);
  $self->{NamespaceMap} = {
			   '#default' => '#default',
			   'xml'      => NS_XML,
			   'xmlns'    => NS_XMLNS,
			   (UNIVERSAL::isa($options{NamespaceMap},'HASH')?
			    %{$options{NamespaceMap}} : ())
			  };

  $self->{Pluralize} = ((defined $options{Pluralize})?
			$options{Pluralize} : 1);
  $self->{Dictionary} = ((UNIVERSAL::isa
			  ($options{Dictionary},'HASH'))?
			 $options{Dictionary} : {});
  $self->{InScopeNamespaces} = {};

  $self->dictionary(%{$options{Dictionary}})
    if UNIVERSAL::isa($options{Dictionary},'HASH');

  return $self;
}

sub skiproot {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{SkipRoot} = $value : $self->{SkipRoot});
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

sub dictionary {
  my ($self);
  $self = shift;
  if(scalar @_ > 1) {
    my ($plural, $singular);
    while(($plural,$singular ) = splice @_,0,2) {
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

sub pluralize {
  my ($self, $value) = @_;
  return ((defined $value)?
	  $self->{Pluralize} = $value : $self->{Pluralize});
}

sub parse_file   { warn "parse_file not supported"; }

sub parse_uri    { warn "parse_uri not supported"; }

sub parse_string { warn "parse_string not supported";}

sub parse {
  my ($self, %options) = @_;
  my ($object, $root);
  $object = $options{Object};
  unless ($object && ref $object) {
    die "No source object supplied!\n";
  }
  $root = $self->parse_start;
  $self->parse_chunk($object);
  return $self->parse_stop($root);
}

sub parse_start {
  my ($self, $root) = @_;
  $self->start_document({});
  unless($self->{SkipRoot}) {
    $root ||= $self->create_element($self->{RootName});
    $self->start_element($root) if defined $root;
  }
  return $root;
}

sub parse_stop {
  my ($self, $root) = @_;
  unless($self->{SkipRoot}) {
    $root ||= $self->create_element($self->{RootName});
    $self->end_element($root) if defined $root;
  }
  return $self->end_document({});
}

sub parse_chunk {
  my ($self, $object, $parent) = @_;
 SWITCH: {
    (UNIVERSAL::isa($object,'HASH')) && do {
      foreach my $key (sort keys %{$object}) {
	my ($element, $mapping);
	$element = $self->create_element($key);
	if(UNIVERSAL::isa($object->{$key},'ARRAY') &&
	   (!$self->{Pluralize} ||
	    (!exists $self->{Dictionary}->{$key} &&
	     plural($key) ne $key))) {
	  $self->parse_chunk($object->{$key}, $element)
	    if defined $object->{$key};
	}
	else {
	  $mapping = $self->create_mapping($element) if defined $element;
	  if(defined $mapping) {
	    $self->start_prefix_mapping($mapping) unless
	      $self->{InScopeNamespaces}->{$mapping->{NamespaceURI}};
	    $self->{InScopeNamespaces}->{$mapping->{NamespaceURI}}++;
	  }
	  $self->start_element($element) if defined $element;
	  $self->parse_chunk($object->{$key}, $element)
	    if defined $object->{$key};
	  $self->end_element($element) if defined $element;
	  if(defined $mapping) {
	    $self->end_prefix_mapping($mapping);
	    $self->{InScopeNamespaces}->{$mapping->{NamespaceURI}}--;
	  }
	}
      }
      last SWITCH;
    };
    (UNIVERSAL::isa($object,'ARRAY')) && do {
      my ($element, $mapping, $singular);
      %{$element} =  %{$parent} if $parent;

      if($self->{Pluralize} && $parent &&
	 ($singular = singular($element->{LocalName},
			       $self->{Dictionary}))) {
	$element->{LocalName} = $singular;
	$element->{Name} = (($element->{Prefix})?
			    (join '', $element->{Prefix},':',$singular):
			    $singular);
      }

      map {
	if(UNIVERSAL::isa($_,'ARRAY')) {
	  $self->parse_chunk($_, $element)
	    if defined $_;
	}
	else {
	  $mapping = $self->create_mapping($element) if defined $element;
	  if(defined $mapping) {
	    $self->start_prefix_mapping($mapping) unless
	      $self->{InScopeNamespaces}->{$mapping->{NamespaceURI}};
	    $self->{InScopeNamespaces}->{$mapping->{NamespaceURI}}++;
	  }
	  $self->start_element($element)
	    if defined $element;
	  $self->parse_chunk($_, $element)
	    if defined $_;
	  $self->end_element($element)
	    if defined $element;

	  if(defined $mapping) {
	    $self->end_prefix_mapping($mapping);
	    $self->{InScopeNamespaces}->{$mapping->{NamespaceURI}}--;
	  }
	}
      } @{$object};

      last SWITCH;
    };
    do {
      $self->characters($self->create_text($object)) if defined $parent;
      last SWITCH;
    };
  };
}


sub create_attribute {
  my ($self, $name, $options) = @_;
  my ($attribute, $prefix, $localname);
  if($self->{Namespace}) {
    if($self->{NamespaceExpand}) {
      my ($namespace);
      ($namespace, $localname) = ($name =~ /^\{(.*)\}(.*)$/);
      if($namespace) {
	my ($pre, $ns, $max);
	$max = 1;
	while(($pre, $ns) = (each %{$self->{NamespaceMap}})) {
	  if($ns eq $namespace) {
	    $prefix = $pre;
	    last;
	  }
	}
	unless(defined $prefix) {
	  my ($max);
	  $max = 1;
	  while(exists $self->{NamespaceMap}->{"ns$max"}) { $max++; }
	  $prefix = "ns$max";
	  $self->{NamespaceMap}->{$prefix} = $namespace;
	}
	$name = (join ':', $prefix, $localname);
      }
    }
    elsif(index($name,':') > 0) {
      ($prefix, $localname) = (split /:/, $name, 2)
    }
  }

  $attribute = {
                Name         => $name,
                Value        => $options->{Value},
                NamespaceURI => (($self->{Namespace} == 0)?
				 undef :
				 (($options->{NamespaceURI})?
				  $options->{NamespaceURI} :
				  (($prefix)?
				   $self->{NamespaceMap}->{$prefix} :
				   $self->{NamespaceMap}->{'#default'}))),
                Prefix       => $prefix,
                LocalName    => ($localname || $name)
	       };
  return $attribute;
}

sub create_mapping {
  my ($self, $element) = @_;
  my ($mapping);
  if($self->{Namespace} && $element->{NamespaceURI}) {
    $mapping = {
		Prefix       => $element->{Prefix},
		NamespaceURI => $element->{NamespaceURI}
	       };
  }
  return $mapping;
}

sub create_element {
  my ($self, $name, $options) = @_;
  my ($element, $prefix, $localname);
  if($self->{Namespace}) {
    if($self->{NamespaceExpand}) {
      my ($namespace);
      ($namespace, $localname) = ($name =~ /^\{(.*)\}(.*)$/);
      if($namespace) {
	my ($pre, $ns);
	while(($pre, $ns) = (each %{$self->{NamespaceMap}})) {
	  if($ns eq $namespace) {
	    $prefix = $pre;
	    last;
	  }
	}
	unless(defined $prefix) {
	  my ($max);
	  $max = 1;
	  while(exists $self->{NamespaceMap}->{"ns$max"}) { $max++; }
	  $prefix = "ns$max";
	  $self->{NamespaceMap}->{$prefix} = $namespace;
	}
	$name = (join ':', $prefix, $localname);
      }
    }
    elsif(index($name,':') > 0) {
      ($prefix, $localname) = (split /:/, $name, 2)
    }

    return undef
      if $self->{NamespaceIgnore} &&
	!exists $self->{NamespaceMap}->{($prefix || '#default')};
  }

  $element = {
              Name         => $name,
              Attributes   => {},
              NamespaceURI => (($self->{Namespace} == 0)?
			       undef :
			       (($options->{NamespaceURI})?
				$options->{NamespaceURI} :
				(($prefix)?
				 $self->{NamespaceMap}->{$prefix} :
				  $self->{NamespaceMap}->{'#default'}))),
	      Prefix       => ($prefix || ''),
              LocalName    => ($localname || $name)
             };
  return $element;
}

sub create_text {
  my ($self, $data) = @_;
  return { Data => $data };
}


1;
__END__

=pod

=head1 NAME

XML::SAX2Object::Generator - A SAX2 Generator, that takes a Perl
datastructure and outputs SAX2 events.

=head1 SYNOPSIS

  use XML::SAX2Object::Generator;

  $parser = XML::SAX2Object::Generator->new(Handler => $handler);

  # In simple mode
  $parser->parse(Object => $object);

  # In stream mode
  $parser->parse_start;
  $parser->parse_chunk($object_a);
  $parser->parse_chunk($object_b);
  $parser->parse_stop;


=head1 DESCRIPTION

XML::SAX2Object::Generator is a SAX2 Generator for creating SAX2
events from a Perl datastructure. The generator has 2 modes of operation:

=head2 Simple

In this mode, SAX2 events are generated from an input object, which is
taken to represent an XML document.

=head2 Stream

The stream mode provides much greater flexibility to how the events are
generated. Once the stream mode has been started, you can feed the
generator chunks of the final object, as you get them. This is useful
in situations where you need to generate events, from say a database
query.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%hash)

Construct a new XML::SAX2Object::Generator instance. It takes a number of
optional parameters,

- SkipRoot

- RootName

- Namespace

- NamespaceExpand

- NamespaceIgnore

- NamespaceMap

- Pluralize

- Handler

The Handler takes the a reference to the next SAX2 handler within the
pipeline. Apart from this, the other options are covered in the description
of the applicable accessor method.

=back

=head1 ACCESSOR METHODS

=over 7

=item * B<skiproot>(bool)

Skip processing the root node of the document. When enabled the generator
will write out the default root node specified by the RootName option.

By default this is enabled.

=item * B<rootname>(string)

Set the name for the root node of the output document. This root node will
only be output if the SkipRoot option is disabled.

The default value is 'document'.

=item * B<namespace>(bool)

Enable namespace support within XML::SAX2Object. The exact behaviour
exhibited, is alterable by the NamespaceMap options.

By default this is disabled.

=item * B<nsexpand>(bool)

In conjuction with namespace support enabled, will result using the
namespace information extracted from the name.

By default this is disabled.

=item * B<nsignore>(bool)

In conjuction with namespace support enabled, will result in all elements
that have not been declared by the namespace map being ignored.

By default this is disabled.

=item * B<nsmap>(%hash)

This sets up the namespace mapping of prefixes to namespace URIs to be
used when processing the data.


=item * B<pluralize>(bool)

When enabled, this will automatically cause arrays to be represented as
a list of elements wrapped with by a parent element with an inflected name.

By default this is enabled.

=item * B<dictionary>(%hash)

This sets up a default mapping of plural words to singular words. This
is used when in pluralize mode, to look up user defined words.


=back

=head1 PROCESSING METHODS

=over 4

=item B<parse>(%hash)

This accepts an input hash containing the Object option, which points
to the input object to be processed.

The parse method will take an input object and generate SAX2 events for
a SAX2 pipeline, representing the object as an XML document.

=item B<parse_start>

This method starts the generator in stream mode.

=item B<parse_chunk>($object)

This accepts an object to be output as SAX2 event in stream mode.

=item B<parse_stop>

This method stops the generator in stream mode.

=back

=head1 LICENCE & AUTHOR

This module is released under the Perl Artistic Licence and
may be redistributed under the same terms as perl itself.

(c)2002-2004 Darren Graves (darren@iterx.org), All rights reserved.

=head1 SEE ALSO

XML::SAX2Object & XML::SAX.

=cut
