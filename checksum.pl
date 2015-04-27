#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;
use Device::SerialPort;
use Device::XBee::API;
use List::Util qw(reduce);
use Data::Dumper;
$Data::Dumper::Useqq = 1;

my @packet = (

    # 0x7E, 0x00, 0x20,
    0x11, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0xFF, 0xFC, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x00, 0x06,
    0xDF, 0xA4, 0xBE, 0x65, 0x8B, 0x40, 0x00, 0xA2, 0x13, 0x00, 0x04

      # 0xAB
);
my $length   = scalar @packet;
my $checksum = checksum(@packet);
my $packed   = pack( "C*", ( 0x7E, 0x00, $length, @packet, $checksum ) );
print "> ";
dump_hex($packed);

sub checksum {
    my @packet = @_;
    my $sum = reduce { ( $a + $b ) & 0xFF } @packet;
    return 0xFF - $sum;
}

sub dump_hex {
    my ($obj) = shift;
    if ( ref $obj ) {
        while ( my ( $k, $v ) = each %$obj ) {
            printf "%20s: %s\n", $k,
              join( " ", split /\w\w\K/, unpack( "H*", $v ) );
        }
    } elsif ( defined $obj ) {
        say join( ' ', split /\w\w\K/, unpack( "H*", $obj ) );
    } else {
        say "undef";
    }
}
