#!/usr/bin/perl -w
#
# This file is part of Exostate.
# 
# Exostate is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Exostate is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Exostate.  If not, see <http://www.gnu.org/licenses/>.
#

use warnings;
use strict;

use Exostate::Store;
use Exostate::Net;
use Net::Domain qw(hostname);
use Data::Dumper;

use Getopt::Std;

our ($opt_d,$opt_i,$opt_g,$opt_p,$opt_h,$opt_f);
getopts("d:i:g:p:h:f:");

my $usage = "
exostate-get.pl -d /var/run/exostate/exostate.db
                -i eth0
                -g 225.0.0.2
                -p 1100
                -h mysql_state
               [-f freshness]";
                              

die "$usage" unless (defined ($opt_d) &&
                     defined ($opt_i) &&
                     defined ($opt_g) &&
                     defined ($opt_p) &&
                     defined ($opt_h));

my $store = new Exostate::Store ({file => $opt_d});
my $net =     new Exostate::Net ({port => $opt_p,
                                 group => $opt_g,
                             interface => $opt_i});

my $handle = ($opt_h =~ m/.*\:.*/) ? $opt_h : hostname().":".$opt_h;
my $freshness = (defined ($opt_f)) ? $opt_f : -1;

my $rec;
my $wanted = {
     handle => $handle,
  freshness => $freshness
};

if (my $rec = $store->get($wanted)) {
  print $rec->{'value'};
} else {
  $net->want($wanted);
  exit -1;
}
