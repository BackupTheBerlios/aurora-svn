package XML::XSP::PageFactory;
use strict;

use Digest::MD5 qw/md5_hex/;

use XML::XSP::Page;
use XML::XSP::Log;
use XML::XSP::Exception qw/:try/;

{
  my ($instance);

  sub new {
    my ($class) = @_;
    unless(defined $instance) {
      $instance = bless {
			 Pages => {}
			}, $class;
    }
    return $instance;
  }

  sub create {
    my ($self, $processor, $uri, $document, $options, $driver, $class, $code);
    $self = (ref $_[0])? shift : shift->new;
    $processor = shift;
    $driver = $processor->driver;
    $uri = ((scalar @_ == 3 ||
	     (scalar @_ == 2 && !UNIVERSAL::isa($_[1],'HASH')))?
	    shift : undef);


    return $self->{Pages}->{$uri}
      if defined $uri && exists $self->{Pages}->{$uri};

    $document = shift ||
      throw XML::XSP::Exception("No source document supplied!");
    $options = shift;
    $options = {} unless defined $options && UNIVERSAL::isa($options,'HASH');
    $class = (join '::', 'XML::XSP::Page',
	      ((defined $uri)?
	       md5_hex((UNIVERSAL::isa($uri, 'URI'))? $uri->as_string : $uri) :
	       md5_hex(join '-',time(),$$,rand(10000))));

    unless($code = $class->can('new')) {
      my ($page, $clone);
      try {
	$clone = $driver->document($document, {Clone => 1});
	$clone = $processor->apply_taglibs($clone);
	if($XML::XSP::DEBUG == 10) {
	  logdebug("Input:\n", $clone->toString, "\n");
	}

	$page = $driver->compile($class, $clone);
	eval $page;
	if ($@ || $XML::XSP::DEBUG > 9) {
	  my ($line);
	  logdebug("Script:\n",
		   map { (++$line,':', $_,"\n" )} split /\n/, $page);
	  logerror($@) if $@;
	}
	$code = $class->can('new');
      }
      otherwise {
	logerror(shift);
      };
    }
    if (defined $code) {
      my ($object);
      $object = $code->($class,
			%{$options},
			Processor => $processor);
      $self->{Pages}->{$uri} = $object if defined $uri;
      return $object;
    }
    return undef;
  }

  sub delete {
    my ($self, $uri) = @_;
    $self = (ref $_[0])? shift : shift->new;
    if(defined $uri) {
      return delete $self->{Pages}->{$uri};
    }
    return undef;
  }

}
1;
__END__

=pod

=head1 NAME

XML::XSP::PageFactory - A factory for dynamically loading and creating
XML::XSP::Page instances.

=head1 SYNOPSIS

  use XML::XSP;
  use XML::XSP::PageFactory;
  $processor = XML::XSP->new;

  $page = XML::XSP::PageFactory->create($processor => '#local' => $document);

  XML::XSP::PageFactory->delete('#local');


=head1 DESCRIPTION

This provides a factory helper class to assist in dynamically loading and
creating of a complied XSP page transformer.


=head1 CONSTRUCTOR

=over 1

=item B<new>()

Construct a new xsp page factory instance.

=back

=head1 PROCESSING METHODS

=over 2

=item B<create>($processor,[$uri], $document, \%options)

This method accepts the a reference to the XSP processors, this page
is to be associated with, an optional URI reference or string, a document
reference (either a URI pointing to the source document, a filehandle,
a string reference or a driver native document) and a hash of optional
parameters.

Upon specifying the optional URI reference, it will cause the
resulting page to be pinned in memory against that URI (rather than
the default behaviour, which is the page is unloaded from memory when
its reference count reaches zero). This will result pages against the
same URI using the pinned page, rather than recompiling.

Currently, the only optional parameter supported is the "Taglib"
option, which disables taglib processing.

=item B<delete>($uri)

This method accepts the URI of the page, causing that page to be
unpinned in memory (causing it to be unloaded from memory once it's
reference count becomes zero).

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

L<XML::XSP>,L<XML::XSP::Page>

=cut
