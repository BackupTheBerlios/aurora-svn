 package XML::SAX2Object::Builder;
use strict;

use XML::SAX2Object::Inflect qw/plural/;

sub new {
  my ($class, %options) = @_;
  return bless {
		SkipRoot     => ((defined $options{SkipRoot})?
				$options{SkipRoot} : 0),
		Namespace    => ((defined $options{Namespace})?
				$options{Namespace} : 0),
		NamespaceExpand => ((defined $options{NamespaceExpand})?
				    $options{NamespaceExpand} : 0),
		NamespaceMap => ((UNIVERSAL::isa
				  ($options{NamespaceMap},'HASH'))?
				 $options{NamespaceMap} : {}),
		NamespaceIgnore => ((defined $options{NamespaceIgnore})?
				    $options{NamespaceIgnore} : 0),
		Normalize    => ((defined $options{Normalize})?
				$options{Normalize} : 1),
		Pluralize    => ((defined $options{Pluralize})?
				$options{Pluralize} : 1),
		Dictionary   => ((UNIVERSAL::isa
				  ($options{Dictionary},'HASH'))?
				 $options{Dictionary} : {}),
		NodeStack    => [],
		ObjectStack  => [],
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

sub dictionary {
  my ($self);
  $self = shift;
  if(scalar @_ > 1) {
    my ($plural, $singular);
    while(($plural, $singular) = splice @_,0,2) {
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

sub start_document {
  my ($self, $document) = @_;
  $self->{NodeStack} = [];
  $self->{ObjectStack} = [{}];
}

sub start_element {
  my ($self, $element) = @_;
  my ($parent, $current);
  $parent = $self->{NodeStack}[-1];
  $current = $self->{ObjectStack}[-1];

 SWITCH: {
    (ref $current eq 'ARRAY') && do {
      my ($hash);
      $hash = {};
      map {
	my ($key);
	$key = $self->key($_);
	$hash->{$key} =
	  (($self->{Normalize})?
	   $self->normalize_space($_->{Value}) : $_->{Value} )
	    if $key && !(index $_->{Name},'xmlns') == 0;
      } values %{$element->{Attributes}};
      push @{$current}, $hash;
      $current = $current->[-1];
      last SWITCH;
    };
    ($self->{Pluralize} &&
     ref $current eq 'HASH' &&
     $parent->{LocalName} &&
     (($self->{Namespace})?
      (($parent->{NamespaceURI} || '') eq
       ($element->{NamespaceURI} || '')) : 1) &&
     (plural($element->{LocalName},
	     $self->{Dictionary}) eq $parent->{LocalName})) && do {
       my ($hash, $key);
       $hash = {};
       $key = $self->key($parent);
       last SWITCH unless defined $key;
       map {
	 my ($key);
	 $key = $self->key($_);
	 $hash->{$key} =
	   (($self->{Normalize})?
	    $self->normalize_space($_->{Value}) : $_->{Value} )
	     if $key && !(index $_->{Name},'xmlns') == 0;
       } values %{$element->{Attributes}};

       unless(UNIVERSAL::isa($current->{$key},'ARRAY')) {
	 $current = $self->{ObjectStack}[-1] = $self->{ObjectStack}[-2];
	 $current->{$key} = [];
       }
       push @{$current->{$key}}, $hash;
       $current = $current->{$key}->[-1];
       $element = $self->{NodeStack}[-1];
       last SWITCH;
     };
    (ref $current eq 'HASH' &&
     exists $current->{$element->{Name}}) && do {
       my ($hash, $key);
       $hash = {};
       $key = $self->key($element);
       last SWITCH unless defined $key;
       if($current->{$key} &&
	  !UNIVERSAL::isa($current->{$key},'ARRAY')){
	 my ($previous);
	 $previous = $current->{$key};
	 $current->{$key} = [$previous];
       }
       map {
	 my ($key);
	 $key = $self->key($_);
	 $hash->{$key} =
	   (($self->{Normalize})?
	    $self->normalize_space($_->{Value}) : $_->{Value} )
	     if defined $key && !(index $_->{Name},'xmlns') == 0;
       } values %{$element->{Attributes}};
       push @{ $current->{$key} }, $hash;
       $current =  $hash;
       last SWITCH;
     };
    (ref $current eq 'HASH') && do {
      my ($key);
      $key = $self->key($element);
      last SWITCH unless defined $key;
      $current->{$key} = {};
      $current = $current->{$key};
      map {
	my ($key);
	$key = $self->key($_);
	$current->{$key} =
	  (($self->{Normalize})?
	   $self->normalize_space($_->{Value}) : $_->{Value} )
	    if defined $key && !(index $_->{Name},'xmlns') == 0;
      } values %{$element->{Attributes}};
      last SWITCH;
    };
  };
  push @{ $self->{NodeStack} }, $element;
  push @{ $self->{ObjectStack} }, $current;
}

sub characters {
  my ($self, $characters) = @_;
  my ($data, $parent, $current, $name);
  return if $characters->{Data} =~ /^\s+$/;
  $data = (($self->{Normalize})?
	   $self->normalize_space($characters->{Data}) : $characters->{Data});
  $parent= $self->{NodeStack}[-1];
  $current = $self->{ObjectStack}[-2];
  $name = $self->key($parent);
  return unless defined $name;

  if (ref $current->{$name} eq "ARRAY") {
    $current->{$name}->[-1] =
      ((ref $current->{$name}->[-1])?
       $data :
       (join '', $current->{$name}->[-1], $data));
  }
  else {
    $current->{$name} =
      ((ref $current->{$name} eq "HASH")?
       $data :
       (join '', $current->{$name}, $data));
  }
}

sub end_element {
  my ($self, $element) = @_;
  pop @{ $self->{ObjectStack} };
  pop @{ $self->{NodeStack} };
}

sub comment {}

sub processing_instruction {}

sub end_document {
  my ($self, $document) = @_;
  my ($object);
  $object = pop @{ $self->{ObjectStack} };
  delete $self->{ObjectStack};
  delete $self->{NodeStack};

  return (($self->{SkipRoot} && UNIVERSAL::isa($object, 'HASH'))?
	  pop @{[values %{$object}]} : $object);
}

sub key {
  my ($self, $element) = @_;


 SWITCH: {
    my ($prefix);
    (!$self->{Namespace}) && do {
      return $element->{LocalName};
    };
    ($self->{NamespaceIgnore} &&
     defined $element->{NamespaceURI} &&
     !exists $self->{NamespaceMap}->{$element->{NamespaceURI}}) && do{

       #use Data::Dumper;
       #print STDERR Dumper($self->{NamespaceMap});
       #print STDERR Dumper($element);
       return undef;
    };
    ($self->{NamespaceExpand} &&
     defined $element->{NamespaceURI}) && do {
      return (join '',
	      '{',($element->{NamespaceURI} || ''),  '}',
	      $element->{LocalName});
    };
    (defined $element->{NamespaceURI} &&
     ($prefix = $self->{NamespaceMap}->{$element->{NamespaceURI}})) && do {
       return (($prefix eq '#default')?
	       $element->{LocalName} :
		(join ':',
		 $self->{NamespaceMap}->{$element->{NamespaceURI}},
		 $element->{LocalName}));
     };
  }
  return $element->{Name};
}


sub normalize_space {
  my ($self, $str) = @_;
  $str = (join '', ' ', $str, ' ');
  $str =~ s/(\s+)/ /g;
  return (substr $str, 1, (length $str) - 2);
}


1;
__END__
=pod

=head1 NAME

XML::SAX2::Builder - A SAX2 Builder, that takes a SAX2 events and
builds a Perl datastructure.

=head1 SYNOPSIS

  use XML::SAX::ParserFactory;
  use XML::SAX2Object::Builder;

  $handler = XML::SAX2Object::Builder->new;
  $parser =  XML::SAX::ParserFactory->parser(Handler => $handler);

  $object = $parser->parse_file($filename);


=head1 DESCRIPTION

XML::SAX2::Builder is SAX2 Builder, that takes a SAX2 events and
builds a Perl datastructure

It should be noted that the mapping between XML and Perl datastructure
is lossy, with data that doesn't fall under the mapping scheme being
discarded. Therefore ,this builder should only be used in situations
where you have control over the XML structure, or it has been checked by
hand that no valuable data is lost in the building process.

=head1 CONSTRUCTOR

=over 1

=item B<new>(%hash)

Construct a new XML::SAX2Object::Builder instance. It takes a number of
optional parameters that controls its behaviour.

- SkipRoot

- Namespace

- NamespaceExpand

- NamespaceIgnore

- NamespaceMap

- Normalize

- Pluralize

Their behaviour is covered in the description of the applicable accessor
method for each of the option.

=back


=head1 ACCESSOR METHODS

=over 8

=item * B<skiproot>(bool) ]

Skip processing the root node of the document. When enabled, the builder
will ignore the root document node of the incomming XML file.

By default this is disabled.

=item * B<namespace>(bool)

Enable namespace support. This will result in the namespace prefix
information being retained. The exact behaviour exhibited, is alterable
by the NamespaceExpand and NamespaceMap options.

By default this is disabled.

=item * B<nsexpand>(bool)

In conjuction with namespace support enabled, will result in the element
prefix being expanded to display the full namespace URI.

By default this is disabled.

=item * B<nsignore>(bool)

In conjuction with namespace support enabled, will result in all elements
that have not been declared by the namespace map being ignored.

By default this is disabled.

=item * B<nsmap>(%hash)

This sets up the namespace mapping of prefixes to namespace URIs to be
used when processing the data.

=item * B<normalize>(bool)

When enabled, all whitespace read will be normalized.

By default this is enabled.

=item * B<pluralize>(bool)

When enabled, this will automatically cause inflected names to be
represented as arrays. Currently, only the English language is
partially supported natively.

By default this is enabled.

=item * B<dictionary>(%hash)

This sets up a default mapping of plural words to singular words. This
is used when in pluralize mode, to look up user defined words.


=back

=head1 LICENCE & AUTHOR

This module is released under the Perl Artistic Licence and
may be redistributed under the same terms as perl itself.

(c)2002-2004 Darren Graves (darren@iterx.org), All rights reserved.

=head1 SEE ALSO

XML::SAX2Object & XML::SAX.

=cut


