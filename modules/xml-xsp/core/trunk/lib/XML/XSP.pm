package XML::XSP;
use strict;

use XML::XSP::Log;
use XML::XSP::Exception qw/:try/;

use XML::XSP::PageFactory;
use XML::XSP::DriverFactory;
use XML::XSP::TaglibFactory;

use vars qw/$VERSION $DEBUG/;
$VERSION = '0.4.2';
$DEBUG   = 3;

use constant DRIVER => qw/XML::XSP::Driver::LibXSLT/;

sub new {
  my ($class, %options) = @_;
  my ($self, $driver, @taglibs);

  $DEBUG = $options{Debug}
    if defined $options{Debug};

  XML::XSP::Log->new($options{LogHandler})
      if defined $options{LogHandler};

  $driver =((UNIVERSAL::isa($options{Driver},'XML::XSP::Driver'))?
	    $options{Driver} :
	    XML::XSP::DriverFactory->create
	    (($options{Driver})?  $options{Driver} :  DRIVER));

  $self = bless {
		 Taglib     => {},
		 Taglibs    => [],
		 Stylesheet => undef,
		 Driver     => $driver
		}, $class;

  @taglibs = ('XML::XSP::Taglib::Core',
	      (ref $options{Taglibs} eq 'ARRAY')?
	      @{$options{Taglibs}} : $options{Taglibs});
  while (my $taglib = shift @taglibs) {
    my ($options);
    $options = shift @taglibs if ref $taglibs[0] eq 'HASH';
    $taglib = XML::XSP::TaglibFactory->create($taglib, $options);
    if(defined $taglib) {
      no strict 'refs';
      push @{$self->{Taglibs}}, $taglib;
      $self->{Taglib}->{${join '::', ((ref $taglib)?
				      ref $taglib : $taglib), 'NS'}} = $taglib;
    }
  }

  return $self;
}

sub start{
  my ($self) = @_;
  map { $_->start if ref $_ } @{$self->{Taglibs}};
}

sub stop {
  my ($self) = @_;
  map { $_->stop if ref $_ } @{$self->{Taglibs}};
}


sub driver {
  my ($self) = @_;
  return $self->{Driver};
}

sub taglib {
  my ($self, $uri) = @_;
  return ((exists $self->{Taglib}->{$uri})?
	  $self->{Taglib}->{$uri} : undef);
}

sub apply_taglibs {
  my ($self, $document) = @_;
  my ($stylesheet);
  $document = $self->{Driver}->document($document);
  unless($stylesheet = $self->{Stylesheet}) {
    $stylesheet = (join '',
		   '<?xml version="1.0"?>',"\n",
		   '<xsl:stylesheet ',
		   'xmlns:xsl="http://www.w3.org/1999/XSL/Transform" ',
		   'version="1.0">',"\n",
		   (map {
		     ('<xsl:import href="#',((ref $_)? ref $_ : $_),'" />',"\n")		   } @{$self->{Taglibs}}),
		   '</xsl:stylesheet>');
    $stylesheet = $self->{Driver}->stylesheet(\$stylesheet);
    $self->{Stylesheet} = $stylesheet;
  }
  return $stylesheet->transform($document);
}

sub page {
  my ($self);
  $self = shift;
  return XML::XSP::PageFactory->create($self, @_);
}

1;

__END__

=pod

=head1 NAME

XML::XSP - A Perl based XSP processor.

=head1 SYNOPSIS

  use XML::XSP;
  $xsp = XML::XSP->new
   (Taglibs => [
  	        'XML::XSP::Taglib::Util',
		'XML::XSP::Taglib::ESQL' => { driver => 'mysql'},
                'XML::XSP::Taglib::Param'
      	       ]);
  $xsp->start;

  $page = $xsp->page('http://localhost/' => $document);
  $result = $page->transform($document, \%options);

  $xsp->stop;

=head1 DESCRIPTION

This module implements a Perl based eXtensibe Server Page (XSP) processor.
XSP is a server side technology (initially created for Cocoon) specifically
tailored to dynamically generating XML documents though the use of embeding
code (similar to ASP or JSP). In addition to the core XSP functions, the
processor can be extended through the use of user defined Taglibs. These
can be deployed to create additional XSP tags that can be embeded with a
document and control how they are evaluated.

The XML::XSP processor works in two stages. In the first stage, the source
XSP document is taken and an XSP Page transformer is compiled. This
object represents the transform required to be applied the source to
evaluate the XSP tags. This transform is then applied in the second
stage to the source document, causing the XSP tags to be evaluated and
the resultant document returned.

Now by nature of the XSP Page transformer being stored as a transform,
this Page can then be cached and applied to any source document that
is of the same form. Documents of the same form consist of all source
documents where all XSP tags are identical and appear in the same
order (from doing a depth first, breadth search). This does mean that
the XSP Page transformer will remain valid even if the surrounding XML
is changes.

Taglibs are implemented as a preprocessing stage to the XSP processor,
converting taglib defined tags into the Core XSP tags, through the
application of an XSLT stylesheets.

Further information can be found at:

=over 2

=item * http://xml.apache.org/cocoon/userdocs/xsp/xsp.html

=item * http://www.axkit.org/docs/xsp/guide.dkb

=back


=head1 CONSTRUCTOR

=over 1

=item B<new>(%options)

Construct a XML::XSP processor. The constructor takes an optional hash,
containing on or more of the following parameters.

=over 4

=item * Debug

Set the level of log messages to be displayed. A value of 0 will
result in no log messages being displayed, while 10 will mean all log
messages will be seen.

=item * Driver

Set the underlying driver the processor should use. This can be set to
a class name for the driver to be used or an instance of an
XML::XSP::Driver can be supplied.

=item * LogHandler

This enables a user to supply an external callback to handle message
logging rather than the builtin default.

=item * Taglibs

This option takes a list of external taglibs this processor should
use. The list can consist of either the class name of the Taglib or a
pair of parameters containing the class name and a hash containing
initialisation parameters for the Taglib class.

=back

=back

=head1 PROCESSING METHODS

=over 6

=item B<start>()

This method causes all of the XSP processors Taglibs to start,
enabling them to initialise any persistent state or connections.

=item B<stop>()

This method causes all of the XSP processors Taglibs to stop,
enabling them to cleanup/close any persistent state or connections.

=item B<apply_taglibs>($document)

The apply_taglibs method accepts a document reference (either a URI
pointing to the source document, a filehandle, a string reference or a
driver native document) and returns a document with all of the
external Taglib tags expanded in terms of the Core XSP tags.

=item B<driver>()

The method returns the underlying XML::XSP::Driver instance used by
this processor.

=item B<taglib>($uri)

The method accepts a URI string representing the namespace of the taglib
requested and returns the corresponding taglib instance.

=item B<page>([$uri], $document, [\%options])

This method accepts an optional URI reference or string, a document
reference (either a URI pointing to the source document, a filehandle,
a string reference or a driver native document) and a hash of optional
parameters. This method returns a compiles XSP Page transformer, which
can be used to evaluate the source document.

Upon specifying the optional URI reference, it will cause the
resulting page to be pinned in memory against that URI (rather than
the default behaviour, which is the page is unloaded from memory when
its reference count reaches zero). This will result pages against the
same URI using the pinned page, rather than recompiling.

Currently, the only optional parameter supported is the "Taglib"
option, which disables taglib processing.

=back


=head1 CAVEATS

There is currently a minor memory leak when XSP Page transformers are
 garbage collected, they are not fully unloaded from memory. However,
 this is only a problem if you can't use Page pinning and you really
 need to compiling a new XSP Page transformers for each source
 document (which is highly unlikely in real world usage).


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

L<XML::XSP::Driver>, L<XML::XSP::Page>, L<XML::XSP::Taglib>,
L<XML::XSP::DriverFactory>, L<XML::XSP::PageFactory>,
L<XML::XSP::TaglibFactory>, L<XML::XSP::Log>,
L<XML::XSP::Exception>

=cut
