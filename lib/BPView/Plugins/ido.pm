#!/usr/bin/perl -w
#
# COPYRIGHT:
#
# This software is Copyright (c) 2013 by ovido
#                            (c) 2014-2015 by BPView Development Team
#
# This file is part of Business Process View (BPView).
#
# (Except where explicitly superseded by other copyright notices)
# BPView is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or 
# any later version.
#
# BPView is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License 
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with BPView.  
# If not, see <http://www.gnu.org/licenses/>.


package BPView::Plugins::ido;

BEGIN {
    $VERSION = '1.000'; # Don't forget to set version and release
}  						# date in POD below!

use strict;
use warnings;
use Carp;
use JSON::PP;

# for debugging only
#use Data::Dumper;


sub new {
  my $invocant	= shift;
  my $class		= ref($invocant) || $invocant;
  my $self		= {};
 
  bless $self, $class;
  return $self;
}


# parse config parameters
sub parse {
	
  # TODO: later
 
}


# prepare SQL query
sub query {

  my $self			= shift;
  my $provdata		= shift or die ("Missing provdata!");
  my $service_names	= shift or die ("Missing service_names!");
  
  my $sql = undef;
  
  # construct SQL query
  # query all host and service data
  if ($service_names eq "__all"){

=cut
Example query: Fetch host and service checks, acknowledges and scheduled downtimes
--------------

SELECT DISTINCT
	icinga_objects.name1 AS hostname,
	coalesce(icinga_objects.name2,'__HOSTCHECK') AS name2,
  coalesce(icinga_hoststatus.last_hard_state, icinga_servicestatus.last_hard_state) AS last_hard_state,
  coalesce(icinga_hoststatus.problem_has_been_acknowledged, icinga_servicestatus.problem_has_been_acknowledged) AS acknowledged, 
	coalesce(icinga_hoststatus.output, icinga_servicestatus.output) AS output,
	coalesce(unix_timestamp(icinga_hoststatus.last_check), unix_timestamp(icinga_servicestatus.last_check)) AS last_check,
	unix_timestamp() between unix_timestamp(icinga_scheduleddowntime.scheduled_start_time) AND
	unix_timestamp(icinga_scheduleddowntime.scheduled_end_time) AS downtime
FROM 
	icinga_objects
LEFT JOIN
	icinga_scheduleddowntime 
  ON icinga_scheduleddowntime.object_id = icinga_objects.object_id
LEFT JOIN 
	icinga_hoststatus 
  ON icinga_objects.object_id=icinga_hoststatus.host_object_id
LEFT JOIN 
	icinga_servicestatus
  ON icinga_objects.object_id=icinga_servicestatus.service_object_id 
WHERE
	icinga_objects.is_active = 1
  AND (icinga_objects.objecttype_id=1 
  OR icinga_objects.objecttype_id=2)
  ORDER BY icinga_objects.name1;

=cut

    if ($provdata->{ 'type' } eq 'mysql'){
    
  	  $sql = "SELECT DISTINCT ";
  	  $sql .= $provdata->{'prefix'} . "objects.name1 AS hostname, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "objects.name2, '__HOSTCHECK') AS name2, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "hoststatus.last_hard_state, " . $provdata->{'prefix'} . "servicestatus.last_hard_state) AS last_hard_state, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "hoststatus.problem_has_been_acknowledged, " . $provdata->{'prefix'} . "servicestatus.problem_has_been_acknowledged) AS acknowledged, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "hoststatus.output, " . $provdata->{'prefix'} . "servicestatus.output) AS output, ";
  	  $sql .= "coalesce(unix_timestamp(" . $provdata->{'prefix'} . "hoststatus.last_check), unix_timestamp(" . $provdata->{'prefix'} . "servicestatus.last_check)) AS last_check, ";
  	  $sql .= "unix_timestamp() between unix_timestamp(" . $provdata->{'prefix'} . "scheduleddowntime.scheduled_start_time) AND ";
  	  $sql .= "unix_timestamp(" . $provdata->{'prefix'} . "scheduleddowntime.scheduled_end_time) AS downtime ";
  	  $sql .= "FROM " . $provdata->{'prefix'} . "objects ";
  	  $sql .= "LEFT JOIN " . $provdata->{'prefix'} . "scheduleddowntime ON ";
  	  $sql .= $provdata->{'prefix'} . "scheduleddowntime.object_id=" . $provdata->{'prefix'} . "objects.object_id ";
  	  $sql .= "LEFT JOIN " . $provdata->{'prefix'} . "hoststatus ON ";
  	  $sql .= $provdata->{'prefix'} . "objects.object_id=" . $provdata->{'prefix'} . "hoststatus.host_object_id ";
  	  $sql .= "LEFT JOIN " . $provdata->{'prefix'} . "servicestatus ON ";
  	  $sql .= $provdata->{'prefix'} . "objects.object_id=" . $provdata->{'prefix'} . "servicestatus.service_object_id ";
  	  $sql .= "WHERE " . $provdata->{'prefix'} . "objects.is_active=1 ";
  	  $sql .= "AND (" . $provdata->{'prefix'} . "objects.objecttype_id=1 OR ";
  	  $sql .= $provdata->{'prefix'} . "objects.objecttype_id=2) ";
  	  $sql .= "ORDER BY " . $provdata->{'prefix'} . "objects.name1";
  	
    }elsif ($provdata->{ 'type' } eq 'pgsql'){

  	  $sql = "SELECT DISTINCT ";
  	  $sql .= $provdata->{'prefix'} . "objects.name1 AS hostname, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "objects.name2, '__HOSTCHECK') AS name2, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "hoststatus.last_hard_state, " . $provdata->{'prefix'} . "servicestatus.last_hard_state) AS last_hard_state, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "hoststatus.problem_has_been_acknowledged, " . $provdata->{'prefix'} . "servicestatus.problem_has_been_acknowledged) AS acknowledged, ";
  	  $sql .= "coalesce(" . $provdata->{'prefix'} . "hoststatus.output, " . $provdata->{'prefix'} . "servicestatus.output) AS output, ";
  	  $sql .= "coalesce(EXTRACT(EPOCH FROM " . $provdata->{'prefix'} . "hoststatus.last_check), EXTRACT(EPOCH FROM " . $provdata->{'prefix'} . "servicestatus.last_check)) AS last_check, ";
  	  $sql .= "EXTRACT(EPOCH FROM NOW()) between EXTRACT(EPOCH FROM " . $provdata->{'prefix'} . "scheduleddowntime.scheduled_start_time) AND ";
  	  $sql .= "EXTRACT(EPOCH FROM " . $provdata->{'prefix'} . "scheduleddowntime.scheduled_end_time) AS downtime ";
  	  $sql .= "FROM " . $provdata->{'prefix'} . "objects ";
  	  $sql .= "LEFT JOIN " . $provdata->{'prefix'} . "scheduleddowntime ON ";
  	  $sql .= $provdata->{'prefix'} . "scheduleddowntime.object_id=" . $provdata->{'prefix'} . "objects.object_id ";
  	  $sql .= "LEFT JOIN " . $provdata->{'prefix'} . "hoststatus ON ";
  	  $sql .= $provdata->{'prefix'} . "objects.object_id=" . $provdata->{'prefix'} . "hoststatus.host_object_id ";
  	  $sql .= "LEFT JOIN " . $provdata->{'prefix'} . "servicestatus ON ";
  	  $sql .= $provdata->{'prefix'} . "objects.object_id=" . $provdata->{'prefix'} . "servicestatus.service_object_id ";
  	  $sql .= "WHERE " . $provdata->{'prefix'} . "objects.is_active=1 ";
  	  $sql .= "AND (" . $provdata->{'prefix'} . "objects.objecttype_id=1 OR ";
  	  $sql .= $provdata->{'prefix'} . "objects.objecttype_id=2) ";
  	  $sql .= "ORDER BY " . $provdata->{'prefix'} . "objects.name1";
   
    }else{
      croak "Unsupported database type: $provdata->{ 'type' }";
    }
  	
  }else{
    # query data for specified service
    $sql = "SELECT name2 AS service, current_state AS state FROM " . $provdata->{'prefix'} . "objects, " . $provdata->{'prefix'} . "servicestatus ";
    $sql .= "WHERE object_id = service_object_id AND is_active = 1 AND name2 IN (";
    # go trough service_names array
    for (my $i=0;$i<scalar @{ $service_names };$i++){
  	  $sql .= "'" . lc($service_names->[$i]) . "', ";
    }
    # remove trailing ', '
    chop $sql;
    chop $sql;
    $sql .= ") ORDER BY name1";
  }
  
  return $sql;
 
}


sub query_starttime {

  my $self			= shift;
  my $provdata		= shift or die ("Missing provdata!");
  
  my $sql = undef;
  
  if ($provdata->{ 'type' } eq "mysql" ){
    $sql  = "SELECT UNIX_TIMESTAMP(program_start_time) AS program_start FROM " . $provdata->{ 'prefix' } . "programstatus ";
    $sql .= "ORDER BY instance_id DESC LIMIT 1";
  }elsif ($provdata->{ 'type' } eq "pgsql"){
    $sql  = "SELECT EXTRACT(EPOCH FROM program_start_time) AS program_start FROM " . $provdata->{ 'prefix' } . "programstatus ";
    $sql .= "ORDER BY instance_id DESC LIMIT 1";
  }
 
  return $sql;

}


# return all data from a monitoring system
sub get {

  my $self		= shift;
  my $provdata 	= shift;
  my $sql		= shift or die ("Missing SQL query!");
  my $fetch		= shift;	# how to handle results
  
  my $result;
  
  my $dsn = undef;
  # database driver
  if ($provdata->{'type'} eq "mysql"){
    use DBI;	  # MySQL
  	$dsn = "DBI:mysql:database=$provdata->{'database'};host=$provdata->{'host'};port=$provdata->{'port'}";
  }elsif ($provdata->{'type'} eq "pgsql"){
	use DBD::Pg;  # PostgreSQL
  	$dsn = "DBI:Pg:dbname=$provdata->{'database'};host=$provdata->{'host'};port=$provdata->{'port'}";
  }else{
  	croak "Unsupported database type: $provdata->{'type'}";
  }
  
  # connect to database
  my $dbh   = eval { DBI->connect_cached($dsn, $provdata->{'username'}, $provdata->{'password'}) };
  if ($DBI::errstr){
  	croak "$DBI::errstr: $@";
  }
  my $query = eval { $dbh->prepare( $sql ) };
  eval { $query->execute };
  if ($DBI::errstr){
  	croak "$DBI::errstr: $@";
  }
  
  # prepare return
  if (! defined $fetch || $fetch eq "all"){
  	# use hashref to fetch results
    $result = $query->fetchall_hashref("service");
  
  # example output:
  # $VAR1 = {
  #        'production-mail-zarafa' => {
  #                                      'service' => 'production-mail-zarafa',
  #                                      'state' => '0'
  #                                    },
  
  }elsif ($fetch eq "row"){
  	# fetch all data and return array
  	while (my $row = $query->fetchrow_hashref()){
  	  
  	  # set last hard state to 2 (critical) if host check is 1 (down)
  	  if ($row->{ 'name2'} eq "__HOSTCHECK"){
  	  	$row->{ 'last_hard_state' } = 2 if $row->{ 'last_hard_state' } != 0;
  	  }
  	  push @{ $result->{ $row->{ 'hostname' } } }, $row;
  
  # example output:
  # $VAR1 = {
  #         'loadbalancer' => [
  #           {
  #             'name2' => 'PING',
  #             'last_hard_state' => '0',
  #             'hostname' => 'loadbalancer',
  #             'output' => ''
  #           },
  #         ]
  #         },
  	}
  	
  }elsif ($fetch eq "program_start"){
  	$result = $query->fetchall_hashref("program_start");
  	
  	# example output:
  	# $VAR1 = {
    #      '1422429147' => {
    #                        'program_start' => 1422429147
    #                      }
    #    };
  	
  }else{
  	croak "Unsupported fetch method: " . $fetch;
  }
  
  
  # disconnect from database
  #$dbh->disconnect;
  
  return $result;

}


sub get_starttime {

  my $self		= shift;
  my $provdata 	= shift;
  my $sql		= shift or die ("Missing SQL query!");
  
  my $result;
  
  my $dsn = undef;
  # database driver
  if ($provdata->{'type'} eq "mysql"){
    use DBI;	  # MySQL
  	$dsn = "DBI:mysql:database=$provdata->{'database'};host=$provdata->{'host'};port=$provdata->{'port'}";
  }elsif ($provdata->{'type'} eq "pgsql"){
	use DBD::Pg;  # PostgreSQL
  	$dsn = "DBI:Pg:dbname=$provdata->{'database'};host=$provdata->{'host'};port=$provdata->{'port'}";
  }else{
  	croak "Unsupported database type: $provdata->{'type'}";
  }
  
  # connect to database
  my $dbh   = eval { DBI->connect_cached($dsn, $provdata->{'username'}, $provdata->{'password'}) };
  if ($DBI::errstr){
  	croak "$DBI::errstr: $@";
  }
  my $query = eval { $dbh->prepare( $sql ) };
  eval { $query->execute };
  if ($DBI::errstr){
  	croak "$DBI::errstr: $@";
  }
  
	$result = $query->fetchall_hashref("program_start");
  	
	# example output:
	# $VAR1 = {
  #      '1422429147' => {
  #                        'program_start' => 1422429147
  #                      }
  #    };
  
  return $result;

}

1;

