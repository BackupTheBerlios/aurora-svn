package XML::XSP::Page;

use XML::XSP::Log;
use XML::XSP::Exception qw/:try/;

use strict;

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		 Taglibs    => ((defined $options{Taglibs})?
				$options{Taglibs} : 1),
		 Processor  => ($options{Processor} ||
				throw XML::XSP::Exception
				("No processor supplied"))
		}, $class;
  return $self;
}

sub driver {
  shift->{Processor}->driver(@_);
}
sub taglib {
  shift->{Processor}->taglib(@_);
}

sub transform {
  my ($self, $source, $options) = @_;
  my ($processor, $document);
  $source || throw XML::XSP::Exception("No source document supplied!");
  $options ||= {};
  $processor = $self->{Processor};
  $document = $processor->driver->document($source);
  unless(defined $options->{Taglibs} && $options->{Taglibs} == 0 ||
	 $self->{Taglibs} == 0) {
    $document = $processor->apply_taglibs($document);
  }
  return $self->_transform($document, $options);
}

sub _transform { throw XML::XSP::Exception("Abstract Class"); }

sub DESTROY {
  my ($self) = @_;
  my ($package, $stab, @functions);
  $self->SUPER::DESTROY if $self->can('SUPER::DESTROY');

  $package = ref $self || $self;
  {
    # Based on code from Apache::PerlRun
    # (c) Doug MacEachern
    no strict 'refs';
    my $tab = \%{$package.'::'};
    for (keys %$tab) {
      my $fullname = join '::', $package, $_;
      #code/hash/array/scalar might be imported
      #make sure the gv does not point elsewhere
      #before undefing each
      if (%$fullname) {
	*{$fullname} = {};
	undef %$fullname;
      }
      if (@$fullname) {
	*{$fullname} = [];
	undef @$fullname;
      }
      if ($$fullname) {
	my $tmp; #argh, no such thing as an anonymous scalar
	*{$fullname} = \$tmp;
	undef $$fullname;
      }
      if (defined &$fullname) {
	no warnings;
	local $^W = 0;
	if (my $p = prototype $fullname) {
	  *{$fullname} = eval "sub ($p) {}";
	}
	else {
	  *{$fullname} = sub {};
	}
	undef &$fullname;
      }
      if (*{$fullname}{IO}) {
	if (fileno $fullname) {
	  close $fullname;
	}
      }
    }
    undef %{$package.'::'};
  }
  return 1;
}

1;

__END__

=pod

=head1 NAME

XML::XSP::Page - An abstract XSP page transformer class.

=head1 SYNOPSIS

  use XML::XSP;
  use XML::XSP::PageFactory;
  $processor = XML::XSP->new;

  $page = XML::XSP::PageFactory->create
           ($processor => '#local' => $document);

  # native document
  $result = $page->transform($document);

  # URI
  $result = $page->transform("file://tmp/test.xsp");

  # string
  $string = << 'XML';
  <xml version="1.0"?>
  ...
  XML
  $result = $page->transform(\$string);

  # filehandle
  $fh = FileHandle->new("> test.xsp");
  $result = $page->transform($fh);

=head1 DESCRIPTION

This abstract class provides the base for all XSP page
transformers. Instances of this class are created automatically by
XML::XSP::PageFactory, based upon the source XSP document
supplied. The page transformer returns represents a compiled class
that can be applied to an XSP document of the same form, to evaluate
the embeded XSP & taglib tags.

XSP documents of the same form, consist of all documents where the XSP
tags have the same content and appear in the same order (from doing a
depth first, breadth search). The result is that the same page
tranformer can be used to pages where the XML content varies over
time. However if this feature is used, it is left upto the
implementator validate if the document conforms to the correct
structure (in most cases this can be determined ahead of time, hence
this doesn't present a problem).


=head1 CONSTRUCTOR

All XSP page instances should be constructed via the
XML::XSP::PageFactory class.

=head1 PROCESSING METHODS

=over 3

=item B<driver>()

The method returns the underlying XML::XSP::Driver instance used by
this page.

=item B<taglib>($uri)

The method accepts a URI string representing the namespace of the taglib
requested and returns the corresponding taglib instance.

=item B<transform>($document,[\%options])

This method accepts a document instance (either a URI pointing to the
source document, a filehandle, a string reference or a driver native
document) and an optional hash of parameters, which might be required
by any  referenced. The document will then be evalutated and returned,
with the embeded XSP and taglib tags expanded.

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

L<XML::XSP>,L<XML::XSP::PageFactory>,L<XML::XSP::Driver>,
L<XML::XSP::Taglib>

=cut
