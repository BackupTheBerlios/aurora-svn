package Aurora::Resource;

use strict;

use Fcntl;
use FileHandle;
use HTTP::Request;
use LWP::UserAgent;

use Aurora::Server;
use Aurora::Log;
use Aurora::Exception qw/:try/;
use Aurora::Server;
use Aurora::Constants qw/:internal :response/;
use Aurora::Resource::RIB;


{
  sub fetch {
    my ($class, $uri, $options) = @_;
    my ($rib);

    unless($uri =~ /^(\w+:\/\/)/) {
      my ($base);
      $base = $options->{base} || Aurora::Server->base;
      $uri = (join '/', $base, $uri);
    }
    $uri =~ s/^(\w+:\/\/)?((\/|\A)\.*\/)/\//g;


    logdebug('Fetching RIB ', $uri);

  SWITCH:{
      ($uri =~ /^file:\/\// || $uri !~ /^\w+:\/\// ) && do {
	my ($file, @stat);
	$file = (index($uri, 'file://') != -1)? substr($uri,7) : $uri;
	$file = substr($file, 0, index($file, '#')) if index($file, '#') != -1;
	@stat = stat($file);
	if (scalar @stat) {
	  my ($type);
	  $rib = Aurora::Resource::RIB->new
	    (uri  => $uri,
	     type => {
		      'content-length' => $stat[7],
		      'last-modified'  => $stat[9],
		      'etag'           => (join '-',
					   sprintf('%lx',$stat[0]),
					   sprintf('%lx',$stat[1]))
		     });
	  last SWITCH;
	}
	throw Aurora::Exception::Event
	  (-event => NOT_FOUND,
	   -text  => (join '', 'File not found: ', $uri));
      };
      ($uri =~ m/^http(s)?:\/\//) && do {
	my ($agent, $request, $response);
	$agent = LWP::UserAgent->new();
	$agent->timeout(15);
	$request = HTTP::Request->new(HEAD => $uri);
	$response = $agent->request($request);
	if ($response->is_success) {
	  $rib = Aurora::Resource::RIB->new
	    (uri  => $uri,
	     type => $response->headers,
	     (($response->is_success && $response->content)?
	      (data => $response->content ) : ())
	    );
	  if(index($rib->type('content-type'),';') != -1) {
	    my ($type, $charset);
	    ($type, $charset) =  split /;/, $rib->type('content-type'), 2;
	    ($charset) = ($charset =~ /charset=([\w\-]+)/);
	    $rib->type('content-type' => $type);
	    $rib->type('charset' => $charset) if $charset;
	  }
	  last SWITCH;
	}
	throw Aurora::Exception::Event
	  (-event => NOT_FOUND,
	   -text  => 'File not found: ', $uri);
      };
      do {
	throw Aurora::Exception::Event
	  (-event => NOT_IMPLEMENTED,
	   -text => (join '','Schema for ', $uri, ' not supported'));
      };
    }
    return $rib;
  }

  sub object {
    my ($class, $uri, $options) = @_;
    my ($object);
    unless($uri =~/^(\w+:\/\/|\/)/) {
      my ($base);
      $base = $options->{base} || Aurora::Server->base;
      $uri = (join '/', $base, $uri);
    }
    $uri =~ s/^(\w+:\/\/)?((\/|\A)\.*\/)/\//g;


    logdebug('Fetching Object ', $uri);
  SWITCH:{
      ($uri =~ /^file:\/\// || $uri !~ /^\w+:\/\// ) && do {
	my ($file, @stat);
	$file = (index($uri, 'file://') != -1)? substr($uri,7) : $uri;
	$file = substr($file, 0, index($file, '#')) if index($file, '#') != -1;
	@stat = stat($file);
	if (scalar @stat) {
	  sysopen(FILE, $file,
		  O_RDONLY|O_BINARY) ||
		    throw Aurora::Exception::Event
		      (-event => SERVER_ERROR,
		       -text  => ("File read error ", $!));
	  sysread(FILE, $object, $stat[7]);
	  close FILE;
	  last SWITCH;
	}
	throw Aurora::Exception::Event
	  ( -event => NOT_FOUND,
	    -text  => ("File not found: ", $uri))
      };
      ($uri =~ m/^http(s)?:\/\//) && do {
	my ($agent, $request, $response);
	$agent = LWP::UserAgent->new();
	$agent->timeout(15);
	$request = HTTP::Request->new(GET => $uri);
	$request->header('Host', $request->uri->host);
	$response = $agent->request($request);
	if ($response->is_success) {
	  $object = $response->content;
	  last SWITCH;
	}
	throw Aurora::Exception::Event
	  ( -event => NOT_FOUND,
 	    -text  => 'File not found: ', $uri);
      };
      do {
	throw Aurora::Exception::Event
	  (-event => NOT_IMPLEMENTED,
	   -text => (join '','Schema for ', $uri, ' not supported'));
      };
    };
    return $object;
  }


  sub is_valid {
    my ($self, $rib) = @_;
    my ($uri);
    $uri = $rib->uri;
    unless($uri =~/^(\w+:\/\/|\/)/) {
      $uri = (join '/', Aurora::Server->base, $uri);
    }
    $uri =~ s/^(\w+:\/\/)?((\/|\A)\.*\/)/\//g;

    if($rib->expires &&
       (($rib->date + $rib->expires) > time())) {
      return 1;
    }

  SWITCH: {
      ($uri =~ /^file:\/\// || $uri !~ /^\w+:\/\// ) && do {
	my (@stat, $file);
	$file = (index($uri, 'file://') != -1)? substr($uri,7) : $uri;
	$file = substr($file, 0, index($file, '#')) if index($file, '#') != -1;
	@stat = stat($file);
	return 1 if scalar @stat && ($rib->version >= $stat[9]);
	last SWITCH;
      };
      ($uri =~ m/^http(s)?:\/\//) && do {
	my ($agent, $request, $response);
	$agent = LWP::UserAgent->new();
	$agent->timeout(15);
	$request = HTTP::Request->new(HEAD => $uri);
	$request->header('Host', $request->uri->host);
	$response = $agent->request($request);
	if ($response->is_success) {
	  return 1
	    if $rib->version >= $response->header('last-modified');
	}
	last SWITCH;
      };
      do {
	throw Aurora::Exception::Event
	  (-event => NOT_IMPLEMENTED,
	   -text => (join '', 'Schema for ', $uri, ' not supported'));
      };
    }
    return 0;
  }



}

1;
__END__

=pod

=head1 NAME

Aurora::Resource - A collection of functions to deal with the loading
of local and remote file resources.

=head1 SYNOPSIS

  use Aurora::Resource;

  $rib = Aurora::Resource->fetch('file://tmp/myfile.txt');
  if($rib->is_valid) {
    $data = $rib->object;
  }

  Aurora::Resource->is_valid($rib);

  $data = Aurora::Resource->object('file://tmp/myfile.txt');


=head1 DESCRIPTION

Aurora::Resource contains a collection of functions to deal with the
loading of local and remote resources, via a variety of protocols.

=head1 FUNCTIONS

=over 3

=item B<fetch>($uri,[\%options])

This function fetches the RIB (resource indentification block) for the
supplied URI. An optional base parameter can be supplied via the
options hash reference, to be used as a URI base when resolving
relative URIs.

=item B<is_valid>($rib)

This function checks to see if the underlying file refered to by the
RIB has expired since this RIB was instantiated.

=item B<object>($uri,[\%options])

This function fetches the contents of the file for the supplied
URI. An optional base parameter can be supplied via the options hash
reference, to be used as a URI base when resolving relative URIs.


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

L<Aurora>, L<Aurora::Resource::RIB>
