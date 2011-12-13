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

package Exostate::Store;

use warnings; use strict;

use DB_File::Lock;
use Fcntl qw(O_RDWR O_CREAT);
use Storable qw(freeze thaw);
use Net::Domain qw(hostname);

sub new {
  my ($class,$self) = @_;
  bless ($self,$class);
  return $self->init();
}

sub init {
  my $self = shift;
  unless (-e $self->{'file'}) {
    my $store = $self->lock('write');
    untie %{ $store };
  }
  return $self;
}

sub lock {
  my ($self,$mode) = @_;
  my %store; my $flags;
  if ($mode eq 'read') {
    $flags = O_RDONLY;
  } elsif ($mode eq 'write') {
    $flags = O_RDWR|O_CREAT;
  }
  tie %store, 'DB_File::Lock', $self->{'file'}, $flags, 0600, $DB_HASH, $mode or die;
  return \%store;
}

sub get {
  my ($self,$args) = @_;
  my $handle = $args->{'handle'};
  my $store = $self->lock('read');
  if (defined($store->{$handle})) {
    my $rec = thaw($store->{$handle});
    untie %{ $store };
    # Return if we weren't asked about freshness
    return $rec unless (defined($args->{'freshness'}));
    # Likewise, return if freshness = -1
    # (which will happen due to a WANT op)
    return $rec if ($args->{'freshness'} == -1);
    # Otherwise, return if it's fresh enough
    return $rec unless ((time - $rec->{'ts'}) > $args->{'freshness'});
    # Finally, return if the handle matches our hostname
    # since we are always authoritative
    my $hostname = hostname();
    my ($host,$scalar) = split(':',$handle);
    # A record from us is re-"fresh"ed
    $rec->{'ts'} = time;
    return $rec if ($host eq $hostname);
  } else {
    untie %{ $store };
  }
  return;
}

sub put {
  my ($self,$rec) = @_;
  my $store = $self->lock('read');
  if (defined($store->{$rec->{'handle'}})) {
    # We already have a newer copy; don't store
    my $existing = thaw($store->{$rec->{'handle'}});
    untie %{ $store };
    return if ($existing->{'ts'} >= $rec->{'ts'});
  }
  untie %{ $store };
  $store = $self->lock('write');
  $store->{$rec->{'handle'}} = freeze $rec;
  untie %{ $store };
  return 1;
}

1;
