package Aurora::Util::File;
use strict;

use Exporter;
use File::Basename;

use Aurora::Log;
use Aurora::Exception qw/:try/;

use vars qw/@ISA @EXPORT_OK/;

@ISA = qw/Exporter/;
@EXPORT_OK = qw/mkpath rmtree/;

# This utility method is based upon File::Path::mkpath
sub mkpath {
  my ($path, $mode) = @_;
  my $parent = File::Basename::dirname($path);
  unless (-d $parent or $path eq $parent) {
    mkpath($parent, $mode);
  }
  if(mkdir($path, $mode)) {
    my (@stat);
    @stat = stat($parent);
    chown $stat[4],$stat[5], $path;
  }
}

# This utility method is based upon File::Path::mkpath
sub rmtree {
  my($roots) = @_;
  my($root);

  foreach $root ((UNIVERSAL::isa($roots, 'ARRAY'))? @{$roots} : $roots) {
    my (@files, $rp);
    $root =~ s/\/\z//;
    (undef, undef, $rp) = lstat $root or return;
    $rp &= 07777;
    if ( -d _ ) {
      chmod(0777, $root) ||
	die "Can't make directory $root read+writeable: $!";
      if (opendir my $d, $root) {
	@files = readdir $d;
	closedir $d;
      }
      else {
	logwarn("Can't read $root: $!");
	@files = ();
      }
      @files = map("$root/$_", grep $_!~/^\.{1,2}\z/s,@files);
      rmtree(\@files);
      unless(rmdir $root) {
	chmod($rp, $root);
      }
    }
    else {
      chmod 0666, $root;
      unless (unlink $root) {
	logwarn("Can't unlink file $root: $!");
	chmod $rp, $root;
      }
    }
  }
}

1;
__END__

=pod

=head1 NAME

Aurora::Util::File - A collection of file utility functions used
within Aurora.

=head1 SYNOPSIS

  use Aurora::Util::File qw/mkpath rmpath/;

  mkpath($uri, $mode);
  rmpath($uri);


=head1 DESCRIPTION

Aurora::Util contains collection of file utility functions used within
Aurora.

=head1 FUNCTIONS

=over 2

=item B<mkpath>($uri, $mode)

The mkpath function provides an easy mechanism to recursively create a
directory tree. This function takes three parameters, the uri
corresponding path to create, the numeric mode to use when creating
the directory. Where possible,  ownership of the directory will be set
to that of the parent directory.

=item B<rmpath>($uri)

The rmpath function provides an easy mechanism to recursively delete a
directory tree. This function takes one parameter, that being the uri
corresponding to the directory tree to be removed.

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

L<Aurora>, L<Aurora::Util>
