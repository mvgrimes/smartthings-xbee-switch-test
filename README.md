## SmartThings Xbee Switch Test (st-switch)

1. Uses X-CTU.app to setup Xbee and communicate with Smart Hub frame-by-frame.

  http://www.falco.co.nz/electronic-projects/xbee-to-smartthings/

2. Uses perl script to control Xbee over USB to communicate with Smart Hub.
   Able to join network, announce device, add to Hub and send commands from Smart
   Things app. App throws an error, but the device receives.

## Setup

Uses X-CTU NG for mac as installed for the temp-sensor project.

    http://www.digi.com/support/productdetail?pid=3352&type=utilities

X-CTU Installed (API) Firmware:

      XB24-ZB / ZigBee End Device API / 2947 (Newest)

minicom connection shouldn't work any more since this is API firmware.

### Exiting settins:

    MY: A4DF  (Little Endien: DF A4)
    SH: 13A200
    SL: 408B65BE
    Address: 0013A200 408B65BE
      (Little Endien: BE 65 8B 40 00 A2 12 00)

### Updated settings:

    SC = 7FFF
    ZS = 2
    NJ = 5A
    NI = Xbee End Point
    NH = 1E
    NO = 3
    EE = Enabled (1)
    EO = 1
    KY = 5A6967426565416C6C69616E63653039
    AP = 2 <- API via escape (required for xbee-api arduino lib)

If prompted to reset Xbee, connect RST pin to GND

See perl script for process.


## Thoughts

This is promising. We are getting pretty far using the perl script. The next
step is to drive the Xbee from the Arduino via the Xbee Shield. (Or wait for the
ArduinoThing Shield which is out of stock.)

There is code for Xbee/Arduino:

  https://code.google.com/p/xbee-arduino/
  http://www.arduino.cc/en/Main/ArduinoXbeeShield
  http://www.arduino.cc/en/Guide/ArduinoXbeeShield

There is an existing, very interesting, sprinkler project that uses the Thing
Shield. We might use that or adapt it to our XbeeShield.

  https://github.com/d8adrvn/smart_sprinkler/blob/master/8_Zone_Controller/README_8_Zone_Irrigation_Controller.md
  https://github.com/DanielOgorchock/ST_Anything/blob/master/Arduino/libraries/SmartThings/SmartThings.cpp

Alternatively, we don't really need the controller to be wireless for our
sprinkler project. We could use an Ethernet Shield instead. This will also
free-up the Xbee's to act as a sensor network (temperature, soil moister, etc.)
