package Aurora::Util;
use strict;
use Exporter;

use Aurora::Log;
use Aurora::Constants;

use vars qw/@ISA @EXPORT_OK/;

@ISA = qw/Exporter/;
@EXPORT_OK = qw/str2time str2size urlencode urldecode
                str2code evaluate str2encoding str2charset/;

use constant TIMES => {
		       'd' => 86400,
		       'h' => 3600,
		       'm' => 60,
		       's' => 1
		      };

use constant SIZES => {
		       'g' => 1073741824 ,
		       'm' => 1048576 ,
		       'k' => 1024 ,
		       'b' => 1
		      };

sub str2time {
  my ($str, $time) = @_;
  return unless defined $str;
  map {
    my ($count, $type) = (/(\d+)(\w?)/);
    $time += $count * (($type) ? TIMES->{lc $type} : 1);
  } ($str =~ /(\d+\w?)/g);
  return ((index $str, '-') == 0)? -$time : $time;
}

sub str2size {
  my ($str, $size) = @_;
  return unless defined $str;
  map {
    my ($count, $type) = (/(\d+)(\w?)/);
    $size += $count * (($type) ? SIZES->{lc $type} : 1);
  } ($str =~ /(\d+\w?)/g);
  return ((index $str, '-') == 0)? -$size : $size;
}

sub str2charset {
  my ($str, $from, $to) = @_;
  my ($code, $iconv);
  if($code = Text::Iconv->can('new')) {
    $iconv = $code->('Text::Iconv', $from, $to);
    return $iconv->convert($str);
  }
  logwarn('Charset conversion failed, Text::Iconv not loaded');
  return undef;
}

sub str2encoding {
  my ($str, $encoding) = @_;
  my ($code);
  if($code =  Compress::Zlib->can
     (($encoding && (lc $encoding eq 'gzip'))? 'memGzip' : 'memGunzip')) {
    return $code->($str);
  }
  logwarn('Encoding failed, Compress::Zlib not loaded');
  return undef;
}

sub urlencode {
  my ($toencode) = @_;
  $toencode =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
  return $toencode;
}

sub urldecode {
  my ($todecode) = @_;
  $todecode =~ tr/+/ /;
  $todecode =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
  return $todecode;
}

sub str2code {
  my ($str) = @_;
  return $str if !defined $str || $str =~ /^\d+$/;
  $str =~ tr/[a-z\-]/[A-Z\_]/;
  {
    no strict 'refs';
    return &{(join '::','Aurora::Constants', $str)}
      if Aurora::Constants->can($str);
  }
  return undef;
}

sub evaluate {
  my ($str, $context) = @_;

  if(defined $str) {
    my ($matches);

    $matches = (defined $context)? $context->matches : {};
    $str =~ s/\$\{?([\w|-|_|\d]+):(\d+)\}?/
      (join '',((exists $matches->{$1})? $matches->{$1}->[($2 - 1)] : ''))/eg;
  }
  return $str;
}




__END__

=pod

=head1 NAME

Aurora::Util - A collection of general purpose utility functions used
within Aurora.

=head1 SYNOPSIS

  use Aurora::Util qw/str2time str2size urlencode urldecode
                      str2code evaluate str2encoding str2charset/;
 
  $uri = evaluate($context, $str);

  $string = str2charset($string, 'utf-8','iso-8559-1');
  $string = str2encoding($string, 'gzip');

  $code = str2code('SERVER_ERROR');
  $bytes = str2size('2k');		      
  $seconds = str2time('2h');

  $url = urlencode($url);
  $url = urldecode($url);


=head1 DESCRIPTION

Aurora::Util contains collection of general purpose utility functions
used within Aurora.

=head1 FUNCTIONS

=over 8

=item B<evaluate>($string, $context)

This function evaluates any match variables within the supplied
string, based upon matches generated for the current context. This is
primarily used by component, where the parameter is dependant say on
the context URI, etc.

=item B<str2charset>($string, $from, $to)

This converts the string supplied from its current set to the newly
specified character set. This function will return undef unless
Text::Iconv support is enabled within Aurora.

=item B<str2encoding>($string, $encoding)

This converts the string supplied to the specified encoding. This
function will return undef unless Compress::Zlib support is enabled.

=item B<str2code>($string)

Converts a string representing the name of a constant in
Aurora::Constants into the internally used integer value. For example
the string 'SERVER_ERROR' will get converted to 500.

=item B<str2size>($string)

Converts a string representation of a file size to the size in
bytes. For example the string '1M' will get converted to 1048576.

=item B<urldecode>($uri)

This function url decodes the supplied string.

=item B<urlencode>($uri)

This function url encodes the supplied string.


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

L<Aurora>, L<Aurora::Constants>, L<Aurora::Util::File>
