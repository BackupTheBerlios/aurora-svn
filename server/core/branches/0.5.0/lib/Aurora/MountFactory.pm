package Aurora::MountFactory;

use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Mount::Pipeline;
use Aurora::Mount::Redirect;
#use Aurora::Mount::Service;


use constant TYPES      => [qw/Redirect Pipeline/];
use constant COMPONENTS => [qw/Event Matcher Plugin/];
use constant PIPELINE   => [qw/Producer Transformer Serializer/];

{
  my ($ID);

  sub new {
    my ($class, %options) = @_;
    return bless {},$class;
  }

  sub create {
    my ($self, $mount, $options) = @_;
    my ($instance);
    try {
      my ($sitemap, $type, $class, $mnt_options, $errors);
      $sitemap = $options->{sitemap} ||
	throw Aurora::Exception::Error
	  ('Mounts must be created for a specified sitemap');
      ($type) = (grep {$mount->{type} eq lc $_ } @{(TYPES)});
      $type ||
	throw Aurora::Exception::Error
	((join '', 'Unknown mount type ', $mount->{type}));
      $class = (join '::','Aurora::Mount', $type);
      logdebug("Creating ", $class);
      # expand all components and pass to mount to create!!!
      # all components should be closures with correct parameters!!!
      map {
	my ($key, $value, $prefix, $name, $component);
	$key = $_;
	($prefix, $name) = (split /:/, $key ,2);
      SWITCH: {
	  ($key eq lc $type) && do {
	    my (@names);
	    @names = (
		      (map {
			my $name = lc $_;
			(exists $mount->{$key}->{$name})? ($name) : ();
		      } @{(PIPELINE)}),
		      (grep {
			my $name = lc $_;
			(grep {$name eq lc $_ } @{(PIPELINE)})? 0 : 1;
		      } keys %{$mount->{$key}}));
	    for(my $i = 0; $i < scalar @names; $i++) {
	      my ($values);
	      $name = $names[$i]; # masks previous value
	      if(ref $mount->{$key}->{$name}) {
		$values = ((ref $mount->{$key}->{$name} eq "ARRAY") ?
			   $mount->{$key}->{$name} :
			   [$mount->{$key}->{$name}]);
		for(my $j = 0; $j < scalar @{$values}; $j++){
		  my ($data);
		  $data = $values->[$j];
		  $data->{id} = $i+$j+1;
		  logdebug("Adding pipeline ",$name," ", $data->{type});
		  if(exists $data->{type} &&
		     (grep {$name eq lc $_ } @{(PIPELINE)})){
		    # should declare this somewhere else!!!
		    $component = $sitemap->component($data->{type});
		    ($component)?
		      (push @{$mnt_options->{$name}},
		       $component->closure($data)) :
			push @{$errors}, $data->{type};
		  }
		  else {
		    $mnt_options->{$name} = $data;
		  }
		}
	      }
#	      elsif($name eq 'type') {
#		$component = $sitemap->component($mount->{$key}->{$name});
#		# only cope with one service at a time - atm
#		($component) ?
#		  $mnt_options->{$key} =  $component->closure($mount) :
#		    push @{$errors}, $mount->{$key}->{$name};
#	      }
	      else {
		$mnt_options->{$name} = $mount->{$key}->{$name};
	      }
	    };
	    last SWITCH;
	  };
	  ((grep {$prefix eq lc $_ } @{(COMPONENTS)}) &&
	   ($component = $sitemap->component($name))) && do {
	     logdebug("Adding ",$prefix, " ", $name);
	     push @{$mnt_options->{$prefix}},
	       $component->closure($mount->{$key});
	     last SWITCH;
	   };
	  (defined $name) && do {
	    push @{$errors}, $name;
	  };
	};
      } keys %{$mount};

      if($errors && scalar @{$errors}) {
	throw Aurora::Exception::Error((join '',"Components ",
					(join ',',@{$errors}), " not found"));
      }
      else {
	my ($code);
	if($code = $class->can('new')) {
	  $instance = $code->($class,
			      id => (join '', 'Mount-', ++$ID),
			      name => $mount->{name},
			      %{$mnt_options})
	}
	throw Aurora::Exception::Error("Can't create mount instance")
	  unless $instance;
	logdebug("Done");
      }
    }
    otherwise {
      logwarn(shift);
      logwarn("Mount creation failed.");
    };
    return $instance;
  }
}

1;
__END__

=pod

=head1 NAME

Aurora::MountFactory - A factory for dynamically loading and creating
Aurora Mount instances.

=head1 SYNOPSIS

  use Aurora::MountFactory;
  $factory = Aurora::MountFactory->new;

  $mount = $factory->create
  ({type => 'redirect', 
    matcher:uri => '.*',
    redirect => {uri => "$uri:1"}}, 
   {sitemap => $sitemap});

=head1 DESCRIPTION

This class provides a helper factory to assist in dynamically loading
and creating of Aurora Mounts.

=head1 CONSTRUCTOR

=over 1

=item B<new>()

Constructs a new mount factory instance.

=back

=head1 PROCESSING METHODS

=over 1


=item B<create>(\%mount, \%options)

This method constructs a new mount instance based upon a hash
reference containing the mount parameters and the options hash
reference which contains a pointer to the sitemap which this mount is
assigned to.

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

L<Aurora>, L<Aurora::Mount>
