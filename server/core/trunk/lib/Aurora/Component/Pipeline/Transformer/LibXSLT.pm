package Aurora::Component::Pipeline::Transformer::LibXSLT;
use strict;

use Aurora::Log;
use Aurora::Server;
use Aurora::Context;
use Aurora::Util qw/str2time evaluate/;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Component::Pipeline;

use vars qw/@ISA $DEBUG/;
@ISA = qw/Aurora::Component::Pipeline/;

$DEBUG = 3;

sub new {
  my ($class, %options) = @_;
  my ($self, $processor);
  $self = $class->SUPER::new(%options);
  $self->{'cache'} = (($options{'cache'} || '') =~ /y|1|on/i)? 1 : 0;
  $self->{'expires'} = str2time($options{'expires'});
  $self->{'base'} = $options{'base'};
  $self->{'stylesheet'} = $options{'stylesheet'};
  $self->{'stylesheet-cache'} =
    (($options{'stylesheet-cache'} || '') =~ /y|1|on/i)? 1 : 0;
  $self->{'stylesheet-dependancy'} =
    (($options{'stylesheet-dependancy'} || '') =~ /y|1|on/i)? 1 : 0;
  $DEBUG = ($options{'debug'} || $Aurora::DEBUG);

  $processor = (join '::',__PACKAGE__,'Processor');
  $self->{_processor} = $processor->new(debug => ($DEBUG));
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  $data->{expires} = str2time($data->{expires});
  if(exists $data->{'cache'}) {
    $data->{'cache'} = (($data->{'cache'} || '') =~ /y|1|on/i)? 1 : 0;
  }
  if(exists $data->{'stylesheet-cache'}) {
    $data->{'stylesheet-cache'} =
      (($data->{'stylesheet-cache'} || '') =~ /y|1|on/i)? 1 : 0;
  }
  if(exists $data->{'stylesheet-dependancy'}) {
    $data->{'stylesheet-dependancy'} =
      (($data->{'stylesheet-dependancy'} || '') =~ /y|1|on/i)? 1 : 0;
  }
  return $self->SUPER::closure($data);
}

sub run {
  my ($self, $context) = @_; 
  my ($instance, $response, $document, $uri, $base);
  logsay("LibXSLT: Applying transform");

  $instance = $self->instance;
  $response = $context->response;

  $base = (evaluate($instance->{base}, $context) ||
	   Aurora::Server->base);

  $uri = (evaluate($instance->{stylesheet}, $context) ||
	  throw Aurora::Exception::Error("No stylesheet specified" ));

  try {
    my ($processor);
    $processor = $self->{_processor};
    $document = $response->content->convert('LibXML')->data;

    $document = $processor->transform
      ($document, {
		   base       => $base,
		   context    => $context,
		   stylesheet => $uri,
		   dependancy => $instance->{'stylesheet-dependancy'},
		   cache      => $instance->{'stylesheet-cache'},
		  });

  }
  otherwise {
    logwarn(shift);
    throw Aurora::Exception::Error("Transform failed");
  };
  $response->header(expires => $instance->{expires});
  $response->content($document);
  logsay("LibXSLT: Done");
  return (DECLINED, $instance->{'cache'});
}

sub cache {
  my ($self) = @_;
  return ($self->instance->{'cache'})? 1 : 0;
}


sub is_valid {
  my ($self, $context, $oib) = @_;
  my ($status);
  $status = $self->SUPER::is_valid($context, $oib);
  if($status == DECLINED) {
    my ($instance, $uri);
    if($instance->{'stylesheet-dependancy'}) {
      #check stylesheet dependancy validity
      $uri = (evaluate($instance->{stylesheet}, $context) ||
	      throw Aurora::Exception::Error("No stylesheet specified" ));
      $status = (($self->{_processor}->is_valid($uri , $context))?
		 DECLINED : DELETE);
    }
  }
  return $status;
}




package Aurora::Component::Pipeline::Transformer::LibXSLT::Processor;
use strict;

use XML::LibXML;
use XML::LibXSLT;

use Aurora::Log;
use Aurora::Resource;
use Aurora::Exception qw/:try/;

{
  my ($context, $base, @dependancy);

  sub new {
    my ($class, %options) = @_;
    my ($self, $parser, $processor);
    $parser =  XML::LibXML->new
      (ext_ent_handler => sub {
	 my $oib = $self->_resource_handler(@_);
	 return ($oib)? $oib->object : undef;
       });
    $parser->callbacks(\&_match_handler,
		       sub {$self->_open_handler(@_)},
		       \&_read_handler,
		       \&_close_handler);
    $processor = XML::LibXSLT->new;

    if($options{debug} > 9) {
      $processor->debug_callback
	( sub{ logdebug('LibXSLT: ', @_) });
    }
    $self = bless {
		   stylesheets  => {},
		   _parser      => $parser,
		   _processor   => $processor
		  }, $class;
    return $self;
  }

  sub is_valid {
    my ($self, $uri, $context) = @_;
    my ($stylesheet);
    if($stylesheet =  $self->{stylesheets}->{$uri}) {
      return 1 if
	!defined $stylesheet->{dependancy} ||
	  grep { ($_->is_valid)? 0 : 1; } @{$stylesheet->{dependancy}};
      delete $self->{stylesheets}->{$uri}
    }
    return 0;
  }

  sub transform {
    my ($self, $document, $options) = @_;
    my ($stylesheet, $uri, $request);
    $base = $options->{base};
    $options->{context} ||
      throw Aurora::Exception("No context supplied");
    $uri = $options->{stylesheet} ||
      throw Aurora::Exception("No stylesheet uri supplied");
    $uri = (join '/',$base, $uri) if
      $uri !~ /^(\w+:\/\/|\/)/ && $base;
    $request = $options->{context}->request;

    unless($stylesheet = $self->{stylesheets}->{$uri}->{stylesheet}) {
      my ($oib);
      @dependancy = ();
      if($oib = $self->_resource_handler($uri)) {
	logsay("LibXSLT: Parsing stylesheet");
	$stylesheet = $self->{_parser}->parse_string($oib->object);
	$stylesheet = $self->{_processor}->parse_stylesheet($stylesheet);
	if($options->{cache}) {
	  $self->{stylesheets}->{$uri} =
	    {stylesheet => $stylesheet,
	     dependancy => (($options->{dependancy})?
			    [ $oib, @dependancy ] : undef)};
	}
      }
      @dependancy = ();
      throw Aurora::Exception("Stylesheet creation failed")
	unless defined $stylesheet;
    }
    $context = $options->{context};
    $document = $stylesheet->transform
      ($document, XML::LibXSLT::xpath_to_string
       (uri => $request->uri,
	#libxslt doesn't like param names containing :
	(grep { tr/\:\+/\- /; s/\%([A-F\d]{2})/chr(hex($1))/gei; 1 }
	 map {
	   # filter out all parameters with no values!
	   ((index $_, '=') > 0)? (split(/=/,$_,2)) : ();
	 } split /[;&]/, ($request->uri->query || ''))));
    $context = $base = undef;
    return $document;
  }


  sub _resource_handler {
    my ($self, $uri) = @_;
    my ($oib);
    $oib = Aurora::Resource->fetch($uri,{ base => $base});
    # is it a runtime file dependancy or not
    ((defined $context)?
     $context->dependancy($oib) :
     push @dependancy, $oib);
    return $oib;
  }

  sub _match_handler {
    my ($uri) = @_;
    return ($uri &&
	    $uri !~/^(unknown-\d+|file:\/\/\/etc\/xml\/catalog)/)? 1 : 0;
  }

  sub _open_handler {
    my ($self, $uri) = @_;
    my ($oib);
    $oib = $self->_resource_handler($uri);
    return ($oib)? $oib->object : undef;
  }

  sub _read_handler {
    return substr($_[0], 0, $_[1], '');
  }
  sub _close_handler {}
}

1;
__END__

=pod

=head1 NAME

Aurora::Component::Pipeline::Transformer::LibXSLT - This transformer
applies an XSLT stylesheet to the current response content.


=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <transformers>
        <transformer name="xslt"
	  class="Aurora::Component::Pipeline::Transformer::LibXSLT"
          base="file:///web"/>
      </transformers>
    </components>
    <mounts>
      <mount type="pipeline" matcher:uri="^/(\w*)">
        <pipeline>
	  ...
  	  <transformer name="xslt"  stylesheet="/common.xsl"/>
          ...
	</pipeline>
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This transfomer applies a specified XSLT stylesheet to the current
response content, using the LibXSLT XSLT processor.

To use the pipeline component, the handler should be added to the mount
declaration.

=head1 COMPONENT TAGS

=over 1

=item B<<transformer>>

This tag signals to the sitemap to create a new component. Options
for this tag are:

=over 9

=item * B<base>

This set the base URI, to be applied when resolving relative URIs.

=item * B<cache>

Sets whether this components output can be cached.

=item * B<class>

The class of the event to create.

=item * B<debug>

The level of debug output this transformer should produce.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the created component.

=item * B<stylesheet>

Sets the default URI for the XSLT stylesheet to use.

=item * B<stylesheet-cache>

This enables compiled stylesheets to be cached in memory.

=item * B<stylesheet-dependancy>

This signals the process to keep track of all stylesheet
dependancies when determining if a cached item is still valid.

=back

=back

=head1 MOUNT TAGS

=over 1

=item B<<transformer>>

This tag sets a transformer for the current mount pipeline. Options for
this tag are:

=over 7

=item * B<base>

This set the base URI, to be applied when resolving relative URIs.

=item * B<cache>

Sets whether this pipeline output can be cached.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the component to use.

=item * B<stylesheet>

Sets the URI of the XSLT stylesheet to use.

=item * B<stylesheet-cache>

This enables compiled stylesheets to be cached in memory.

=item * B<stylesheet-dependancy>

This signals the process to keep track of all stylesheet
dependancies when determining if a cached item is still valid.


=back

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

L<Aurora>, L<Aurora::Component>, L<Aurora::Component::Pipeline>
