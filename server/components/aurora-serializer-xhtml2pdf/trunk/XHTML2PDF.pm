package Aurora::Component::Pipeline::Serializer::XHTML2PDF;

use strict;

use Digest::MD5 qw/md5_hex/;

use Aurora::Log;
use Aurora::Server;
use Aurora::Util qw/str2time str2code evaluate/;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Component::Pipeline;


use vars qw/@ISA $VERSION/;
@ISA = qw/Aurora::Component::Pipeline/;

$VERSION = '0.4.1';

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $self->{'cache'} = (($options{'cache'} || '') =~ /y|1|on/i)? 1 : 0;
  $self->{'content-type'} = 'text/html';
  $self->{'mime-type'} = ($options{'mime-type'} || 'application/pdf');
  $self->{'charset'} = ($options{'charset'} || 'ISO-8859-1');
  $self->{'encoding'} = $options{'encoding'};
  $self->{'expires'} = str2time($options{'expires'});
  $self->{'code'} = str2code($options{'code'});

  $self->{doctype} = ($options{doctype} || 'webpage');

  $self->{converter} = (($options{converter})?
			do { $options{converter} =~ /^(file:\/\/)?(.*)/; $2} :
			()) || 'htmldoc';
  open FILE, $self->{converter} ||
    throw Aurora::Exception("Unable to find the htmldoc program");
  close FILE;

  $self->{tmp} = (($options{tmp})?
		  do { $options{tmp} =~ /^(file:\/\/)?(.*)/; $2} :
		  ()) || '/tmp';
  unless(-e $self->{tmp}) {
    throw Aurora::Exception("Temporary directory does no exist");
  }

  return $self;
}

sub closure {
  my ($self, $data) = @_;
  $data->{'content-type'} = 'text/html';
  $data->{'mime-type'} ||= 'application/pdf';
  $data->{expires} = str2time($data->{expires});
  $data->{code} = str2code($data->{code});
  if(exists $data->{cache}) {
    $data->{cache} = (($data->{cache} || '') =~ /y|1|on/i)? 1 : 0;
  }
  return $self->SUPER::closure($data);
}


sub run {
  my ($self, $context) = @_;
  my ($serializer, $instance, $response, $expires, $tmp);
  $serializer = substr(ref $self, 1+rindex(ref $self,':'));
  $instance = $self->instance;
  $response = $context->response;
  $expires = $instance->{expires};

  $tmp = (join '', $self->{tmp}, '/htmldoc-',
	  md5_hex(join '-',rand(1000),time, $$),
	  '.dat');


  logsay($serializer,': Serializing content to ', $instance->{'mime-type'});

  try {
    my ($converter, $charset, $base, $doctype, $document);
    local $/ = undef;
    ($charset) = ($instance->{charset} =~ /^iso-(.*)$/i);
    ($doctype) = ($instance->{doctype} =~ /(webpage|book)/);

    $base = (evaluate($instance->{base}, $context) ||
	     Aurora::Server->base);
    $base = do { $base =~ /^(file:\/\/)?(.*)/; $2};

    $converter = (join ' ',
		  ($self->{converter} || 'htmldoc'),
		  (($charset)? ("--charset", $charset) : ()),
		  (($base)? ("--path",$base) : ()),
		  (($doctype)? "--$doctype" : "--webpage"),
		  "--permissions no-modify --size a4 --linkstyle plain",
		  "--no-links -t pdf --quiet", $tmp, "|");


    open (FILE, "> $tmp") ||
      throw Aurora::Exception("Can't open temporary file: $!");
    print FILE $response->content;
    close FILE;

    open (FILE, $converter) ||
      throw Aurora::Exception("HTML2PDF conversion failed: $!");
    binmode FILE;
    $document =  <FILE>;
    close FILE;
    $response->content($document, {content_type => 'text/plain',
				   charset => $instance->{charset}});

    $response->header(
		      charset          => $instance->{charset},
		      mime_type        => $instance->{'mime-type'},
		      content_type     => 'text/plain',
		      content_encoding => $instance->{encoding},
		      ((defined $expires && $expires <= 0)?
		       (cache_control  => 'private',
			pragma => 'private',
			expires => 0) :
		       (($expires)?
			(expires => $expires) :()))
		     );

    unlink $tmp;
    logdebug($serializer,': Done');
  }
  otherwise {
    unlink $tmp;
    logwarn(shift);
    throw Aurora::Exception::Error($serializer, ":Serialization failed");
  };

  $response->code($instance->{code}) if defined $instance->{code};
  $response->status(OK);
  return (OK, $instance->{cache});
}

sub cache {
  my ($self) = @_;
  return ($self->instance->{cache})? 1 : 0;
}


1;


__END__

=pod

=head1 NAME

Aurora::Component::Pipeline::Serializer::XHTML2PDF - This component
serializes the current XHTML content to PDF.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <components>
      <serializer>
        <serializer name="pdf"
          class="Aurora::Component::Pipeline::Serializer::XHTML2PDF"/>
      </producers>
    </components>
    <mounts>
      <mount type="pipeline" matcher:uri="^/(\w*)">
        <pipeline>
          ...
          <serializer name="pdf"/>
        </pipeline>
      </mount>
    </mounts>
  </sitemap>

=head1 DESCRIPTION

This pipeline component takes the current response content
representing an XHTML document and serializes it to PDF.

To use the pipeline component, the handler should be added to the mount
declaration.

=head1 COMPONENT TAGS

=over 1

=item B<<serializer>>

This tag signals to the sitemap to create a new component. Options
for this tag are:

=over 9

=item * B<cache>

Sets whether this components output can be cached.

=item * B<charset>

Sets the default charset for the content, in the event that the
component can't automatically determine it.

Only the charsets ISO-8859-1...ISO-8859-15 are currently valid, the
default is ISO-8859-1.

=item * B<class>

The class of the event to create.

=item * B<converter>

The URI representing the location of the HTMLDOC binary, if it is not
in the servers PATH.

=item * B<doctype>

Sets the type of PDF document produced. Valid options are either
webpage or book.


=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<mime-type>

Sets the mime-type for the response content.

The default value is application/pdf.

=item * B<name>

The name of the created component.

=item * B<tmp>

The URI of path to the local directory that is to be used for temporarily
storing files generated while serializing the content. This directory
needs to be readable and writable by the server.

The default path is 'file:///tmp'.

=back

=back

=head1 MOUNT TAGS

=over 1

=item B<<serializer>>

This tag sets the serializer for the current mount pipeline. Options for
this tag are:

=over 6

=item * B<cache>

Sets whether this pipeline output can be cached.

=item * B<charset>

Sets the default charset for the content, in the event that the
component can't automatically determine it.

Only the charsets ISO-8859-1...ISO-8859-15 are currently valid, the
default is ISO-8859-1.

=item * B<doctype>

Sets the type of PDF document produced. Valid options are either
webpage or book.

=item * B<expires>

Set the default amount of time that a this components output is valid
for.

=item * B<name>

The name of the component to use.

=item * B<mime-type>

Sets the mime-type for the response.

The default value is application/pdf.

=back

=back

=head1 CAVEATS

=over 2

=item * HTMLDOC currently doesn't support UTF-8

=item * External files required to generate the PDF must reside on the
local filesystem

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
