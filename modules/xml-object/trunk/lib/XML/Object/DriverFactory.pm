package XML::Object::DriverFactory;
use strict;
use vars qw/@DRIVER %TYPEMAP/;

sub new { shift; }

sub create {
  my ($self, %options) = @_;
  my ($driver, $code);

  if(defined $options{Input}) {
    ($driver) =
      map { $TYPEMAP{$_} }
	grep { UNIVERSAL::isa($options{Input}, $_) } keys %TYPEMAP;
  }
  $driver ||= ($options{Driver} || $DRIVER[0]);
  return undef unless $driver;
  unless($code = $driver->can('new')) {
    eval {
      my ($file);
      $file = $driver;
      $file =~ s/::/\//g;
      require (join '',$file,'.pm');
      if($code = $driver->can('new')) {
	push @DRIVER, $driver;
      }
    };
    if($@) {
      warn (join '', 'Failed to load driver ',$driver, ': ', $@)
	if $XML::Object::DEBUG;
    }
  }
  return (($code)? $code->($driver): undef);
}

sub register {
  my ($self, %mappings) = @_;
  while (my ($class, $type) = (each %mappings)) {
    $TYPEMAP{$class} = $type;
  }
  return 1;
}

1;
