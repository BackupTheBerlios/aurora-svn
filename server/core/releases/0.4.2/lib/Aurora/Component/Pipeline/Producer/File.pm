package Aurora::Component::Pipeline::Producer::File;

use strict;

use Aurora::Log;
use Aurora::Server;
use Aurora::Util qw/str2time evaluate/;
use Aurora::Resource;
use Aurora::Component::Pipeline;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Pipeline/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{base} = $options{base};
  $self->{cache} = (($options{cache} || '') =~ /y|1|on/i)? 1 : 0;
  $self->{expires}= str2time($options{expires});
  $self->{charset} = ($options{charset} || 'utf-8');
  $self->{'content-type'} = ($options{'content-type'} || 'text/xml');
  $self->{'mime-type'} = ($options{'mime-type'} ||
			  $options{'content-type'} || 'text/xml');
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  $data ||= {};
  $data->{expires} = str2time($data->{expires});
  if(exists $data->{cache}) {
    $data->{cache} = (($data->{cache} || '') =~ /y|1|on/i)? 1 : 0;
  }
  return $self->SUPER::closure($data);
}

sub run {
  my ($self, $context) = @_;
  my ($instance, $base, $uri, $oib);
  logsay('File: Retrieving resource');
  $instance = $self->instance;

  $base = ((defined $instance->{base})?
	   evaluate($instance->{base}, $context) :
	   Aurora::Server->base);

  $uri = evaluate($instance->{uri}, $context) ||
    throw Aurora::Exception::Error("No uri specified" );

  if($oib = Aurora::Resource->fetch($uri, {base => $base })) {
    my ($response, $content_type, $mime_type, $charset);
    $response = $context->response;
    $content_type = ($oib->type('content-type') ||
		     $instance->{'content-type'});
    $mime_type = ($instance->{'mime-type'} || $content_type);
    $charset = ($oib->type('charset') || $instance->{charset}),

    $context->dependancy($oib);
    $response->header(
		      charset       => $charset,
		      mime_type     => $mime_type,
		      content_type  => $content_type,
		      expires       => ($instance->{expires} ||
					$oib->type('expires')),
		      last_modified => $oib->type('last-modified'),
		      etag          => $oib->type('etag'),
		     );

    $response->content
      ($oib->object,
       {content_type => $content_type,
	charset      => $charset});
    logsay('File: Done');
    return (DECLINED, $instance->{cache});
  }
  return NOT_FOUND;
}

sub cache {
  my ($self) = @_;
  return ($self->instance->{cache})? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

Aurora::Component::Pipeline::Producer::File - This producer loads a
file resource.



=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <producers>
        <producer name="file"
	          class="Aurora::Component::Pipeline::Producer::File"
		  base="file:///web"/>
      </producers>
    </components>
    <mounts>
      <mount type="pipeline" matcher:uri="^/(\w*)">
        <pipeline>
  	  <producer name="file" uri="${uri:1}/index.xml"/>
          ...
	</pipeline>
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This producer loads in a file resource for the pipeline source. The
file resource can either be a file on the local file system or any
resource available via HTTP.

To use the pipeline component, the handler should be added to the mount
declaration.

=head1 COMPONENT TAGS

=over 1

=item B<<producer>>

This tag signals to the sitemap to create a new component. Options
for this tag are:

=over 7

=item * B<base>

This set the base URI, to be applied when resolving relative URIs.

=item * B<cache>

Sets whether this components output can be cached.

=item * B<charset>

Sets the default charset for the content, in the event that the
component can't automatically determine it. 

The default value is UTF-8.

=item * B<class>

The class of the event to create.

=item * B<content-type>

Sets the default content-type for the content, in the event that the
component can't automatically determine it. The content-type should be
set to the base mime type of the underlying content. For example
an xsl stylesheet would have a content-type of text/xml while a
mime-type of text/xsl, since it's underlying content is represented as
XML.

The default value is text/xml.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the created component.

=item * B<mime-type>

Sets the default mime-type for the content, in the event that the
component can't automatically determine it.

The default value is the value for the content-type.

=back

=back

=head1 MOUNT TAGS

=over 1

=item B<<producer>>

This tag sets the producer for the current mount pipeline. Options for
this tag are:

=over 7

=item * B<base>

This set the base URI, to be applied when resolving relative URIs.

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

Sets the default mime-type for the content, in the event that the
component can't automatically determine it.

The default value is text/xml.


=item * B<uri>

The URI of the file to load.

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
