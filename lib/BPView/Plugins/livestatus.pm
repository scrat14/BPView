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


package BPView::Plugins::livestatus;

BEGIN {
    $VERSION = '1.000'; # Don't forget to set version and release
}  						# date in POD below!

use strict;
use warnings;
use Carp;
use JSON::PP;
use Monitoring::Livestatus;

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


# return all data from a monitoring system
sub query {
	
  my $self			= shift;
  my $provdata		= shift or die ("Missing provdata!");
  my $service_names	= shift or die ("Missing service_names!");
  
  my $query = undef;
   
  # get service status for given host and services
  # construct livestatus query
  if ($service_names eq "__all"){
  	$query->[0] = "GET services\n
Columns: host_name description last_hard_state plugin_output last_check acknowledged\n";
    # get host status
    $query->[1] = "GET hosts\n
Columns: name last_hard_state plugin_output last_check acknowledged";
  }else{
  	# query data for specified service
    $query->[0] = "GET services\n
Columns: display_name state\n";
    # go through service array
    for (my $i=0;$i< scalar @{ $service_names };$i++){
   	  $query->[0] .= "Filter: display_name = " . lc($service_names->[$i]) . "\n";
    }
    $query->[0] .= "Or: " . scalar @{ $service_names } . "\n" if scalar @{ $service_names } > 1;
  }
  	  
  return $query;

}


sub query_starttime {

  my $self			= shift;
  my $provdata		= shift or die ("Missing provdata!");

  my $query = "GET status\n
Columns: program_start\n";

  return $query;

}


sub get {

  my $self		= shift;
  my $provdata	= shift;
  my $query		= shift or croak ("Missing livestatus query!");
  my $fetch		= shift;	# how to handle results
  
  my $result;
  my $ml;
  
  use Monitoring::Livestatus;
  
  # use socket or hostname:port?
  if ($provdata->{ 'socket' }){
    $ml = Monitoring::Livestatus->new( 	'socket' 	=> $provdata->{'socket'},
    									'keepalive' => 1 );
  }else{
    $ml = Monitoring::Livestatus->new( 	'server' 	=> $provdata->{'server'} . ':' . $provdata->{'port'},
    									'keepalive'	=> 1 );
  }
  
  $ml->errors_are_fatal(0);
  
  # prepare return
  if (! defined $fetch || $fetch eq "all"){
  	
    $result = $ml->selectall_hashref($query->[0], "display_name");
    
  # example output:
  # $VAR1 = {
  #        'production-mail-zarafa' => {
  #                                      'service' => 'production-mail-zarafa',
  #                                      'state' => '0'
  #                                    },
  
    foreach my $key (keys %{ $result }){
      # rename columns
      $result->{ $key }{ 'service' } = delete $result->{ $key }{ 'display_name' };
    }
  
  
  }elsif ($fetch eq "row"){
  	# fetch all data and return array
  	my $tmp = undef;
  	for (my $i=0;$i<=@{ $query };$i++){
      push @{ $tmp }, $ml->selectall_arrayref($query->[$i]);
  	}
  	
  	if (! defined $tmp){
  	  my $provdetails = undef;
  	  if ( $provdata->{'socket'} ){
  	  	$provdetails = $provdata->{ 'socket' };
      }else{
    	$provdetails = $provdata->{'server'} . ':' . $provdata->{'port'};
      }
  	  croak "Got empty result from livestatus ($provdetails)";
  	}
    for (my $i=0; $i<scalar @{ $tmp }; $i++ ){
      for (my $j=0; $j<scalar @{ $tmp->[ $i ] }; $j++ ){
        my $tmphash = {};
        # do we deal with host or service checks?
        # host checks don't have description, so array doesn't have last entry
        if (! defined $tmp->[$i][$j][5]){
      	  # host check
      	  $tmphash->{ 'name2' } = "__HOSTCHECK";
      	  $tmphash->{ 'last_hard_state' } = $tmp->[$i][$j][1];
          # set last hard state to 2 (critical) if host check is 1 (down)
      	  $tmphash->{ 'last_hard_state' } = 2 if $tmp->[$i][$j][1] != 0;
          $tmphash->{ 'hostname' } = $tmp->[$i][$j][0];
          $tmphash->{ 'output' } = $tmp->[$i][$j][2];
          $tmphash->{ 'last_check' } = $tmp->[$i][$j][3];
          $tmphash->{ 'acknowledged' } = $tmp->[$i][$j][4];
        }else{
          $tmphash->{ 'name2' } = $tmp->[$i][$j][1];
          $tmphash->{ 'last_hard_state' } = $tmp->[$i][$j][2];
          $tmphash->{ 'hostname' } = $tmp->[$i][$j][0];
          $tmphash->{ 'output' } = $tmp->[$i][$j][3];
          $tmphash->{ 'last_check' } = $tmp->[$i][$j][4];
          $tmphash->{ 'acknowledged' } = $tmp->[$i][$j][5];
        }
  	    push @{ $result->{ $tmp->[$i][$j][0] } }, $tmphash;
      }
 
  # example output:
  # $VAR1 = {
  #         'loadbalancer' => [
  #           {
  #             'name2' => 'PING',
  #             'last_hard_state' => '0',
  #             'hostname' => 'loadbalancer',
  #             'output' => '',
  #             'last_check' => '1424453213'
  #           },
  #         ]
  #         },
  	}

  }elsif ($fetch eq "program_start"){
  	$result = $ml->selectall_hashref($query->[0], "program_start");
  	
  	# example output:
  	# $VAR1 = {
    #      '1422429147' => {
    #                        'program_start' => 1422429147
    #                      }
    #    };
    
  }else{
  	die "Unsupported fetch method: " . $fetch;
  }
  
  if($Monitoring::Livestatus::ErrorCode) {
    croak "Getting Monitoring checkresults failed: $Monitoring::Livestatus::ErrorMessage";
  }
  
  return $result;

}


sub get_starttime {

  my $self		= shift;
  my $provdata	= shift;
  my $query		= shift or croak ("Missing livestatus query!");
  
  my $result;
  my $ml;
  
  use Monitoring::Livestatus;
  
  # use socket or hostname:port?
  if ($provdata->{ 'socket' }){
    $ml = Monitoring::Livestatus->new( 	'socket' 	=> $provdata->{'socket'},
    									'keepalive' => 1 );
  }else{
    $ml = Monitoring::Livestatus->new( 	'server' 	=> $provdata->{'server'} . ':' . $provdata->{'port'},
    									'keepalive'	=> 1 );
  }
  
  $ml->errors_are_fatal(0);

  $result = $ml->selectall_hashref($query, "program_start");
  	
  # example output:
  # $VAR1 = {
  #      '1422429147' => {
  #                        'program_start' => 1422429147
  #                      }
  #    };
  
  return $result;
  
}

1;
