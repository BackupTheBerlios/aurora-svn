package XML::SAX2Object::Inflect;
use strict;
use Exporter;

use vars qw/@ISA @EXPORT_OK/;

@ISA = qw/Exporter/;
@EXPORT_OK = qw/singular plural/;

my ($lingua);

sub BEGIN {
  eval { require "Lingua/EN/Inflect.pm" };
  $lingua = ($@)? 0 : 1;
}

sub singular {
  my ($word, $dictionary) = @_;
  my ($singular);

  if(UNIVERSAL::isa($dictionary, 'HASH')) {
    return $dictionary->{$word} if exists $dictionary->{$word};
  }

  SWITCH: {
      ($word =~ /^([A-Z].*)es$/) &&
	do { $singular = $1; last SWITCH;};
      ($word =~ /(.*)([cs]h|[zx])es$/i) &&
	do { $singular = "$1$2"; last SWITCH; };
      ($word =~ /(.*)(us)es$/i) &&
	do { $singular = "$1$2"; last SWITCH; };
      ($word =~ /(.*[eao])lves$/i) &&
	do { $singular = "$1lf"; last SWITCH; };
      ($word =~ /(.*[nlw])ives$/i) &&
	do { $singular = "$1ife"; last SWITCH; };
      ($word =~ /(.*)arves$/i) &&
	do { $singular = "$1arf"; last SWITCH; };
      ($word =~ /(.*)eaves$/i) &&
	do { $singular = "$1eaf"; last SWITCH; };
      ($word =~ /(.*[aeiou])ys$/i) &&
	do { $singular = "$1y"; last SWITCH; };
      ($word =~ /([A-Z].*y)s$/) &&
	do { $singular = $1; last SWITCH; };
      ($word =~ /(.*)ies$/i) &&
	do { $singular = "$1y"; last SWITCH; };
      ($word =~ /(.*)s$/i) &&
	do { $singular = $1; last SWITCH; };
    };
  return (defined $singular)? $singular : $word;
}



sub plural {
  my ($word, $dictionary) = @_;
  my ($plural);
  if(UNIVERSAL::isa($dictionary, 'HASH')) {
    return $dictionary->{$word} if exists $dictionary->{$word};
  }

  if($lingua) {
    $plural = Lingua::EN::Inflect::PL($word);
    return (length($plural) < length($word))? $word : $plural;
  }

 SWITCH: {
    ($word =~ /^([A-Z].*s)$/) && do { $plural = "$1es"; last SWITCH; };
    ($word =~ /(.*)([cs]h|[zx])$/i) && do { $plural = "$1$2es"; last SWITCH; };
    ($word =~ /(.*)(us)$/i) && do { $plural = "$1$2es"; last SWITCH; };
    ($word =~ /(.*[eao])lf$/i) && do { $plural = "$1lves"; last SWITCH; };
    ($word =~ /(.*[^d])eaf$/i) && do { $plural = "$1eaves"; last SWITCH; };
    ($word =~ /(.*[nlw])ife$/i) && do { $plural = "$1ives"; last SWITCH; };
    ($word =~ /(.*)arf$/i) && do { $plural = "$1arves"; last SWITCH; };
    ($word =~ /(.*)eaf$/i) && do { $plural = "$1eaves"; last SWITCH; };
    ($word =~ /(.*[aeiou])y$/i) && do { $plural = "$1ys"; last SWITCH; };
    ($word =~ /([A-Z].*y)$/) && do { $plural = "$1s"; last SWITCH; };
    ($word =~ /(.*)y$/i) && do { $plural = "$1ies"; last SWITCH; };
    ($word =~ /[aeiou]o$/i) && do { $plural = "${word}s"; last SWITCH; };
    ($word =~ /o$/i) && do { $plural = "${word}es"; last SWITCH; };
    ($word !~ /s$/i) && do { $plural = "${word}s"; last SWITCH;};
  };

  return (defined $plural)? $plural : $word;
}

1;
__END__

=pod

=head1 NAME

XML::SAX2Object::Inflect - A couple of helper subroutines that
converts singualar words to plural and vice versa.

=head1 SYNOPSIS

  use XML::SAX2Object::Inflect qw/singular plural/;

  $plural = plural($word);
  $singular = singular($plural);

  # or with user defined dictionary
  $dictionary = { leaves => 'leaf' }

  $plural = plural($word, $dictionary);
  $singular = singular($plural, $dictionary);



=head1 DESCRIPTION

This module provides a couple of exportable subroutines that
provide plural inflections and the reverese for a selection
of English words.

=head1 LICENCE & AUTHOR

This module is released under the Perl Artistic Licence and
may be redistributed under the same terms as perl itself.

Most of the contents of this module is derived from
Lingua::EN::Inflect.

(c)1997-2000, Damian Conway, All rights reserved.

(c)2002-2004 Darren Graves (darren@iterx.org), All rights reserved.

=head1 SEE ALSO

XML::SAX2Object & XML::SAX.

=cut
