package Aurora::Component::Event::Redirect;
use strict;

use Aurora::Util qw/evaluate/;
use Aurora::Component::Event;
use Aurora::Constants qw/:response/;
use Aurora::Log;


use vars qw/@ISA/;
@ISA = qw/Aurora::Component::Event/;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{base} = $options{base} if $options{base};
  return $self;
}

sub closure {
  my ($self, $data) = @_;
  return $self->SUPER::closure({event => $data});
}

sub run {
  my ($self, $context) = @_;
  my ($instance, $request, $response, $base, $uri);
  $instance = $self->instance;
  $request = $context->request;
  $response = $context->response;

  $base = ((defined $instance->{base})?
	   evaluate($instance->{base}, $context) :
	   $context->request->base);
  $uri = evaluate($instance->{event}, $context);
  $uri = (join '/',$base, $uri) if $base && $uri !~ /:\/\//;
  $uri =~ s/([^:\/])\/\//$1\//g;

 SWITCH:{
    $uri =~ /^(http(s)?|file):\/\// && do {
      $response->status(REDIRECT);
      $response->header(location => $uri);
      last SWITCH;
    };
    do {
      logwarn('Unsupported protocol ', $uri);
      return NOT_FOUND;
    };
  };
  return REDIRECT;
}

1;
__END__

=pod

=head1 NAME

Aurora::Component::Event::Redirect - This component creates a HTTP
redirect response, based upon the event thrown.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:event="http://iterx.org/aurora/sitemap/1.0/event">
    <components>
      <events>
        <event name="not-found-handler" type="not-found"
	       class="Aurora::Component::Event::Redirect"
	       base="file://web/" />
      </events>
    </components>
    <mounts>
      <mount event:not-found-handler="not-found-page.html">
        ...
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

The redirect component creates a HTTP redirect response, based upon
the event thrown.

To use the event component, the handler should be added to the mount
declaration, specifying the target URI for the redirect.


=head1 COMPONENT TAGS

=over 1

=item B<<event>>

This tag signals to the sitemap to create a new event
component. Options for this tag are:

=over 4

=item * B<base>

The base URI to be used when resolving relative URIs.

=item * B<class>

The class of the event to create

=item * B<name>

The name of the created component

=item * B<type>

The type of event this component can handle. Possible values are ANY,
ERROR or any HTTP response code.

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

L<Aurora>, L<Aurora::Component>, L<Aurora::Component::Event>
