package Aurora::Component::Pipeline::Serializer::XML;

use strict;

use XML::LibXML;

use Aurora::Log;
use Aurora::Util qw/str2time str2code/;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Component::Pipeline;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Pipeline/;



sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{'cache'} = (($options{'cache'} || '') =~ /y|1|on/i)? 1 : 0;
  $self->{'charset'} = ($options{'charset'} || 'utf-8');
  $self->{'content-type'} = ($options{'content-type'} || 'text/xml');
  $self->{'mime-type'} = ($options{'mime-type'} ||
			  $options{'content-type'} || 'text/xml');
  $self->{'encoding'} = $options{'encoding'};
  $self->{'expires'} = str2time($options{'expires'});
  $self->{'code'} = str2code($options{'code'});
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  $data->{expires} = str2time($data->{expires});
  $data->{code} = str2code($data->{code});
  if(exists $data->{cache}) {
    $data->{cache} = (($data->{cache} || '') =~ /y|1|on/i)? 1 : 0;
  }
  return $self->SUPER::closure($data);
}


sub run {
  my ($self, $context) = @_;
  my ($serializer, $instance, $response, $expires);
  $serializer = substr(ref $self, 1+rindex(ref $self,':'));
  $instance = $self->instance;
  $response = $context->response;
  $expires = $instance->{expires};
  logsay($serializer,': Serializing content to ', $instance->{'content-type'});

  $response->header(
		    charset          => $instance->{charset},
		    content_type     => $instance->{'content-type'},
		    mime_type        => $instance->{'mime-type'},
		    content_encoding => $instance->{encoding},
		    ((defined $expires && $expires <= 0)?
		     (cache_control  => 'private',
		      pragma => 'private',
		      expires => 0) :
		     (($expires)?
		      (expires => $expires) :()))
		   );
  $response->code($instance->{code}) if defined $instance->{code};
  $response->status(OK);
  logdebug($serializer,': Done');
  return (OK, $instance->{cache});
}


sub cache {
  my ($self) = @_;
  return ($self->instance->{'cache'})? 1 : 0;
}



1;

__END__
=pod

=head1 NAME

Aurora::Component::Pipeline::Serializer::XML - This component
serializes the current content to XML.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <serializer>
        <serializer name="xml"
	            class="Aurora::Component::Pipeline::Serializer::XML"/>
      </producers>
    </components>
    <mounts>
      <mount type="pipeline" matcher:uri="^/(\w*)">
        <pipeline>
          ...
  	  <serializer name="xml"/>
	</pipeline>
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This pipeline component takes the current response content and
serializes it to XML.

To use the pipeline component, the handler should be added to the mount
declaration.

=head1 COMPONENT TAGS

=over 1

=item B<<serializer>>

This tag signals to the sitemap to create a new component. Options
for this tag are:

=over 6

=item * B<cache>

Sets whether this components output can be cached.

=item * B<charset>

Sets the default charset for the content, in the event that the
component can't automatically determine it.

The default value is UTF-8.

=item * B<class>

The class of the event to create.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the created component.

=item * B<mime-type>

Sets the mime-type for the response content.

The default value is text/xml.

=back

=back

=head1 MOUNT TAGS

=over 1

=item B<<serializer>>

This tag sets the serializer for the current mount pipeline. Options for
this tag are:

=over 5

=item * B<cache>

Sets whether this pipeline output can be cached.

=item * B<charset>

Sets the default charset for the content, in the event that the
component can't automatically determine it.

The default value is UTF-8.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the component to use.

=item * B<mime-type>

Sets the mime-type for the response.

The default value is text/xml.

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
