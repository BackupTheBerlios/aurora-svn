package Aurora::Component::Pipeline::Transformer::XSP;
use strict;

use XML::XSP;

use Aurora::Log;
use Aurora::Context;
use Aurora::Util qw/str2time/;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Component::Pipeline;

use vars qw/@ISA $DEBUG $VERSION/;
@ISA = qw/Aurora::Component::Pipeline/;

$VERSION = '0.4.3';
$DEBUG = 3;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{cache} = (($options{'cache'} || '') =~ /y|1|on/i)? 1 : 0;
  $self->{expires} = str2time($options{'expires'});
  $self->{taglibs} = [];

  $DEBUG = ($options{'debug'} || $Aurora::DEBUG);


  if($options{taglib}) {
    map {
      push @{$self->{taglibs}}, (delete $_->{class}, $_)
	if exists $_->{class};
    } (ref $options{taglib} eq 'ARRAY')?
      @{$options{taglib}} : $options{taglib};
  }

  $self->{_processor} = XML::XSP->new
    (Debug      => $DEBUG,
     Taglibs    => $self->{taglibs});


  return $self;
}

sub closure {
  my ($self, $data) = @_;
  $data->{expires} = str2time($data->{expires});
  if(exists $data->{cache}) {
    $data->{cache} = (($data->{cache} || '') =~ /y|1|on/i)? 1 : 0;
  }
  return $self->SUPER::closure($data);
}


sub start {
  my ($self) = @_;
  return $self->{_processor}->start if $self->{_processor};
}

sub stop {
  my ($self) = @_;
  return $self->{_processor}->stop if $self->{_processor};
}

sub run {
  my ($self, $context) = @_;
  my ($instance, $response, $document);
  logsay("XSP: Applying transform");
  $instance = $self->instance;
  $response = $context->response;

  try {
    my ($processor, $page, $path);
    $processor = $self->{_processor};
    $document = $response->content->convert('LibXML')->data;
    $path = $context->request->uri;
    $path = substr $path,0,(index $path, '?')
      if (index $path, '?') != -1;
    $page = $processor->page
      ($path => $document);
    $document = $page->transform($document, { context => $context });
  }
  catch Aurora::Exception with {
    my ($exception);
    $exception = shift;
    throw $exception;
  }
  otherwise {
    logwarn(shift);
    throw Aurora::Exception::Error("XSP: Transform failed");
  };
  $response->header(expires => $instance->{expires});
  $response->content($document);
  logsay("XSP: Done");
  return (DECLINED, $instance->{cache});
}

sub cache {
  my ($self) = @_;
  return ($self->instance->{cache})? 1 : 0;
}

1;
__END__

=pod

=head1 NAME

Aurora::Component::Pipeline::Transformer::XSP - This transformer
adds XSP support to Aurora.


=head1 SYNOPSIS

 <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <transformers>
        <transformer name="xsp"
         class="Aurora::Component::Pipeline::Transformer::XSP">
           <taglib class="XML::XSP::Taglib::Util"/>
           <taglib class="XML::XSP::Taglib::Aurora::Context"/>
        </transformer>
      </transformers>
    </components>
    <mounts>
      <mount type="pipeline" matcher:uri="^/(\w*)">
        <pipeline>
          ...
          <transformer name="xsp" />
          ...
        </pipeline>
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This transfomer expands eXtensibe Server Page (XSP) tags in the
current response content, using the XML::XSP processor.

To use the pipeline component, the handler should be added to the mount
declaration.


=head1 COMPONENT TAGS

=over 1

=item B<<transformer>>

This tag signals to the sitemap to create a new XSP component. Options
for this tag are:

=over 6

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

=item * B<<taglib>>

This tag is used to load additional XSP taglib support into the
current processor, as specified by the class attribute. All other
attribute values for this tag are used as initialisation parameters
for the taglib in question.

=back

=head1 MOUNT TAGS

=over 1

=item B<<transformer>>

This tag sets a transformer for the current mount pipeline. Options for
this tag are:

=over 4

=item * B<base>

This set the base URI, to be applied when resolving relative URIs.

=item * B<cache>

Sets whether this pipeline output can be cached.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the component to use.

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
