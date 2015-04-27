#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;
use Device::SerialPort;
use Device::XBee::API;
use List::Util qw(reduce);
use POSIX;
use Data::Dumper;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Terse = 1;

my $serial_port_device =
  Device::SerialPort->new('/dev/tty.usbserial-13W9S9GD') || die $!;
$serial_port_device->baudrate(9600);
$serial_port_device->databits(8);
$serial_port_device->stopbits(1);
$serial_port_device->parity('none');
$serial_port_device->read_char_time(0);    # don't wait for each character
$serial_port_device->read_const_time(1000)
  ;    # 1 second per unfulfilled "read" call

my $api = Device::XBee::API->new( { fh => $serial_port_device } ) || die $!;

my $id = $api->at('MY');
say "id (MY): $id";

my $frame_id = int( rand(0x20) );

sub send_device_announce {
    my @packet = (

        # 0x11, $frame_id++,  # frame type and frame id
        # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # 64-bit dest address
        # 0xFF, 0xFC, # 16-bit dest address
        ##0x00,    # source endpoint
        ##0x00,    # dest endpoint
        0x00, 0x13,    # cluster id
        0x00, 0x00,    # profile id
        0x00,          # broadcast radius
        0x00,          # options
                       # Data
        0x06,          # any frame id
        0xDF, 0xA4,    # our 16-bit address in little endian
        0xBE, 0x65, 0x8B, 0x40, 0x00, 0xA2, 0x13, 0x00,    # our 64-bit address
        0x04,                                              # capability
    );

    # my $packed =
    #   pack( "C*", ( 0x7E, 0x00, scalar(@packet), @packet, checksum(@packet) ) );
    say "> Device Announce";

    # print "> ";
    # dump_hex($packed);
    ## $api->tx($packed);
    $api->tx( { sh => 0, sl => 0, na => 0xfffc }, pack( "C*", @packet ) )
      or die "tx error";
}

sub send_active_endpoints_response {
    my ( $ci, $fi ) = @_;
    my @packet = (

        # 0x11, $frame_id++,  # frame type and frame id
        # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # 64-bit dest address
        # 0xFF, 0xFC, # 16-bit dest address
        ##0x00,    # source endpoint
        ##0x00,    # dest endpoint
        0x80, 0x05,    # cluster id (same as response with high bit set)
        0x00, 0x00,    # profile id
        0x00,          # broadcast radius
        0x00,          # options
                       # Data
        $fi,           # fames id the hub sent
        0x00,          # status 00=OK
        0xDF, 0xA4,    # our 16-bit address in little endian
        0x01,          # number of endpoint address
        0x08,          # endpoint address (random choice)
    );

    # my $packed =
    #   pack( "C*", ( 0x7E, 0x00, scalar(@packet), @packet, checksum(@packet) ) );
    say "> Active Endpoints Reponse";

    # print ">";
    # dump_hex($packed);
    ## $api->tx($packed);
    $api->tx( { sh => 0, sl => 0, na => 0 }, pack( "C*", @packet ) )
      or die "tx error";
}

sub send_simple_descriptor_response {
    my ( $ci, $fi ) = @_;
    my @packet = (

        # 0x11, $frame_id++,  # frame type and frame id
        # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, # 64-bit dest address
        # 0xFF, 0xFC, # 16-bit dest address
        ##0x00,    # source endpoint
        ##0x00,    # dest endpoint
        0x80, 0x04,    # cluster id (same as response with high bit set)
        0x00, 0x00,    # profile id
        0x00,          # broadcast radius
        0x00,          # options
                       # Data
        $fi,           # fames id the hub sent
        0x00,          # status 00=OK
        0xDF, 0xA4,    # our 16-bit address in little endian
        0x0E,          # number of bytes sent after this
        0x08,          # the endpoint (chosen randomly in the last response)
        0x04, 0x01,    # our endpoint is Home Automation capable
        0x02, 0x00,    # our device is an on/off output
        0x30,          # version numbers?
        0x03,          # number of cluster types we can accept in
        0x00, 0x00,    # first cluster type - basic
        0x03, 0x00,    # second on is id clusters
        0x06, 0x00,    # last on is on/off clusters
        0x00,          # the number of cluster types we send out
    );

    # my $packed =
    #   pack( "C*", ( 0x7E, 0x00, scalar(@packet), @packet, checksum(@packet) ) );
    say "> Simple Descriptor Response";

    # print ">";
    # dump_hex($packed);
    ## $api->tx($packed);
    $api->tx( { sh => 0, sl => 0, na => 0 }, pack( "C*", @packet ) )
      or die "tx error";
}

sub checksum {
    my @packet = @_;
    my $sum = reduce { ( our $a + our $b ) & 0xFF } @packet;
    return 0xFF - $sum;
}

my $done = 0;
$SIG{INT} = sub { $done++; };
while ( !$done ) {
    my $rx = $api->rx();
    print "< ";
    dump_hex($rx);

    if ( ref $rx eq 'HASH' ) {
        if ( $rx->{api_data} eq "\00" ) {
            say "= Device Reset";
        } elsif ( $rx->{api_data} eq "\02" ) {
            say "= Device Joined Network";
            send_device_announce();
        } elsif ( substr( $rx->{api_data}, 0, 1 ) eq "\320" ) {
            my $ci = $rx->{ci};
            my $fi = unpack( "C", substr( $rx->{data}, 0, 1 ) );
            if ( $ci == 5 ) {
                say "= Active Endpoints Request";
                send_active_endpoints_response( $ci, $fi );
            } elsif ( $ci == 4 ) {
                say "= Simple Descriptor Request";
                send_simple_descriptor_response( $ci, $fi );
            }
        }
    }
}

sub dump_hex {
    my ($obj) = shift;
    if ( ref $obj ) {
        while ( my ( $k, $v ) = each %$obj ) {
            printf "%20s: %s (%s", $k, isdigit($v)
              ? $v
              : join( " ", split /\w\w\K/, unpack( "H*", $v ) ),
              Dumper($v);
        }
    } elsif ( defined $obj ) {
        say join( ' ', split /\w\w\K/, unpack( "H*", $obj ) );
    } else {
        say " undef";
    }
}

# my $id = $api->at( 'SC', 0x7fff );
# $api->at( 'ZS', 0x2 );
# $api->at( 'NJ', 0x5a );
# $api->at( 'NI', 'Xbee End Point' );
# $api->at( 'NH', 0x1e );
# $api->at( 'NO', 0x3 );
# $api->at( 'EE', 0x1 );
# $api->at( 'EO', 0x1 );
# $api->at( 'EE', '5A6967426565416C6C69616E63653039' );

$serial_port_device->close();

__END__
$VAR1 = {
          "api_data" => "\0\23\242\0\@\213e\276N\17\1\1\0\0\2\2\f",
          "options" => 1,
          "api_type" => 146,
          "data" => "20c0",
          "number_samples" => 1,
          "digital_channel_second" => [
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0
                                      ],
          "digital_channel_first" => [
                                       0,
                                       0,
                                       0,
                                       0,
                                       0,
                                       0,
                                       0,
                                       0
                                     ],
          "is_ack" => 1,
          "sl" => "1082877374",
          "analog_channel_bits" => [
                                     0,
                                     0,
                                     0,
                                     0,
                                     0,
                                     0,
                                     1,
                                     0
                                   ],
          "analog_inputs" => [
                               undef,
                               524
                             ],
          "sh" => 1286656,
          "na" => 19983,
          "is_broadcast" => 0
        };
