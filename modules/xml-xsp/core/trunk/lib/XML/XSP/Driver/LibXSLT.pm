package XML::XSP::Driver::LibXSLT;
use strict;

use FileHandle;
use XML::LibXML;
use XML::LibXSLT;

use XML::XSP::Driver;

use vars qw/@ISA $NS $VERSION/;
@ISA = qw/XML::XSP::Driver/;

$NS = 'http://apache.org/xsp/core/v1';
$VERSION = '0.4.2';

sub new {
  my ($class, %options) = @_;
  my ($self, $parser, $processor);
  $self = $class->SUPER::new(%options);

  $parser =  XML::LibXML->new;
  $parser->callbacks(\&_match_handler,
		     \&_open_handler,
		     \&_read_handler,
		     \&_close_handler);

  $processor = XML::LibXSLT->new;

  $self->{parser} = $parser;
  $self->{processor} = $processor;
  return $self;
}

sub document {
  my ($self, $source, $options) = @_;
  my ($document);
 SWITCH: {
    (!ref $source) && do {
      $document = $self->{parser}->parse_file($source);
      last SWITCH;
    };
    (UNIVERSAL::isa($source,'IO::Handle')) && do {
      $document = $self->{parser}->parse_fh($source);
      last SWITCH;
    };
    (UNIVERSAL::isa($source,'XML::LibXML::Node')) && do {
      $document = ($options->{Clone})?
	$self->{parser}->parse_string($source->toString):
	  $source;
      last SWITCH;
    };
    do {
      $document = $self->{parser}->parse_string($$source);
      last SWITCH;
    };
  };
  return $document;
}

sub stylesheet {
  my ($self, $source, $options) = @_;
  my ($stylesheet);
  if($stylesheet = $self->document($source, $options)) {
    $stylesheet = $self->{processor}->parse_stylesheet($stylesheet);
  }
  return $stylesheet;
}


sub compile {
  my ($self, $class, $node, $fragments, $offset, $count) = @_;
  my ($code, @fragments, $position, $max);


  @fragments = (defined $fragments)? @{$fragments} :
    $node->findnodes
      ("descendant::node()[namespace-uri() = '$NS']");

  $position = $offset || 0;
  $max = ($count)? ($offset + $count) :  (1+$#fragments);
  $code = '';

  while($position < $max) {
    my ($fragment, $children, $type);
    $fragment = $fragments[$position];
    $children = $fragment->findvalue
      ("count(descendant::node()[namespace-uri() = '$NS'])");
    $type = $fragment->getLocalName;
    $code .= (join '',"\n",
	      '#######################', "\n",
	      '## fragment ', $position, " ", $type ,"\n",
	      '## max ',$max,' children ', $children, "\n"
	     );
  SWITCH:{

      # should add support for:
      # xsp:page, xsp:include, xsp:structure, xsp:content, xsp:comment, xsp:pi
      # need to fix xsp:logic for a couple of pathological cases

      $type eq "page" && do {
	my ($parent, $type);
	$parent = $fragment->getParentNode;
	$type = $parent->getType;
	$code .= (join '',
		  '{',"\n",
		  'my ($current, $parent);',"\n",
		  '$current = $__fragments[',($position),'];',"\n",
		  '$parent = $current->getParentNode;',"\n");
	if($children) {
	  $code .= $self->compile($class, $fragment, \@fragments,
				  ($position+1), $children);
	  $position = $position + $children;
	}
	$code .= (join '',
		  '$parent->removeChild($current);',"\n",
		  'map { ',
		  (($type == XML_DOCUMENT_NODE)?
		   '$parent->setDocumentElement($_) if UNIVERSAL::isa($_,\'XML::LibXML::Element\');' :
		   '$parent->appendChild($_);'),
		  '} $current->getChildNodes;',"\n",
		  '}',"\n",
		 );
	last SWITCH;
      };
      $type =~/(text|comment|pi)/ && do {
	$code .= (join '',
		  '{',"\n",
		  'my ($current, $parent, $value);',"\n",
		  '$current = $__fragments[',($position),'];',"\n",
		  '$parent = $current->getParentNode;',"\n",
		  'unshift @__stack, undef;',"\n"
		 );

	if($children) {
	  $code .= $self->compile($class, $fragment, \@fragments,
				  (1 + $position), $children);
	  $position = $position + $children;
	}
	$code .= (join '',
		  'shift @__stack;',"\n",
		  'if(defined $__stack[0]) {',"\n",
		  'while(my $node = shift @__stack) {',"\n",
		  '$value .= $node->toString;',"\n",
		  '}',"\n",
		  '}',"\n",
      		  'else {',"\n",
		  '$value = (join "", map {',"\n",
		  '(($_->namespaceURI || \'\')  ne \'',$NS,'\')? $_->toString : "";',"\n",
		  '} $current->getChildnodes);',"\n",
		  '}',"\n",
		  'if(defined $value) {',
		  (($type eq 'text')?
		   '$parent->insertAfter($document->createTextNode($value),$current);' :
		   ($type eq 'comment')?
		   '$parent->insertAfter($document->createComment($value),$current);' :
		   ($type eq 'pi' && $fragment->getAttribute('target'))?
		   do {
		     (
		      '$value =~ s/(&quot;|&#34;)/\"/g;',"\n",
		      'my $pi = $document->createProcessingInstruction("',
		      $fragment->getAttribute('target'),'",$value);',"\n",
		      '$parent->insertAfter($pi, $current);',"\n"
		     )}: ()),
		  '}',"\n",
		  '}',"\n"
		 );
	last SWITCH;
      };
      $type eq "attribute" && do {
	my ($parent, $name, $namespace, $prefix);
	# Add preserve space option
	# Fix for nested xsp tags..

	$parent = $fragment->getParentNode;
	$namespace = $fragment->getAttribute('namespace');
	$namespace =~ s/'/\\'/g if $namespace;
	$prefix = $fragment->getAttribute('prefix') || 'ns';
	$name = ($namespace)? (join ':', $prefix, $fragment->getAttribute('name')):
 	  $fragment->getAttribute('name');
	$name =~ s/'/\\'/g;

	$code .= (join '',
		  '{',"\n",
		  'my ($current, $parent, $value);',"\n",
		  '$current = $__fragments[',($position),'];',"\n",
		  '$parent = $current->getParentNode;',"\n",
		  'unshift @__stack, undef;',"\n"
		 );

	if($children) {
	  $code .= $self->compile($class, $fragment, \@fragments,
				  (1 + $position), $children);
	  $position = $position + $children;
	}
	$code .= (join '',
		  'shift @__stack;',"\n",
		  'if(defined $__stack[0]) {',"\n",
		  'while(my $node = shift @__stack) {',"\n",
		  '$value .= $node->toString;',"\n",
		  '}',"\n",
		  '}',"\n",
      		  'else {',"\n",
		  '$value = (join "", map {',"\n",
		  '(($_->namespaceURI || \'\') ne \'',$NS,'\')? $_->toString : "";',"\n",
		  '} $current->getChildnodes);',"\n",
		  '}',"\n",
		  ((($parent->namespaceURI || '') eq $NS &&
		    $parent->localName =~ /^expr|logic|page$/)?
		   '$parent = $parent->getParentNode;' :
		   '' ),"\n",
		  ((defined $namespace)?
		   ('$parent->setAttributeNS(\'',$namespace,'\',\'',$name,'\',$value)'):
		   ('$parent->setAttribute(\'',$name,'\',$value)')
		  ),' if defined $value;',"\n",
		  '}',"\n"
		 );
	last SWITCH;
      };

      $type eq "element" && do {
	my ($parent, $namespace, $name, $prefix);

	$parent = $fragment->getParentNode;
	$namespace = $fragment->getAttribute('namespace');
	$namespace =~ s/'/\\'/g if $namespace;
	$prefix = $fragment->getAttribute('prefix') || 'ns';
	$name = ($namespace)? (join ':', $prefix, $fragment->getAttribute('name')):
 	  $fragment->getAttribute('name');
	$name =~ s/'/\\'/g;


	$code .= (join '',
		  '{',"\n",
		  'my ($current, $parent, $element);',"\n",
		  '$current = $__fragments[',($position),'];',"\n",
		  '$parent = $current->getParentNode;',"\n",
		  ((defined $namespace)?
		   ('$element = $document->createElementNS(\'',$namespace,'\',\'',$name,'\');') :
		   ('$element = $document->createElement(\'',$name,'\');')
		  ),"\n",
		  ((($parent->namespaceURI || '') eq $NS &&
		    $parent->localName =~ /^logic|expr$/)?
		   'push @__stack, $element;' :
		   '$parent->insertAfter($element, $current);' ),"\n",
		  'map {',"\n",
		  '$element->appendChild($_->cloneNode(1));',"\n",
		  '} $current->getChildnodes;', "\n",
		 );

	if($children) {
	  $code .= (join '',
		    '{',"\n",
		    'my ($count);',"\n",
		    '$count = 1;',"\n",
		    'foreach my $fragment ($element->findnodes',"\n",
		    '("descendant::node()[namespace-uri() = \'',$NS,'\']")) {',"\n",
		    'push @__fragments, $__fragments[(',($position),'+ $count)];',"\n",
		    '$__fragments[(',($position),'+ $count)] = $fragment;',"\n",
		    '$count++;',"\n",
		    '}',"\n",
		    'unshift @__stack, undef;',"\n"
		  );

	  $code .= $self->compile($class, $fragment, \@fragments,
				  ($position + 1), $children);

	  $code .= (join '',
		    'shift @__stack;',"\n",
		    '};',"\n",
		    'if(defined $__stack[0]) {',"\n",
		    'while(my $node = shift @__stack) {',"\n",
		    #unless($p->isEqual($parent)) { to reduce tree shifting?
		    '$element->appendChild($node);',"\n",
		    '}',"\n",
		    '}',"\n",
		 );
	  $position = $position + $children;
	}

	$code .= (join '', '}',"\n");
	last SWITCH;
      };
      $type eq "logic" && do {
	# Add preserve space option
	my (@children, $count, $element);
	@children = $fragment->getChildnodes;
	$count = 0;
        $code .= (join '',
		  '{',"\n",
		  'my ($current, $parent);',"\n",
		  '$current = $__fragments[',($position),'];',"\n",
		  '$parent = $current->getParentNode;',"\n",
		  'unshift @__stack, undef;',"\n",
		  '{',"\n"
		 );

	while ($count <= $#children) {
	  my ($type, $child);

	  $child = $children[$count];
	  $type = $child->getType;
	SWITCH: {
	    ($type == XML_TEXT_NODE || $type == XML_CDATA_SECTION_NODE) && do {
	      $code .= $child->getData;
	      last SWITCH;
	    };
  	    ($type == XML_ELEMENT_NODE && ($child->namespaceURI || '') eq $NS) && do {
	       my ($children);
	       $children = $child->findvalue
		 ("count(descendant-or-self::node()[namespace-uri() = '$NS'])");
	       $code .= $self->compile($class, $fragment, \@fragments,
				       ($position + 1), $children);
	       $position = $position + $children;
  	      last SWITCH;
  	    };
  	    ($type == XML_ELEMENT_NODE) && do {
  	      my ($children);
  	      $children =$child->findvalue
  		("count(descendant::node()[namespace-uri() = '$NS'])");
	      if($children) {
		$code .= (join '',
			  'push @__stack, map {', "\n",
			  'my ($clone, $count);',"\n",
			  '$count = 1;',"\n",
			  '$clone = $_->cloneNode(1);',"\n",
			  '$parent->insertAfter($clone, $current);',"\n",
			  # clean up namespacing?
			  'foreach my $fragment ($clone->findnodes',"\n",
			  '("descendant::node()[namespace-uri() = \'',$NS,'\']")) {',"\n",
			  'push @__fragments, $__fragments[(',($position),'+ $count)];',"\n",
			  '$__fragments[(',($position),'+ $count)] = $fragment;',"\n",
			  '$count++;',"\n",
			  '}',"\n",
			 );
		$code .= $self->compile($class, $fragment, \@fragments,
					 ($position + 1), $children);
		$code .= (join '',
			  '$clone;',"\n",
			  '}',"\n",
			  ' $current->findnodes(\'child::node()[position()=',
			  (1+$count),']\');',"\n");

  		$position = $position + $children;
  	      }
	      else {
		$code .= (join '',
			  'push @__stack, map {$_->cloneNode(1);}',"\n",
			  ' $current->findnodes(\'child::node()[position()=',
			  (1+$count),']\');',"\n");
	      }
  	      last SWITCH;
  	    };
	  };
	  $count++;
	}

	$code .= (join '',
		  '};',"\n",
		  'shift @__stack;',"\n",
		  'while(my $node = shift @__stack) {',"\n",
		  '$parent->appendChild($node);',"\n",
		  '}',"\n",
		  '}',"\n"
		 );
	last SWITCH;
      };
      $type eq "expr" && do {
	my (@children, $count, $element);
	@children = $fragment->getChildnodes;
	$count = 0;
	$element = 0;
	$code .= (join '',
		  '{',"\n",
		  'my ($current, $parent, $clone, $value);',"\n",
		  '$current = $__fragments[',($position),'];',"\n",
		  '$parent = $current->parentNode;',"\n",
		  'unshift @__stack, undef;',"\n",
		  '$value = do { ',"\n",
		  'my (@__nodes);',"\n",
		 );


	while ($count <= $#children) {
	  my ($type, $child);
	  $child = $children[$count];
	  $type = $child->getType;

	SWITCH: {
	    ($type == XML_TEXT_NODE || $type == XML_CDATA_SECTION_NODE) && do {
	      $code .= $child->getData;
	      last SWITCH;
	    };
  	    ($type == XML_ELEMENT_NODE &&
	     ($child->namespaceURI || '') eq $NS) && do {
	       my ($children);
	       $children = $child->findvalue
		 ("count(descendant-or-self::node()[namespace-uri() = '$NS'])");
	       $code .= $self->compile($class, $fragment, \@fragments,
				       ($position + 1), $children);
	       $code .= (join '',
			 'map { ',"\n",
			 'if($_->namespaceURI ne \'',$NS,'\') {',"\n",
			 '$current->removeChild($_);',"\n",
			 '$parent->insertAfter($_, $current) }',"\n",
			 '} $current->getChildnodes;',"\n",
			 'undef;',"\n",
			);
  		$position = $position + $children;
	       last SWITCH;
  	    };
  	    ($type == XML_ELEMENT_NODE) && do {
  	      my ($children);
  	      $children = $child->findvalue
  		("count(descendant::node()[namespace-uri() = '$NS'])");
	      # we should be stashing an array of child nodes to refer to!
  	      if($children) {
		$code .= (join '',
			  'push @__nodes, map {', "\n",
			  'my ($clone, $count);',"\n",
			  '$count = 1;',"\n",
			  '$clone = $_->cloneNode(1);',"\n",
			  '$parent->insertAfter($clone, $current);',"\n",
			  # clean up namespacing?
			  'foreach my $fragment ($clone->findnodes',"\n",
			  '("descendant::node()[namespace-uri() = \'',$NS,'\']")) {',"\n",
			  'push @__fragments, $__fragments[(',($position),'+ $count)];',"\n",
			  '$__fragments[(',($position),'+ $count)] = $fragment;',"\n",
			  '$count++;',"\n",
			  '}',"\n",
			 );
		$code .= $self->compile($class, $fragment, \@fragments,
					 ($position + 1), $children);
		$code .= (join '',
			  '$clone;',"\n",
			  '}',"\n",
			  ' $current->findnodes(\'child::node()[position()=',
			  (1+$count),']\');',"\n");

  		$position = $position + $children;
  	      }
	      else {
		$code .= (join '',
			  'push @__nodes, map {$_->cloneNode(1);}',"\n",
			  ' $current->findnodes(\'child::node()[position()=',
			  (1+$count),']\');',"\n");
	      }

	      $element++;
  	      last SWITCH;
  	    };
	  };
	  $count++;
	}

	$code .= (join '',
		  (($element)? ';\@__nodes;': ($#children)? ';undef;' : ''),"\n",
		  '};',"\n",
		  'shift @__stack;',"\n",
		  'if(defined $__stack[0]) {',"\n",
		  'while(my $node = shift @__stack) {',"\n",
		  '$parent->appendChild($node);',"\n",
		  '}',"\n",
		  '}',"\n",
		  'if(ref $value && (ref $value eq \'ARRAY\' ||',"\n",
		  'UNIVERSAL::isa($value,\'XML::LibXML::Node\'))) {',"\n",
		  'map { $parent->appendChild($_); } ',"\n",
		  '(ref $value eq "ARRAY")? @{$value} : $value;',"\n",
		  '}',"\n",
      		  'elsif(defined $value) {',"\n",
		  '$value = $document->createTextNode($value);',"\n",
		  '$parent->insertAfter($value, $current);',"\n",
		  '}',"\n",
		  '}',"\n"
		 );

	last SWITCH;
      };
      do {
	# should warn that unknown tag!
	last SWITCH;
      };
    };

    $position++;
  }

  if($node->getType == XML_DOCUMENT_NODE ||
     !defined $node->parentNode) {
    my ($header, $footer);
    $code = (join '',
	     'package ', $class, ';',"\n",
	     'use strict;',"\n",
	     'no warnings;',"\n",
	     'use XML::XSP::Page;',"\n",
	     'use XML::XSP::Log;',"\n",
	     'use XML::XSP::Exception qw/:try/;',"\n",
	     'use vars qw/@ISA @__fragments @__stack/;',"\n",
	     '@ISA = qw/XML::XSP::Page/;',"\n",
	     'sub _transform {',"\n",
	     'my ($self, $document, $options) = @_;',"\n",
	     'my ($current, $parent);',"\n",
	     'eval { ',"\n",
	     '@__stack = ();',"\n",
	     '@__fragments = $document->findnodes',"\n",
	     '("descendant-or-self::node()[namespace-uri() = \'',$NS,'\']");',"\n",
	     $code, "\n",
	     'while(my $fragment = pop @__fragments) {',"\n",
	     '$fragment->parentNode->removeChild($fragment) if defined $fragment;',"\n",
	     '}',"\n",
	     '};',"\n",
	     '@__stack = ();',"\n",
	     '@__fragments = ();',"\n",
	     'if($@) {',"\n",
	     '$document = undef;',"\n",
	     '(ref $@)? (throw $@) : ',"\n",
	     '(throw XML::XSP::Exception("Transform failed: $@"));',"\n",
	     '}',"\n",
	     'return  $document;',"\n",
	     '};',"\n",
	     '1;',"\n"
	    );
    @fragments = ();
  }
  return $code;
}

sub _match_handler {
  my ($uri) = @_;
  return ($uri =~/^(unknown-\d+)#/)? 1 : 0;
}

sub _open_handler {
  my ($uri) = @_;
  my ($data);
 SWITCH:{
    ($uri  =~ s/^(unknown-\d+)#//) && do {
      my ($handle, $pos , @data);
    FIND: {
	no strict 'refs';
	unless(defined ${join '', $uri,'::STYLESHEET'}) {
	  my ($ref, $fh);
	  local $/ = "\n";
	  $ref = $uri;
	  $ref =~ s/::/\//g;
	  $fh = FileHandle->new;
	  $fh->open($INC{"$ref.pm"});
	  while(<$fh>) {
	    if(index($_,"__DATA__") == 0) {
	      $handle = *{join '', $uri,'::STYLESHEET'} = $fh;
	      ${join '', $uri,'::STYLESHEET'} = 1;
	      last FIND;
	    }
	  }
	  ${join '', $uri,'::STYLESHEET'} = 0;
	}
	$handle = *{join '', $uri,'::STYLESHEET'}{IO};
      }
      if($handle && $handle->opened) {
	my (@data);
	$pos = tell $handle;
	while(<$handle>) {
	  last if $handle =~ /^__(.*)__\s*?$/;
	  push @data, $_;
	}
	$data = join '', @data;
	seek $handle, $pos, 0;
      }
      else {
	$data = (join '',
		 '<?xml version="1.0"?>',
		 '<xsl:stylesheet ',
		 'xmlns:xsl="http://www.w3.org/1999/XSL/Transform" ',
		 'version="1.0"/>');
      }
      last SWITCH;
    };
  };
  return $data;
}

sub _read_handler {
  return substr($_[0], 0, $_[1], '');
}

sub _close_handler { }

1;

__END__

=pod

=head1 NAME

XML::XSP::Driver::LibXSLT - A LibXSLT based XML::XSP Driver.

=head1 DESCRIPTION

This provides an XML::XSP::Driver based around the LibXML/LibXSLT
XML & XSLT libraries.

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

L<XML::XSP>,L<XML::XSP::Driver>

=cut
