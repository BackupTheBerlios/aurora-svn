package Aurora::Mount::Pipeline;
use strict;

use Time::HiRes;

use Aurora::Server;
use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Mount;

use vars qw/@ISA/;
@ISA = qw/Aurora::Mount/;


sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = $class->SUPER::new(%options);
  $options{producer} ||
    throw Aurora::Exception("No producer specified");
  $options{serializer} ||
    throw Aurora::Exception("No serializer specified");

  $self->{pipeline} = [
		       ((UNIVERSAL::isa($options{producer},'ARRAY'))?
			@{$options{producer}} :
			(ref $options{producer})? $options{producer} : ()),
		       ((UNIVERSAL::isa($options{transformer},'ARRAY'))?
			@{$options{transformer}} :
			(ref $options{transformer})? $options{transformer} : ()),
		       ((UNIVERSAL::isa($options{serializer},'ARRAY'))?
			@{$options{serializer}} :
			(ref $options{serializer})? $options{serializer} : ()),
		      ];
  return $self;
}

sub run {
  my ($self, $context, $options) = @_;
  my (@pipeline, $status, $cache, $oid);

  @pipeline = @{$self->{pipeline}};
  $status = DECLINED;

  map { &$_->run($context) } @{$self->{plugin}};

  if($cache = Aurora::Server->cache) {
    my ($length);
    $oid = $context->id;
    $cache->lock(READ => $oid);
    try {
    COMPONENT: for(my $i = scalar(@pipeline); $i > 0; $i--) {
	my ($component, $oib, $object);
	$component = &{$pipeline[$i - 1]};
	next unless $component->cache;
	$oib = $cache->fetch(join ':', $oid, $i);
	if(defined $oib) {
	  my (@dependancy);
	  @dependancy = $oib->dependancy;
	DEPENDANCY: for(my $j = (scalar(@dependancy) - 1); $j >= 0; $j--) {
	    !(defined $dependancy[$j]->[1]) && do {
	      next DEPENDANCY;
	    };
	    (ref $dependancy[$j]->[1] eq "ARRAY") && do {
	      $status = &{$pipeline[$j]}->is_valid($context, $oib);
	      next DEPENDANCY if $status == DECLINED;
	      last;
	    };
	    do {
	      my (@coibs, @processed, $coib);
	      @coibs = $cache->fetch($dependancy[$j]->[1]);
	    COIB: while ($coib = shift @coibs) {
		my (@subdependancy);
		@subdependancy = $coib->dependancy;
		push @processed, $coib;
	      SUBDEPENDANCY:
		for(my $k = (scalar(@subdependancy) - 1); $k >= 0; $k--) {
		  !(defined $subdependancy[$k]->[1]) && do {
		    next SUBDEPENDANCY;
		  };
		  (ref $subdependancy[$k]->[1] eq "ARRAY") && do {
		    $status = &{$pipeline[$k]}->is_valid($context, $coib);
		    next SUBDEPENDANCY if $status == DECLINED;
		    last COIB;
		  };
		  do {
		    if($coib = $cache->fetch($subdependancy[$k]->[1])){
		      push @coibs, $coib;
		      next COIB;
		    }
		    $status = DELETE;
		  }
		};
	      }
	    STATUS: {
		($status == OK || $status == DECLINED) && do {
		  my ($write);
		  #lazy refresh
		  map {
		    if($_->expires &&
		       ($_->date + $_->expires) > time()) {
		      if($write || ($write =  $cache->lock(WRITE => $oid))){
			$_->date(time());
			$cache->store($_);
		      }
		    }
		  } @processed;
		  last DEPENDANCY
		};
		($status == DELETE) && do {
		  if($cache->lock(WRITE => $oid)) {
		    map { $cache->remove($_->id) } @processed;
		    last DEPENDANCY;
		  }
		};
	      }
	      $status = DELETE;
	      last DEPENDANCY;
	    };
	  };
	STATUS: {
	    ($status == OK || $status == DECLINED) && do {
	      # lazy refresh
	      if($oib->expires &&
		 ($oib->date + $oib->expires) > time()){
		if($cache->lock(WRITE => $oid)){
		  $oib->date(time());
		  $cache->store($oib);
		}
	      }

	      $context->reconsecrate($oib, $oib->object);
	      if(scalar(@pipeline) == $i) {
		$status = OK;
		$context->response->status($status)
	      }
	      splice @pipeline, 0, $i;
	      last COMPONENT;
	    };
	    ($status == DELETE) && do {
	      if($cache->lock(WRITE => $oid)) {
		$cache->remove($oib->id);
		next COMPONENT;
	      }
	      $cache->unlock;
	      while(!$cache->lock(WRITE => $oid)) {
		Time::HiRes::sleep(0.05);
	      }
	      redo COMPONENT;
	    };
	    do {
	      throw Aurora::Exception("Invalid cache dependancy status");
	    };
	  };
	}
	else {
	  unless($cache->lock(WRITE => $oid)) {
	    $cache->unlock;
	    while(!$cache->lock(WRITE => $oid)) {
	      Time::HiRes::sleep(0.05);
	      redo COMPONENT;
	    }
	  }
	}
      }
    }
    otherwise {
      my ($error);
      $error = shift;
      $cache->unlock;
      throw $error;
    };
  }

  if(scalar(@pipeline)) {
    logdebug('Running pipeline');
    try {
      map {
	my ($store, $component);
	$component = &$_;
	$context->dependancy($component);
	($status, $store) = $component->run($context);
      SWITCH: {
	  ($status == OK || $status == DONE) && do {
	    if($cache && $store) {
	      my ($oib, $object);
	      ($oib, $object) = $context->consecrate;
	      $cache->store($oib, $object);
	      $cache->unlock;
	    }
	    return $status;
	  };
	  ($status == DECLINED) && do {
	    if($cache && $store) {
	      my ($oib, $object);
	      ($oib, $object) = $context->consecrate;
	      $cache->store($oib, $object);
	    }
	    last SWITCH;
	  };
	  do {
	    throw Aurora::Exception::Event
	      ( -event => $status,
		-text  => 'Pipeline error');
	  };
	};
      } @pipeline;

    }
    otherwise {
      my ($error);
      $error = shift;
      $cache->unlock if $cache;
      throw $error;
    };
  }
  $cache->unlock if $cache;
  return (defined $status)? $status : $context->response->status;
}
1;


__END__

=pod

=head1 NAME

Aurora::Mount::Pipeline - A pipeline Aurora mount.

=head1 SYNOPSIS

  <sitemap
    xmlns="http://iterx.org/aurora/sitemap/1.0"
    xmlns:matcher="http://iterx.org/aurora/sitemap/1.0/matcher">
    <mounts>
      <mount type="pipeline" matcher:uri="^(.*)">
        <pipeline>
	  <producer type="file"/>
          <transformer type="xslt"/>
	  <serializer type="html"/>
        </pipeline>
      </mount>
    </mounts>
  </sitemap>


=head1 DESCRIPTION

The pipeline mount provides an XML pipeline, that describes how the
source XML file should be transformed, before being returned as the
response.

When specifying a pipeline mount within a sitemap, it can contain:

=over 2

=item * 

One or more plugin declarations

=item * 

A pipeline declaration containing one producer, zero or more
transformers and one serializer component declarations.

=back

=head1 TAGS

=over 1

=item B<<pipeline>>

The pipeline tag sets out the stages within the pipeline that source
XML should processed by. The pipeline tag, can take the following
elements:

=over 3

=item * B<<producer>>

Every pipeline must specify a producer component. This component is
responsible for creating the source XML document for the pipeline.

=item * B<<transformer>>

A pipeline can zero or more different transformer components, with
which the current XML document can be manipulated and altered.

=item * B<<serializer>>

Every pipeline must specify a serializer component. This component is
responsible for serializing the resultant document, to its native
format.

=back

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

L<Aurora>, L<Aurora::MountFactory>, L<Aurora::Mount>
