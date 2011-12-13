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

package Exostate::Op;

use warnings; use strict;

use base 'Exporter';
our @EXPORT = qw(NOTIFY WANT);

use constant NOTIFY => 0;
use constant WANT => 1;

sub new {
  my ($class,$self) = @_;
  bless ($self,$class);
  return $self;
}

sub from_net {
  my $msg = shift;
  my ($ts,$op,$handle,$value) = split(/\t/,$msg);
  return new Exostate::Op ({ts => $ts,
                            op => $op,
                        handle => $handle,
                         value => $value});
}

sub to_net {
  my $self = shift;
  return join("\t",$self->{'ts'},
                   $self->{'op'},
                   $self->{'handle'},
                   $self->{'value'});
}

1;
