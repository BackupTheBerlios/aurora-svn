package Aurora::Component::Pipeline::Serializer::Text;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;

use Aurora::Component::Pipeline::Serializer::XML;

use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Pipeline::Serializer::XML/;

sub new {
  my ($class, %options) = @_;
  $options{'content-type'} = 'text/plain';
  return $class->SUPER::new(%options);
}

sub closure {
  my ($self, $data) = @_;
  $data->{'content-type'} = 'text/plain';
  return $self->SUPER::closure($data);
}

sub run {
  my ($self, $context) = @_;
  my ($response, $content);
  $response = $context->response;
  $content = $response->content;
  unless($content->content_type eq 'text/plain') {
    $response->content($content->convert('LibXML'));
  }
  return $self->SUPER::run($context);
}



1;

__END__

=pod

=head1 NAME

Aurora::Component::Pipeline::Serializer::Text - This component
serializes the current content to plain text.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <serializer>
        <serializer name="text"
	            class="Aurora::Component::Pipeline::Serializer::Text"/>
      </producers>
    </components>
    <mounts>
      <mount type="pipeline" matcher:uri="^/(\w*)">
        <pipeline>
          ...
  	  <serializer name="text"/>
	</pipeline>
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This pipeline component takes the current response content and
serializes it to plain text.

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

Sets the mime-type for the response.

The default value is text/plain.

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

Sets the mime-type for the response content.

The default value is text/plain.

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
