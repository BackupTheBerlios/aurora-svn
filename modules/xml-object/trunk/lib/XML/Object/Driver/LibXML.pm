package XML::Object::Driver::LibXML;
use strict;

use Fcntl;

use XML::LibXML;
use XML::LibXML::SAX::Parser;

use XML::Object;
use XML::Object::XPath;

XML::Object::DriverFactory->register
  ('XML::LibXML::Node' => __PACKAGE__);

use constant NS_XML   => 'http://www.w3.org/XML/1998/namespace';
use constant NS_XMLNS => 'http://www.w3.org/2000/xmlns/';

sub new {
  my ($class) = @_;
  return bless {
		_namespaces => {
				&NS_XML   => 'xml',
				&NS_XMLNS => 'xmlns',
			       },
		_parser => XML::LibXML->new,
	       }, $class;
}

sub parse {
  my ($self, $source) = @_;
  my ($document);
 SWITCH:{
    (ref $source) && do {
      $document =
	$self->{_parser}->parse_string(${$source});
      last SWITCH;
    };
    (defined $source) && do {
    PROTO: {
	$source =~ s/^file:\/\/// || $source !~ /^\w+:\/\// && do {
	  my (@stat);
	  @stat = stat($source);
	  if(scalar @stat) {
	    my ($xml);
	    sysopen(FILE, $source,
		    O_RDONLY|O_BINARY) ||
		      die "Error reading file : $!\n";
	    sysread(FILE, $xml, $stat[7]);
	    close FILE;
	    $document = $self->{_parser}->parse_string($xml);
	    last PROTO;
	  }
	  die "File $source not found!\n";
	};
	do {
	  die "Protocol not supported for $source\n";
	};
      };
      last SWITCH;
    };
    do {
      $document = XML::LibXML::Document->new;
    };
  };
  return $document;
}

sub namespace {
  my($self, $object, $dom, $element);
  $self = shift;
  $object = shift;
  $dom = $object->as_dom;
  $element = (($dom->getType == XML_DOCUMENT_NODE)?
	      $dom->documentElement : $dom);

  if(scalar @_ == 1) {
    return (($element)?
	    $element->lookupNamespacePrefix($_[0]) :
	    (($self->{_namespaces})?
	     $self->{_namespaces}->{$_[0]} : undef));
  }
  else {
    my ($ok, $ns, $prefix);
    $ok = 0;
    while(($ns, $prefix) = (splice @_, 0, 2)) {
      if($element && $element->lookupNamespaceURI($prefix)) {
	warn "Namespace prefix '$prefix' already exists\n";
      }
      else {
	(($element)?
	 $element->setNamespace($ns, $prefix, 0) :
	 ($self->{_namespaces}->{$ns} = $prefix));
	$ok++;
      }
    }
    return $ok;
  }
}


sub fetch {
  my ($self, $object, $key, $as_object) = @_;
  my ($dom, $nodeset, @values);
  $dom = $object->as_dom;
  $nodeset =
    (($dom->getType != XML_DOCUMENT_NODE)?
     $dom->find(((index $key, '//') == 0)? $key : "../$key") :
     (defined $dom->documentElement)? $dom->find($key) : ());

  if(UNIVERSAL::isa($nodeset,'ARRAY')) {
    @values = map {
      my ($type, $value);

      $type = $_->getType;
    SWITCH: {
	($type == XML_ATTRIBUTE_NODE) && do {
	  $value = $_->getValue;
	  last SWITCH;
	};
	($type == XML_TEXT_NODE ||
	 $type == XML_CDATA_SECTION_NODE) && do {
	   $value = $_->nodeValue;
	   last SWITCH;
	 };
	$as_object && do {
	  my ($document, $class);
	  $class = (UNIVERSAL::isa($as_object,'XML::Object'))? $as_object : (ref $object);
	  $document = XML::LibXML::Document->new;
	  $document->setDocumentElement($_->cloneNode(1));
	  $value = $class->new
	    ((map {(index($_,'_') == 0)? () : ($_ => $object->{$_}) } keys %{$object}),
	     (Input => $document));
	  last SWITCH;
	};
	($type == XML_ELEMENT_NODE) && do {
	  $value = (join ' ', map { ($_->nodeValue || ()) } $_->getChildnodes())
	    if $_->hasChildNodes();
	  last SWITCH;
	};
	do {
	  warn "Invalid node type $type\n";
	};
      };
      $value;
    } @{$nodeset};
  }
  else {
    push @values, $nodeset->value if $nodeset;
  }

  return ((wantarray)? @values :
	  ((scalar @values) < 2)? $values[0] : \@values);
}

sub exists {
  my ($self, $object, $key) = @_;
  my ($dom, $nodeset);
  $dom = $object->as_dom;
  $nodeset =
    (($dom->getType != XML_DOCUMENT_NODE)?
     $dom->find(((index $key, '//') == 0)? $key : "../$key") :
     (defined $dom->documentElement)? $dom->find($key) : ());
  $nodeset ||= [];
  return scalar @{$nodeset};
}

sub store {
  my ($self, $object, $key, $value) = @_;
  my ($dom, $nodeset);
  $dom = $object->as_dom;
  eval {
    $nodeset =
      (($dom->getType != XML_DOCUMENT_NODE)?
       $dom->find(((index $key, '//') == 0)? $key : "../$key") :
       (defined $dom->documentElement)? $dom->find($key) : ());
  };
  $nodeset ||= [];

  if(scalar @{$nodeset}) {
    foreach my $node (@{$nodeset}) {
      my ($type, $new);
      $type = $node->getType;

    SWITCH:{
	($type == XML_DOCUMENT_NODE) && do {
	  $new = ((UNIVERSAL::isa($value, 'XML::Object'))?
		  $value->as_dom->documentElement :
		  (die "Invalid value supplied, it must fragment"));
	  $node->setDocumentElement($new);
	  last SWITCH;
	};
	($type == XML_ATTRIBUTE_NODE) && do {
	  $node->setValue($value);
	  last SWITCH;
	};
	($type == XML_TEXT_NODE ||
	 $type == XML_CDATA_SECTION_NODE) && do {
	   $new = ((UNIVERSAL::isa($value, 'XML::Object'))?
		   $value->as_dom->documentElement :
		   XML::LibXML::Text->new($value));
	   $node->getParentNode->replaceChild($new, $node);
	   last SWITCH;
	 };
	$node->hasChildNodes && do {
	  my ($type);
	  map {
	    $type = $_->getType;
	    $node->removeChild($_)
	      if $type == XML_TEXT_NODE ||
		$type == XML_CDATA_SECTION_NODE;
	  } $node->getChildnodes;
	};
	do {
	  $new = ((UNIVERSAL::isa($value, 'XML::Object'))?
		  $value->as_dom->documentElement :
		  XML::LibXML::Text->new($value));
	  $node->appendChild($new);
	  last SWITCH;
	};
      };
    }
  }
  else {
    my ($xpath, $node, $type, $new);
    $new = ((UNIVERSAL::isa($value, 'XML::Object'))?
	    $value->as_dom->documentElement :
	    $value);

    if($key &&
       ($xpath = XML::Object::XPath->compile($self => $key))) {
      $xpath->value($new);
      $xpath->build($dom);
    }
    else {
      ($dom->getType == XML_DOCUMENT_NODE)?
	$dom->setDocumentElement($new) :
	  $dom->replaceNode($new);
    }
  }
  return 1;
}


sub delete {
  my ($self, $object, $key, $as_object) = @_;
  my ($dom, $nodeset, @values);
  $dom = $object->as_dom;
  eval {
    $nodeset =
      (($dom->getType != XML_DOCUMENT_NODE)?
       $dom->find(((index $key, '//') == 0)? $key : "../$key") :
       (defined $dom->documentElement)? $dom->find($key) : ());
  };
  $nodeset ||= [];

  if($as_object) {
    my ($class);
    $class = (UNIVERSAL::isa($as_object,'XML::Object'))? $as_object : (ref $object);
    @values = map {
      my ($document);
      $document = XML::LibXML::Document->new;
      $document->setDocumentElement($_->cloneNode(1));
      $class->new
	((map {((index $_, '_') == 0)? () : ($_ => $object->{$_}) } keys %{$object}),
	 (Input => $document));
    } @{$nodeset};
  }
  else {
    @values = $self->fetch($object, $key);
  }
    map { $_->unbindNode } @{$nodeset};
  return ((wantarray)? @values :
	  ((scalar @values) < 2)? $values[0] : \@values);
}

sub clone {
  my ($self, $dom) = @_;
  my ($clone);
  if($dom) {
    my ($node);
    $node = ($dom->getType == XML_DOCUMENT_NODE)? $dom->documentElement : $dom;
    if($node) {
      $clone = XML::LibXML::Document->new;
      $clone->setDocumentElement($node->cloneNode(1));
    }
  }
  return $clone;
}

sub as_string {
  my ($self, $dom) = @_;
  return ($dom)? $dom->toString : undef;
}

sub as_sax {
  my ($self, $dom);
  $self = shift;
  $dom = shift;
  if($dom) {
    my ($parser);
    $parser = XML::LibXML::SAX::Parser->new(@_);
    return $parser->generate($dom);
  }
  return undef;
}

sub serialize {
  my ($self, $object) = @_;
  my (%values, @nodes, $dom);
  $dom = $object->as_dom;
  push @nodes,
    (($dom->getType == XML_DOCUMENT_NODE)?
     [$dom->documentElement,
      (join '','/',(($dom->documentElement)?
		    $dom->documentElement->getName : ''))]:
     [$dom, (join '', '/', $dom->getName)]);

  while(my $next = pop @nodes) {
    my ($node, $path);
    ($node, $path) = @{$next};
    next unless $node;

    map {
      my ($name);
      $name = $_->getName;
      $name = (join ':', 'xmlns', ($name || ())) if
	  UNIVERSAL::isa($_, 'XML::LibXML::Namespace');
      $values{(join '', $path, '/@', $name)} = $_->value;
    } $node->getAttributes;

    if ($node->hasChildNodes) {
      my (%names, %nodes);
      map {
	if ($_->getType ==  XML_ELEMENT_NODE) {
	  my ($name);
	  $name = (join '/',$path, $_->getName);
	  $nodes{(join '', $name, '[1]')} = delete $nodes{$name}
	    if $names{$name}++ == 1;
	  $name = (join '',$name, '[', $names{$name}, ']') if $names{$name} > 1;
	  $nodes{$name} = $_;
	}
	else {
	  $values{$path} = (join '',
			    (($values{$path})? ($values{$path}, ' ') : ()),
			    $_->nodeValue);
	}
      } $node->getChildnodes;
      while (my ($path, $node) = each %nodes) {
	push @nodes, [$node, $path];
      }
    }
  }
  return %values;
}

sub function {
  my ($self, $function, $args) = @_;
  my ($class, $name);
  $name = $function;
  $name =~ s/-/_/;
  $class = (join '::', __PACKAGE__, 'Function', $name);
  if(my $code = $class->can('new')) {
    return $code->($class, $name, $args);
  }
  die "Unsupported XPath function $function()\n";
}

sub document {
  my ($self);
  $self = shift;
  return XML::Object::Driver::LibXML::Document->new(@_);
}

sub element {
  my ($self, $name, $predicates) = @_;
  my ($index, $namespace);
  if($self->{_namespaces} &&
     ($index = (index $name, ':'))) {
    my ($prefix);
    $prefix = (substr($name, 0, $index));
    foreach my $ns (keys %{$self->{_namespaces}}) {
      if($self->{_namespaces}->{$ns} eq $prefix) {
	$namespace = $ns;
	last;
      }
    }
  }
  return XML::Object::Driver::LibXML::Element->new
    ($name, $namespace, $predicates);
}

sub attribute {
  my ($self, $name, $predicates) = @_;
  my ($index, $namespace);
  if($self->{_namespaces} &&
     ($index = (index $name, ':'))) {
    my ($prefix);
    $prefix = (substr($name, 0, $index));
    foreach my $ns (keys %{$self->{_namespaces}}) {
      if($self->{_namespaces}->{$ns} eq $prefix) {
	$namespace = $ns;
	last;
      }
    }
  }
  return XML::Object::Driver::LibXML::Attribute->new
    ($name, $namespace, $predicates);
}

package XML::Object::Driver::LibXML::Function;
use XML::Object::XPath;
@XML::Object::Driver::LibXML::Function::ISA =
  qw/XML::Object::XPath::Function/;

sub new {
  my ($class, $name, $args) = @_;
  my ($self, $func);
  $self = bless {
		 name       => $name,
		 args       => $args,
		 value      => undef,
		}, $class;
  return $self;
}

sub do {
  die "Abstract class\n";
}

sub value {
  my ($self, $value) = @_;
  return $self->{value} = $value;
}

package XML::Object::Driver::LibXML::Function::position;
@XML::Object::Driver::LibXML::Function::position::ISA =
  qw/XML::Object::Driver::LibXML::Function/;

sub do {
  my ($self, $xpath, $node) = @_;
  $xpath->{predicate}->{position} = $self->{value};
  return;
}

package XML::Object::Driver::LibXML::Function::last;
@XML::Object::Driver::LibXML::Function::last::ISA =
  qw/XML::Object::Driver::LibXML::Function/;

sub do {
  my ($self, $xpath, $node) = @_;
  $xpath->{predicate}->{position} = 0;
  $xpath->{predicate}->{max} = $self->{value}
    if defined $self->{value};
  return;
}


package XML::Object::Driver::LibXML::Function::local_name;
@XML::Object::Driver::LibXML::Function::local_name::ISA =
  qw/XML::Object::Driver::LibXML::Function/;

sub do {
  my ($self, $xpath, $node) = @_;
  $xpath->{local} = $self->{value};
  $xpath->{name} = (($self->{prefix})?
		    (join ':', $self->{prefix}, $self->{value}) :
		    $self->{value});
  return;
}

package XML::Object::Driver::LibXML::Function::name;
@XML::Object::Driver::LibXML::Function::name::ISA =
  qw/XML::Object::Driver::LibXML::Function/;

sub do {
  my ($self, $xpath, $node) = @_;
  my ($prefix, $local);
  ((index $self->{value}, ':') != -1)?
    (($prefix, $local) = split /\:/, $self->{value}) :
      ($local = $self->{value});
  $xpath->{name} = $self->{value};
  $xpath->{prefix} = $prefix;
  $xpath->{local} = $local;
  return;
}

package XML::Object::Driver::LibXML::Function::namespace_uri;
@XML::Object::Driver::LibXML::Function::namespace_uri::ISA =
  qw/XML::Object::Driver::LibXML::Function/;

sub do {
  my ($self, $xpath, $node) = @_;
  $xpath->{namespace} = $self->{value};
  return;
}


package XML::Object::Driver::LibXML::Node;
use XML::Object::XPath;
@XML::Object::Driver::LibXML::Node::ISA =
  qw/XML::Object::XPath::Node/;

sub new {
  my ($class, $name, $namespace) = @_;
  my ($self, $local, $prefix);
  ((index $name, ':') != -1)?
    (($prefix, $local) = split /\:/, $name) :
      ($local = $name);

  $self = bless {
		 name       => $name,
		 local      => $local,
		 prefix     => $prefix,
		 namespace  => ($namespace || undef),
		 value      => undef,
		 next       => undef
		}, $class;
  return $self;
}

sub value {
  my ($self, $value) = @_;
  my (@nodes, $current);
  push @nodes, $self;
  while(my $node = shift @nodes) {
    ((defined $node->{next})?
     (push @nodes, $node->{next}) :
     do { $current = $node; last; });
  }
  return $current->{value} = $value;
}

sub chain {
  my ($self, $node) = @_;
  ($self->{next})? $self->{next}->chain($node) : ($self->{next} = $node);
  return $self;
}

sub unchain {
  my ($self, $node) = @_;
  ($self->{next} && $self->{next}->{next})?
    $self->{next}->unchain($node) :  ($self->{next} = undef);
  return $self;
}

sub find {
  die "Abstract Class";
}

sub build {
  die "Abstract Class";
}

package XML::Object::Driver::LibXML::Element;
use XML::LibXML;
@XML::Object::Driver::LibXML::Element::ISA =
  qw/XML::Object::Driver::LibXML::Node/;


sub new {
  my ($class, $name, $namespace, $predicates) = @_;
  my ($self);
  $self = $class->SUPER::new($name, $namespace);
  $self->{predicate} = undef;

  if(ref $predicates eq 'ARRAY') {
    foreach my $predicate (@{$predicates}) {
    SWITCH: {
	(UNIVERSAL::isa($predicate, 'XML::Object::XPath::Node')) && do {
	  push @{$self->{predicate}->{test}}, $predicate;
	  last SWITCH;
	};
	(UNIVERSAL::isa($predicate, 'XML::Object::XPath::Function')) && do {
	  push @{$self->{predicate}->{function}}, $predicate;
	  last SWITCH;
	};
	(!ref $predicate) && do {
	  $self->{predicate}->{position} = $predicate;
	  last SWITCH;
	};
      };
    }
  }

  return $self;
}


sub find {
  my ($self, $node) = @_;
  my (@elements, $type, $dom);
  $type = $node->getType;

  if($self->{predicate} && $self->{predicate}->{function}) {
    map {
      $_->do($self, $node);
    } @{$self->{predicate}->{function}};
  }
  die "XPath element has no name" unless $self->{name};
 SWITCH: {
    ($type == XML_DOCUMENT_NODE) && do {
      $dom = $node;
      $node = $node->getDocumentElement;
      if($node && $node->getName eq $self->{name}) {
	@elements = ($node);
      }
      last SWITCH;
    };
    do {
      my ($ns);
      $dom = $node->getOwnerDocument;
      die "XPath node has no name" unless $self->{name};
      (@elements) = do {
	$ns = (($self->{namespace})?
	       $self->{namespace} :
	       (($self->{prefix})?
		$node->lookupNamespaceURI($self->{prefix}) :
		undef));
	(($ns)? $node->getElementsByTagNameNS($ns, $self->{local}) :
	 $node->getElementsByTagName($self->{name}));
      };

      last SWITCH;
    };
  };

  if(scalar @elements && $self->{predicate}) {
    my ($element, $position);

    if($self->{predicate}->{test}) {
      @elements = grep {
	my ($node);
	$node = $_;
	(grep { $_->find($node)? 0 : 1 }
	 @{$self->{predicate}->{test}})?  0 : 1;
      } @elements;
    }
    die "More elements exist than specified by the last() predicate"
      if $self->{predicate}->{max} &&
	scalar @elements > $self->{predicate}->{max};

    $element = ((defined $self->{predicate}->{position})?
		$elements[($self->{predicate}->{position} - 1)] :
		$elements[0]);
    return $element;
  }
  return $elements[0];
}

sub build {
  my ($self, $node) = @_;
  my ($dom, $element, $type);
  $type = $node->getType;
  $dom = (($type == XML_DOCUMENT_NODE)?
	  $node : $node->getOwnerDocument);

  unless($element = $self->find($node)) {
    while(!defined $element) {
      my ($new, $ns);
      $new = do {
	$ns = (($self->{namespace})?
	       $self->{namespace} :
	       (($self->{prefix})?
		$node->lookupNamespaceURI($self->{prefix}) :
		undef));
	(($ns)? $dom->createElementNS($ns, $self->{name}) :
	 $dom->createElement($self->{name}))
      };

      (($type == XML_DOCUMENT_NODE)?
       $dom->setDocumentElement($new) : $node->appendChild($new));

      if($self->{predicate}->{test}) {
	map { $_->build($new) }  @{$self->{predicate}->{test}};
      }
      $element = $self->find($node);
    }
  }
  if($element && $self->{value}) {
    my ($new);
    $new = ((UNIVERSAL::isa($self->{value},'XML::LibXML::Node'))?
	    $self->{value} :
	    $dom->createTextNode($self->{value}));
    $element->appendChild($new);
  }
  return (($self->{next})? $self->{next}->build($element) : $element);
}

package XML::Object::Driver::LibXML::Attribute;
use XML::LibXML;
@XML::Object::Driver::LibXML::Attribute::ISA =
  qw/XML::Object::Driver::LibXML::Node/;

sub new {
  my ($class, $name, $namespace, $predicates) = @_;
  my ($self);
  $self = $class->SUPER::new($name, $namespace);
  $self->{predicate} = undef;

  if(ref $predicates eq 'ARRAY') {
    foreach my $predicate (@{$predicates}) {
    SWITCH: {
	(UNIVERSAL::isa($predicate, 'XML::Object::XPath::Node')) && do {
	  push @{$self->{predicate}->{test}}, $predicate;
	  last SWITCH;
	};
	(UNIVERSAL::isa($predicate, 'XML::Object::XPath::Function')) && do {
	  push @{$self->{predicate}->{function}}, $predicate;
	  last SWITCH;
	};
      };
    }
  }
  return $self;
}


sub find {
  my ($self, $node) = @_;
  my ($dom, $attribute, $ns);
  $dom = $node->getOwnerDocument;

  if($self->{predicate} && $self->{predicate}->{function}) {
    map {
      $_->do($self, $node);
    } @{$self->{predicate}->{function}};
  }
  die "XPath attribute has no name" unless $self->{name};
  $attribute = do {
    $ns = (($self->{namespace})?
	   $self->{namespace} :
	   (($self->{prefix})?
	    $node->lookupNamespaceURI($self->{prefix}) :
	    undef));
    (($ns)? $node->getAttributeNodeNS($ns, $self->{local}) :
     $node->getAttributeNode($self->{name}))
  };
  return (($attribute && defined $self->{value})?
	  (($attribute->getValue eq $self->{value})? $attribute : undef) :
	  $attribute);
}

sub build {
  my ($self, $node) = @_;
  my ($attribute);
  unless($attribute = $self->find($node)) {
    my ($dom, $ns);
    $dom = $node->getOwnerDocument;
    if($self->{name} =~ /^xmlns:?(\w+)?$/) {
      $node->setNamespace($self->{value}, $1, 0);
    }
    else {
      $attribute = do {
	$ns = (($self->{namespace})?
	       $self->{namespace} :
	       (($self->{prefix})?
		$node->lookupNamespaceURI($self->{prefix}) :
		undef));
	(($ns)? $dom->createAttributeNS($ns, $self->{name}) :
	 $dom->createAttribute($self->{name}));
      };
      $attribute->setValue($self->{value}) if defined $self->{value};
      $node->setAttributeNode($attribute);
    }
  }
  return $attribute;
}


package XML::Object::Driver::LibXML::Document;
use XML::LibXML;
@XML::Object::Driver::LibXML::Document::ISA =
  qw/XML::Object::Driver::LibXML::Node/;

sub build {
  my ($self, $node) = @_;
  return ($self->{next})? $self->{next}->build($node) : $node;
}


1;
