package XML::XSP::TaglibFactory;

use strict;

use XML::XSP::Log;
use XML::XSP::Exception qw/:try/;

sub new { shift; }

sub create {
  my ($self, $taglib, $options) = @_;
  my ($code);
  logdebug('Creating taglib ',$taglib);
  unless($code = $taglib->can('new')) {
    try {
      my ($file);
      $file = $taglib;
      $file =~ s/::/\//g;
      require (join '',$file,'.pm');
      $code = $taglib->can('new');
    }
    otherwise {
      logerror('Failed to load taglib ',$taglib, ': ', shift);
    };
  }

  return (($code)?
	  $code->($taglib,
		  ((UNIVERSAL::isa($options, 'HASH'))? %{$options} : ())):
	  undef);
}



1;
__END__

=pod

=head1 NAME

XML::XSP::TaglibFactory - A factory for dynamically loading and creating
XML::XSP::Taglib instances.

=head1 SYNOPSIS

  use XML::XSP::TaglibFactory;
  $taglib = XML::XSP::TaglibFactory->create('XML::XSP::Taglib::Core');

=head1 DESCRIPTION

This provides a factory helper class to assist in dynamically loading and
creating a XML::XSP::Taglib.


=head1 CONSTRUCTOR

=over 1

=item B<new>()

Construct a new taglib factory instance.

=back

=head1 PROCESSING METHODS

=over 1

=item B<create>($class,[\%options])

This method accepts a class name of the taglib to be loaded and an optional
hash of taglib dependant initialisation options and returns a taglib
instance.

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

L<XML::XSP>,L<XML::XSP::Taglib>

=cut

