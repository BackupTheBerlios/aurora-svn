package XML::XSP::Taglib::ESQL;
use strict;

use DBI;

use XML::XSP;
use XML::XSP::Taglib;

use vars qw/@ISA $NS $VERSION/;

@ISA = qw/XML::XSP::Taglib/;
$NS = 'http://apache.org/xsp/SQL/v2';
$VERSION = '0.2.1';

sub new {
  my ($class, %options) = @_;
  my ($self);
  $self = bless {
		}, $class;
  return $self;
}


sub driver {
  my ($self, %options) = @_;
  my ($dsn, $dbh);
  $dsn = (join '', 'dbi:', $options{driver},
	  ((defined $options{dburl})? (':',$options{dburl}): ''));
  $dbh = DBI->connect_cached($dsn,
			     $options{username},
			     $options{password},
			     {
			      PrintError  => 0,
			      RaiseError  => 0
			     });
  # should throw exception here!!
  return XML::XSP::Taglib::ESQL::Driver->new($dbh);
}

package XML::XSP::Taglib::ESQL::Driver;
use strict;

sub new {
  my ($class, $dbh) = @_;
  return bless { dbh => $dbh}, $class;
}

sub query {
  my ($self, $query) = @_;
  my ($sth);
  $sth = $self->{dbh}->prepare_cached($query);
  return XML::XSP::Taglib::ESQL::Query->new(sth => $sth, dbh => $self->{dbh});
}


package XML::XSP::Taglib::ESQL::Query;
use strict;

sub new {
  my ($class, %options) = @_;
  return bless {
		count   => 0,
		pos     => -1,
		names   => {},
		options => undef,
		rows    => [],
		_sth    => $options{sth},
		_dbh    => $options{dbh}
	       }, $class;
}

sub execute {
  my ($self, $bind, $options) = @_;
  my ($rv, $count);
  $bind ||= [];
  # if count != 0 then already running!!!
  if($options->{'skip-rows'} && $options->{'max-rows'}) {
    # adjust window to fit row!
    $options->{'skip-rows'} = ($options->{'skip-rows'} -
			       $options->{'skip-rows'} %
			       $options->{'max-rows'});
  }
  $self->{options} = $options;
  $rv = $self->{_sth}->execute(@{$bind});
  map { $self->{names}->{$_} = $count++ } @{$self->{_sth}->{NAME_lc}};
  return $rv;
}


sub execute_update {
  my ($self, $bind, $options) = @_;
  $bind ||= [];
  $self->{options} = $options;
  $self->{_sth}->execute(@{$bind});
  $self->{count} = $self->{_sth}->rows;
  print STDERR "-->",$self->{_sth}->rows,"\n";
  return $self->{count};
}

sub commit {
  my ($self) = @_;
  return 0 unless defined $self->{_dbh};
  return ($self->{_dbh}->{AutoCommit})? 1 :  $self->{_dbh}->commit;
}

sub rollback {
  my ($self) = @_;
  return 0 unless defined $self->{_dbh};
  return ($self->{_dbh}->{AutoCommit})? 0 :  $self->{_dbh}->rollback;
}

sub finish {
  my ($self) = @_;
  $self->{count} = 0;
  $self->{pos}   = -1;
  $self->{names} = {};
  $self->{rows}  = [];
  $self->{options} = undef;
  $self->{_sth}->finish if defined $self->{_sth};
}

sub prev_row {
  my ($self) = @_;
  my ($row);
  $row = ($self->{rows}->[$self->{pos} - 1 ])? $self->{rows}->[$self->{pos} - 1] :
     undef;
  if($row) {
    $self->{count}--;
    $self->{pos}--;
  }
  return $row;
}

sub rewind {
  my ($self) = @_;
  my ($count);
  if($self->{pos} != -1) {
    $self->{count} = $self->{count} - (1 + $self->{pos});
    $self->{pos} = -1;
  }
  return;
}

sub next_row {
  my ($self) = @_;
  my ($row);

  if($self->{options}->{'skip-rows'}) {
    while($self->{options}->{'skip-rows'} > $self->{count}) {
      return undef unless $self->{_sth}->fetchrow_arrayref;
      $self->{count}++;
    }
    $self->{options}->{'skip-rows'} = 0;
  }
  elsif($self->{options}->{'max-rows'}){
    return undef unless (1 + $self->{pos}) < $self->{options}->{'max-rows'};
  }
  if($self->{rows}->[1 + $self->{pos}]) {
    $row = $self->{rows}->[1 + $self->{pos}];
  }
  else {
    $row = $self->{_sth}->fetchrow_arrayref;
    unless($row) {
      # hmmm seems like postgres driver has some kind of automatic
      # rewind
      $self->{options}->{'max-rows'} = 1 + $self->{pos};
      return undef;
    }
    @{$self->{rows}->[1 + $self->{pos}]} = @{$row};
  }
  $self->{count}++;
  $self->{pos}++;
  return $row;
};

sub get_row_position {
  my ($self) = @_;
  return $self->{count};
}

sub get_column {
  my ($self, $column) = @_;
  my ($col);
  $col = ($column =~/^\d+$/)? $column : $self->{names}->{lc $column};
  return (defined $col)? $self->{rows}->[$self->{pos}]->[$col] : '';
}

sub get_column_type {
  my ($self, $column) = @_;
  my ($col);
  $col = ($column =~/^\d+$/)? $column : $self->{names}->{$column};
  return (!defined $col)?  undef :
    $self->{_dbh}->type_info($self->{_sth}->{TYPE}->[$col])->{TYPE_NAME};
}

sub get_columns {
  my ($self, $column) = @_;
  my ($array);
  $array = [];
  map {$array->[$self->{names}->{$_}] = $_} keys %{$self->{names}};
  return (wantarray)? @{$array} : $array ;
}

=pod

=head1 NAME

XML::XSP::Taglib::ESQL - An Extended SQL taglib

=head1 SYNOPSIS

  use XML::XSP;
  $xsp = XML::XSP->new(taglibs => ['XML::XSP::Taglib::ESQL']);

=head1 EXAMPLE

<?xml version="1.0"?>
<xsp:page language="perl"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:esql="http://apache.org/xsp/SQL/v2"
  xmlns:param="http://iterx.org/xsp/param/v1">

  <esql:connection>
  <esql:driver>mysql</esql:driver>
  <esql:dburl>host=localhost;database=xml</esql:dburl>
  <esql:username></esql:username>
  <esql:password></esql:password>
  <esql:execute-query>
    <esql:query>
    select name, street from customers where companyid=
    <esql:parameter><param:id/></esql:parameter>
    </esql:query>
    <esql:max-rows>10</esql:max-rows>
    <esql:results>
     <customers>
      <esql:row-results>
        <customer>
          <name><esql:get-string column="name" /></name>
          <street><esql:get-string column="street" /></street>
        <customer>
      </esql:row-results>
     </customers>
    </esql:results>
    <esql:no-results>
      <error>No Customers Found!</error>
    </esql:no-results>
  </esql:execute-query>
  </esql:connection>
</xsp:page>


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

XML::XSP

=cut

1;

package XML::XSP::Taglib::ESQL;
__DATA__
<?xml version="1.0"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsp="http://apache.org/xsp/core/v1"
  xmlns:esql="http://apache.org/xsp/SQL/v2"
  version="1.0">


  <xsl:template match="esql:connection">
    <xsp:logic>
      my ($esql, $driver, $db, $level, @queries);
      $esql = $self-&gt;taglib('http://apache.org/xsp/SQL/v2');
      <xsl:apply-templates mode="code"/>
    </xsp:logic>
  </xsl:template>

  <xsl:template match="esql:connection//esql:connection" mode="code">
     {
      my ($driver, $db);
      $level = ++$level;
      <xsl:apply-templates mode="code"/>
     }
  </xsl:template>

  <xsl:template match="esql:driver|esql:dburl|esql:username|esql:password" mode="code">
  $db-&gt;{<xsl:value-of select="local-name()"/>} =
  <xsl:call-template name="as-expr">
  <xsl:with-param name="node" select="current()"/>
  </xsl:call-template>;
  </xsl:template>

  <xsl:template match="esql:execute-query" mode="code">
    $driver = $esql-&gt;driver(%{$db});
    {
      my ($query, $parameters, @bind);
      <xsl:apply-templates mode="code"/>
      $queries[-1]-&gt;finish;
      pop @queries;
    }
  </xsl:template>

  <xsl:template match="esql:query" mode="code">
    $query =
    <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>;
    push @queries, $driver-&gt;query($query);
  </xsl:template>

  <xsl:template match="esql:parameter" mode="code">

  push @bind,
  <xsl:call-template name="as-expr">
  <xsl:with-param name="node" select="current()"/>
  </xsl:call-template>; '?';

  <!-- OLD CODE
    <xsl:when test="xsp:expr">
      &quot;,do { push @bind,<xsl:apply-templates select="xsp:expr/node()"/>;
		  '?'},&quot;
    </xsl:when>

    <xsl:when test="node() and not(text())">
      &quot;,do { push @bind,<xsl:apply-templates mode="code"/>;
		  '?'},&quot;
      </xsl:when>
    <xsl:otherwise>
	&quot;,do { push @bind, &quot;<xsl:value-of select="."/>&quot;;
		    '?'},&quot;
   </xsl:otherwise>
   </xsl:choose>
   -->
  </xsl:template>

  <xsl:template match="esql:max-rows|esql:skip-rows" mode="code">
  $parameters-&gt;{q|<xsl:value-of select="local-name()"/>|} =
  <xsl:call-template name="as-expr">
  <xsl:with-param name="node" select="current()"/>
  </xsl:call-template>;
  </xsl:template>

  <xsl:template match="esql:update-results" mode="code">
    if($queries[-1]-&gt;execute_update(\@bind, $parameters)) {
      <xsl:apply-templates mode="code"/>
    }
  </xsl:template>



  <xsl:template match="esql:results" mode="code">
      $queries[-1]-&gt;execute(\@bind, $parameters);
      if($queries[-1]-&gt;next_row) {
      <xsl:apply-templates mode="code"/>
      }
  </xsl:template>

  <xsl:template match="esql:row-results|esql:no-results|esql:get-columns|esql:get-xml|esql:get-string|esql:get-column|esql:get-boolean|esql:get-int|esql:get-long|esql:get-short|esql:get-date|esql:get-time|esql:get-timestamp|esql:get-float|esql:get-double|esql:get-column-name|esql:get-column-label|esql:get-column-type-name|esql:get-row-position">
  <xsp:expr><xsl:apply-templates select="current()" mode="code"/></xsp:expr>
  </xsl:template>

  <xsl:template match="esql:no-results" mode="code">
      else {
        <xsl:apply-templates mode="code"/>
      }
  </xsl:template>


  <xsl:template match="esql:row-results" mode="code">
     $queries[-1]-&gt;rewind();
     while($queries[-1]-&gt;next_row()) {
      <xsl:apply-templates mode="code"/>
     }
  </xsl:template>


  <!-- THIS IS BROKEN -->
  <xsl:template match="esql:get-columns" mode="code" >
   <xsl:variable name="case">
     <xsl:choose>
	<xsl:when test="@tag-case = 'upper'">uc</xsl:when>
        <xsl:otherwise>lc</xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
     <![CDATA[
      my ($esql, $columns, @fragment);
      $esql = $self->taglib('http://apache.org/xsp/SQL/v2');
      $columns = $esql->{QueryStack}->[(-1]]><xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if><![CDATA[)]->get_columns();
      map {
	my ($element);
	$element = $document->createElement(]]><xsl:value-of select="$case"/><![CDATA[ $_);
	$element->appendText($esql->{QueryStack}->[(-1]]><xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if><![CDATA[)]->get_column($_));
	push @fragment, $element;
      } (ref $columns eq 'ARRAY')?  @{$columns} : $columns;
     @fragment;
     ]]>
  </xsl:template>


  <xsl:template match="esql:get-xml" mode="code">
     <![CDATA[
      my ($esql, $xml, $fragment);
      $esql = $self->taglib('http://apache.org/xsp/SQL/v2');
      $xml = $esql->{QueryStack}->[(-1]]><xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if><![CDATA[)]->get_column("]]><xsl:value-of select="@column"/><![CDATA[");
     if($xml) {
       $xml = $self->driver->document($xml);
       $fragment = $document->importNode($xml->getDocumentElement(),1);
     }
     ]]>
     ($fragment || <xsl:apply-templates mode="code"/>);
  </xsl:template>


  <xsl:template match="esql:get-string|esql:get-column|esql:get-boolean|esql:get-int|esql:get-long|esql:get-short" mode="code">
     $queries[(-1 <xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if>)]-&gt;get_column('<xsl:value-of select="@column"/>') ||
  <xsl:call-template name="as-expr">
    <xsl:with-param name="node" select="current()"/>
  </xsl:call-template>;
  </xsl:template>

  <xsl:template match="esql:get-date|esql:get-time|esql:get-timestamp" mode="code">
      $value = $queries[(-1<xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if>)]-&gt;get_column('<xsl:value-of select="@column"/>') ||
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>;
  </xsl:template>


  <xsl:template match="esql:get-float|esql:get-double" mode="code">
      my ($value);
      $value = $queries[(-1<xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if>)]-&gt;get_column('<xsl:value-of select="@column"/>') ||
    <xsl:call-template name="as-expr">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>;

      <xsl:if test="@format">
      sprintf('<xsl:value-of select="@format"/>',$value);
      </xsl:if>
  </xsl:template>

  <xsl:template match="esql:get-column-name|esql:get-column-label" mode="code">
      my ($columns, $column);
      $columns = $queries[(-1<xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if>)]-&gt;get_columns();
      $column = ($columns-&gt;[<xsl:value-of select="@column"/>] ||
       '<xsl:value-of select="@column"/>');
      <xsl:if test="contains(local-name(), '-name')">
	lc $column;
      </xsl:if>
  </xsl:template>

  <xsl:template match="esql:get-row-position" mode="code">
      $queries[(-1<xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if>)]->get_row_position;
  </xsl:template>


  <xsl:template match="esql:get-column-type-name" mode="code">
     $queries->[(-1<xsl:if test="@ancestor"><xsl:value-of select="concat(' - ', number(@ancestor))"/></xsl:if>)]->get_column_type('<xsl:value-of select="@column"/>');
  </xsl:template>

  <xsl:template match="node()[namespace-uri() = 'http://apache.org/xsp/SQL/v2']"
    priority="-1"/>

</xsl:stylesheet>
