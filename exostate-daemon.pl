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
use Exostate::Op;
use Data::Dumper;

use Getopt::Std;

our ($opt_d,$opt_i,$opt_g,$opt_p);
getopts("d:i:g:p:");

my $usage = "
exostate-daemon.pl -d /var/run/exostate/exostate.db
                   -i eth0
                   -g 225.0.0.2
                   -p 1100";
                              

die "$usage" unless (defined ($opt_d) &&
                     defined ($opt_i) &&
                     defined ($opt_g) &&
                     defined ($opt_p) );

my $store = new Exostate::Store ({file => $opt_d});
my $net =     new Exostate::Net ({port => $opt_p,
                                 group => $opt_g,
                             interface => $opt_i});

$net->listen();

while(1)
{
  my $op = $net->read();
  print Dumper $op;
  if ($op->{'op'} == NOTIFY) {
    $store->put({ts => $op->{'ts'},
             handle => $op->{'handle'},
              value => $op->{'value'}});
  }
  if ($op->{'op'} == WANT) {
    # In a "WANT" message, the "value" is actually freshness in seconds
    if (my $rec = $store->get({handle => $op->{'handle'},
                            freshness => $op->{'value'}})) {
      $net->notify($rec);
    }
  }
}
