package Aurora::Context::Response;
use strict;

use HTTP::Date;
use HTTP::Response;
use HTTP::Headers;

use Aurora::Log;
use Aurora::Util qw/urlencode/;
use Aurora::Constants qw/:internal :response/;
use Aurora::Exception qw/:try/;
use Aurora::Context::Cookies;

use vars qw/@ISA $AUTOLOAD/;

@ISA = qw/HTTP::Response/;

use overload q/""/ => sub {
  my ($self) = @_;
  return $self->as_string;
};


require HTTP::Status;

sub new {
  my ($class, $headers, $self);
  $class = shift;
  $self = (ref $_[0] && UNIVERSAL::isa($_[0], 'HTTP::Response'))?  $_[0] :
    $class->SUPER::new(($_[0] || REQUEST_OK) ,
		       ($_[1] || undef),
		       ((ref $_[2] && UNIVERSAL::isa($_[2], 'HTTP::Headers'))?
			$_[2] : HTTP::Headers->new(%{$_[2]})));
  $self->{_content} = undef;
  $self->{_status} = DECLINED;
  $self->{_protocol} = "HTTP/1.1";
  $self->{_cookie} = {};
  return bless $self, $class;
}

sub status {
  my ($self, $code) = @_;
  $self->{_status} = $code if defined $code;
  return $self->{_status};
}

sub cookie {
  my ($self);
  $self = shift;
  my (@cookies);
  unless (exists $self->{_cookies}) {
    $self->{_cookies} = Aurora::Context::Cookies->new($self);
  }
  @cookies = $self->{_cookies}->cookie(@_);
  return (wantarray)? @cookies : $cookies[0];
}

sub header {
  my ($self);
  $self = shift;
  return ($self->SUPER::header(@_) || undef);
}

# Modifed version of HTTP::Response::as_string
sub as_string {
  my $self = shift;
  my @result;
  my $code = $self->code;
  my $status_message = HTTP::Status::status_message($code) || "Unknown code";
  my $message = $self->message || "";
  my $status_line = "$code";
  my $proto = $self->protocol;
  $status_line = "$proto $status_line" if $proto;
  $status_line .= " ($status_message)" if $status_message ne $message;
  $status_line .= " $message";
  push(@result, $status_line);
  push(@result, $self->headers_as_string("\x0D\x0A"));

  # check if content exists?
  if(my $content = $self->content) {
    $content = $content->as_string
      (charset          => $self->header('charset'),
       content_encoding => $self->header('content-encoding'),
       content_type     => $self->header('content-type'),
       mime_type        => $self->header('mime-type')) ;
    push @result, $content;
  }

  return join("\x0D\x0A", @result, "");
}

# Modifed version of HTTP::Response::headers_as_string
sub headers_as_string {
  my($self, $endl) = @_;
  my (@results, $date);
  $date = time();
  $endl ||= "\n";

  push @results, (join '', 'Date: ',HTTP::Date::time2str($date));
  $self->{_headers}->scan
    (sub {
       my($field, $val) = @_;
       if ($val =~ /\n/) {
	 # must handle header values with embedded newlines with care
	 $val =~ s/\s+$//;          # trailing newlines and space must go
	 $val =~ s/\n\n+/\n/g;      # no empty lines
	 $val =~ s/\n([^\040\t])/\n $1/g;  # intial space for continuation
	 $val =~ s/\n/$endl/g;      # substitute with requested line ending
       }
     SWITCH: {
	 ($field =~ /charset|date|mime-type/ix) && return;
	 ($field !~ /content-type|last-modified|expires/ix)
	   && last SWITCH;
	 (lc $field eq 'content-type') && do {
	   my ($mime, $charset);
	   if ($mime = $self->header('mime-type')) {
	     $val = (join '', $mime,
		     (((index $val, ';') > 0)?
		      (substr($val,(index $val, ';'))): ()));
	   }
	   if((index($val, 'charset=') == -1) &&
	      ($charset = $self->header('charset'))) {
	     $val .= "; charset=$charset";
	   }
	   last SWITCH;
	  };
	 (lc $field eq 'last-modified') && do {
	   $val = HTTP::Date::time2str($val);
	   last SWITCH;
	 };
	 (lc $field eq 'expires') && do {
	   return if $val < 0;
	   $val = HTTP::Date::time2str($date + $val);
	   last SWITCH;
	 };
       };
       push(@results, "$field: $val");
     });

  if(exists $self->{_cookies}) {
    $self->{_cookies}->scan(sub {
        my ($version, $key, $value, $path, $domain, $port,
	    $path_spec, $secure, $expires, $discard, $rest) = @_;
	my ($cookie, @values);
	push(@values,"domain=$domain") if $domain ;
	push(@values,"path=$path") if $path ;
	push(@values,
	     (join '',"expires=",HTTP::Date::time2str($expires)))
	  if defined $expires;
	push(@values,"secure") if $secure;

	$cookie = "Set-Cookie: ";
	$cookie .= (join "=", urlencode($key),urlencode($value));
	push @results, (join "; ",$cookie, @values);
      });
  }
  return join($endl, @results, '');
}


sub content {
  my ($self, $content, $options) = @_;
  if(defined $content) {
    unless(UNIVERSAL::isa($content,
			  'Aurora::Context::Response::ContentHandler')) {
      $content = Aurora::Context::Response::ContentHandler->new
	($content, $options);
    }
    $self->{_content} = $content;
  }
  return $self->{_content};
}


sub add_content { throw Aurora::Exception("Method Not implemented") }

sub content_ref { throw Aurora::Exception("Method Not implemented") }


package Aurora::Context::Response::ContentHandler;
use strict;

use Aurora::Log;
use Aurora::Exception qw/:try/;
use vars qw/%TYPEMAP/;

sub new {
  my ($class, $data, $options) = @_;
  $options ||= {};
  if ($class eq __PACKAGE__) {
    foreach my $class (keys %TYPEMAP) {
      if(($class eq 'SCALAR')? (!ref $data) : UNIVERSAL::isa($data, $class)) {
	my ($instance, $code);
	$instance = (join '::', __PACKAGE__, $TYPEMAP{$class});
	if ($code = $instance->can('new')) {
	  return $code->($instance, $data, $options);
	}
      }
    }
    throw Aurora::Exception("Invalid data type");
  }
  return bless {
		charset    => ($options->{charset}   || 'utf-8'),
		encoding   => ($options->{content_encoding}  || ''),
		content_type  => ($options->{content_type} || 'text/xml'),
		data       => $data,
	       }, $class;
}

sub register {
  my ($self, %mappings) = @_;
  while (my ($class, $type) = (each %mappings)) {
    $TYPEMAP{$class} = $type;
  }
  return 1;
}

sub as_string { throw Aurora::Exception("Abstract Class") }

sub charset   { throw Aurora::Exception("Abstract Class") }

sub content_encoding  { throw Aurora::Exception("Abstract Class") }

sub content_type { throw Aurora::Exception("Abstract Class") }

sub data {
  my ($self) = @_;
  return $self->{data};
}

sub type {
  my ($self) = @_;
  return substr(ref $self, 1+rindex(ref $self,':'));
}

sub convert {
  my ($self, $type) = @_;
  my ($class, $code);
  return $self if !defined $type || $self->type eq $type;
  $class = (join '::', __PACKAGE__, $type);
  if ($code = $class->can('new')) {
    return $code->($class,
		   $self->as_string(encoding => undef),
		   {
		    charset   => $self->{charset},
		    content_type => $self->{content_type}
		   }
		  );
  }
  logwarn("Can't convert data to ", $type);
  return undef;
}



package Aurora::Context::Response::ContentHandler::String;
use strict;

use Aurora::Log;
use Aurora::Util qw/str2encoding str2charset/;

use overload '""' => \&as_string;

use vars qw/@ISA/;
@ISA = qw/Aurora::Context::Response::ContentHandler/;


Aurora::Context::Response::ContentHandler->register
  ('SCALAR' => 'String');

sub new {
  my ($class, $data, $options) = @_;
  my ($self);
  $self = $class->SUPER::new($data, $options);
  return $self;
}

sub as_string {
  my ($self, $string, %options);

  $self = shift;
  {
    no warnings;
    %options = (scalar @_)? @_ : ();
  }
  $string = $self->{data};


  if($options{charset} && (lc $options{charset} ne $self->{charset})) {
    $string = str2charset($string, $self->{charset}, $options{charset});
  }
  if(defined $options{content_encoding} &&
     (lc $options{content_encoding} ne $self->{encoding})) {
    $string = str2encoding($string, $options{content_encoding});
  }
  return $string;
}

sub charset {
  my ($self, $charset) = @_;
  if(defined $charset && (lc $charset ne $self->{charset})) {
    my ($data);
    $data = str2charset($self->{data}, $self->{charset}, $charset);
    if($data) {
      $self->{data} = $data;
      $self->{charset} = $charset;
    }
  }
  return $self->{charset};
}

sub content_encoding {
  my ($self, $encoding) = @_;
  if(defined $encoding && (lc $encoding ne $self->{encoding})) {
    my ($data);
    $data = str2encoding($self->{data}, $encoding);
    if($data) {
      $self->{data} = $data;
      $self->{encoding} = $encoding;
    }
  }
  return $self->{encoding};
}

sub content_type {
  my ($self, $content_type) = @_;
  if (defined $content_type) {
    $self->{content_type} = $content_type;
  }
  return $self->{content_type};
}


package Aurora::Context::Response::ContentHandler::LibXML;
use strict;

use XML::LibXML;
use XML::LibXSLT;

use Aurora::Log;
use Aurora::Util qw/str2encoding/;
use overload '""' => \&as_string;

use vars qw/@ISA/;
@ISA = qw/Aurora::Context::Response::ContentHandler/;


{
  my ($parser, $processor);
  $parser = XML::LibXML->new;
  $processor = XML::LibXSLT->new;
  Aurora::Context::Response::ContentHandler->register
      ('XML::LibXML::Node' => 'LibXML');

  sub new {
    my ($class, $data, $options) = @_;
    my ($self, $dom);
    $data = str2encoding($data) if $options->{encoding};
    $dom = ((UNIVERSAL::isa($data, 'XML::LibXML::Node'))?
	    $data :
	    ((exists $options->{content_type} &&
	      $options->{content_type} eq 'text/html')?
	     $parser->parse_html_string($data) :
	     $parser->parse_string($data)));
    $self = $class->SUPER::new($dom);
    return $self;
  }

  sub as_string {
    my ($self, $string, %options);

    $self = shift;
    {
      no warnings;
      %options = (scalar @_)? @_ : ();
    }

    if(($options{charset} && $options{charset} ne $self->{charset}) ||
       ($options{content_type} &&
	$options{content_type} ne $self->{content_type})) {
      my ($stylesheet, $document, $content_type, $mime_type, $charset, $method);
      $content_type = ($options{content_type} || $self->{content_type});
      $mime_type = ($options{mime_type} || $content_type);
      $charset = ($options{charset} || $self->{charset});
      $method = (($content_type eq 'text/xml')? 'xml' :
		 ($content_type eq 'text/html')? 'html' : 'text');
      $stylesheet = $parser->parse_string(<< "XML");
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="$method" media-type="$mime_type" encoding="$charset"/>
<xsl:template match="*">
<xsl:copy>
<xsl:copy-of select="@*"/>
<xsl:apply-templates/>
</xsl:copy>
</xsl:template>
</xsl:stylesheet>
XML

      $stylesheet = $processor->parse_stylesheet($stylesheet);
      $document = $stylesheet->transform($self->{data});
      $string = $stylesheet->output_string($document);
    }
    else {
      $string = $self->{data}->toString;
    }

    if(defined $options{content_encoding} &&
       (lc $options{content_encoding} ne $self->{content_encoding})) {
      $string = str2encoding($string, $options{content_encoding});
    }
    return $string;
  }

  sub charset {
    my ($self, $value) = @_;
    if (defined $value) {
      logwarn("Charset conversion failed, option not supported.");
    }
    return $self->{charset};
  }

  sub content_encoding {
    my ($self, $value) = @_;
    if (defined $value) {
      logwarn("Encoding failed, option not supported.");
    }
    return $self->{encoding};
  }

  sub content_type {
    my ($self, $value) = @_;
    if (defined $value) {
      logwarn("Can't set content type, option not supported.");
    }
    return $self->{content_type};
  }
}

1;

__END__

=pod

=head1 NAME

Aurora::Context::Response - the response object for the current
process.

=head1 SYNOPSIS

  use Aurora::Context::Response;
  use Aurora::Constants qw/:internal/;

  $response = Aurora::Context::Response->new(200);

  $response->cookie(name => 'session-id', value=> '1');
  $response->headers('content-type' => 'text/plain');
  $response->status(OK);

  $content = $response->content;
  $response->content($context,{content_type => 'text/xml'})


=head1 DESCRIPTION

This object provides a encapsulated HTTP style response, containing
the response information, resultant from the current process.

=head1 CONSTRUCTOR

=over 2

=item B<new>($response)

Construct a new Aurora response object, where response is a
HTTP::Response object.

=item  B<new>([$code[, [$message], [$header, [$content]])

Construct a new Aurora response object, where response code, and
optional message is a string, while the headers should be a reference
to a valid HTTP::Headers object.

=back

=head1 ACCESSOR METHODS

=over 8

=item B<code>()

With no name specified, this method will return the current response
HTTP code, otherwise it will set the code to the value supplied.

=item B<cookie>($name)

In list context, this will return all of the cookie objects for the
specified name, while in scalar context it will return just the first
value.

=item B<cookie>(%options)

The method will add a new cookie to the response object from the
options supplied. Valid options are name (mandatory), value
(mandatory), path (defaults to '/'), domain, port, secure and expires.

=item B<content>([$object], [\%options])

With no parameters, the content method returns the content object for
the current response. The content of the response can  be set by
suppling a raw data object and an option hash containing the
content_type, charset and encoding of the data, if known (otherwise
default values are assumed).

=item B<header>($name)

In list context, this method will return a list of the values set for
specified HTTP Header name, while in scalar context a string will be
returned with the values concatenated by the comma seperator.

=item B<header>(%headers)

The method takes the hash containing the header name/value pairs and
sets the corresponding HTTP Headers of the response object for each
one in turn.

=item B<status>([$status])

With no name specified, this method will return the current response
status, otherwise it will set the status to the value supplied. The
status controls what further processing should be done on the
response.

=back

=head1 PROCESSING METHODS

=over 2

=item B<as_string>([%options])

This returns a string representation of the Response object, in the
form of a HTTP Response. Optional content_type, charset and encoding
parameters can be specified to control the output formatting of the
outputs body.

=item B<headers_as_string>()

The returns a string representation of the Response's HTTP headers.

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

L<Aurora>, L<Aurora::Constants>, L<Aurora::Context>

