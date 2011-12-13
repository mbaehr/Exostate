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

package Exostate::Net;

use warnings; use strict;

use Exostate::Op qw(NOTIFY WANT);

use IO::Socket::Multicast;

sub new {
  my ($class,$self) = @_;
  bless ($self,$class);
  return $self->init();
}

sub init {
  my $self = shift;
  $self->{'sock'} = IO::Socket::Multicast->new(
    LocalPort => $self->{'port'},
    PeerPort => $self->{'port'},
    PeerDest => $self->{'group'},
    ReuseAddr => 1
  ) or die;
  return $self;
}

sub listen {
  my $self = shift;
  $self->{'sock'}->mcast_add($self->{'group'},$self->{'interface'}) or die;
}

sub read {
  my $self = shift;
  my $data;
  # Just stick to <1024 bytes for now
  $self->{'sock'}->recv($data,1024);
  chomp $data;
  return Exostate::Op::from_net($data);
}

sub want {
  my ($self,$args) = @_;
  # Default freshness of 5 minutes
  my $freshness = (defined($args->{'freshness'})) ? $args->{'freshness'} : 300;
  my $op = new Exostate::Op ({ts => time,
                              op => WANT,
                          handle => $args->{'handle'},
                           value => $freshness});
  $self->{'sock'}->mcast_send($op->to_net(),
    $self->{'group'}.':'.$self->{'port'});
}

sub notify {
  my ($self,$rec) = @_;
  my $op = new Exostate::Op ({ts => $rec->{'ts'},
                              op => NOTIFY,
                          handle => $rec->{'handle'},
                           value => $rec->{'value'}});
  $self->{'sock'}->mcast_send($op->to_net(),
    $self->{'group'}.':'.$self->{'port'});
}

1;
