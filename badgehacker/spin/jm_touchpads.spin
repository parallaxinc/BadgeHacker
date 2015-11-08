'' =================================================================================================
''
''   File....... jm_touchpads.spin
''   Purpose.... Touchpad reader for Parallax boards (Quickstart, DC22 badge, eBadge)
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (C) 2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started....
''   Updated.... 07 JUL 2015
''
'' =================================================================================================


con { fixed io pins }

  RX1 = 31                                                       ' programming / terminal
  TX1 = 30

  SDA = 29                                                       ' eeprom / i2c
  SCL = 28


var

  long  pincount                                                 ' # of pins scanned
  long  p_pinslist                                               ' pointer to list of pins (byte array)
  long  disch                                                    ' discharge timing

  long  pinsmask                                                 ' mask for input pins


pub start(count, p_pins, dms) | idx

'' Setup object for input of count pins
'' -- count is # pins to scan
'' -- p_pins is a pointer to a list of pins (byte array)
''    * pins in list are arranged MSB to LSB
'' -- ms is the discharge timing in milliseconds

  longmove(@pincount, @count, 3)                                 ' copy parameters

  pinsmask := 0                                                  ' build mask of input pins
  repeat idx from 0 to pincount-1 
    pinsmask |= 1 << byte[p_pinslist][pincount-1-idx]


pub read_pads | work, pads, idx                                  ' UPDATED 06 JUL 2015

'' Reads and returns state of touch pad inputs

  outa |= pinsmask                                               ' charge pads
  dira |= pinsmask
  waitcnt(cnt + (clkfreq / 1000))                                ' hold 1ms

  dira &= !pinsmask                                              ' float pads
  waitcnt(cnt + ((clkfreq / 1000) * disch))                      ' allow discharge through finger 

  work := !ina & pinsmask                                        ' capture pads (touched = "1")

  pads := 0                                                      ' clear result
  repeat idx from 0 to pincount-1                                ' loop through all pins
    if (work & (1 << byte[p_pinslist][pincount-1-idx]))          ' this pin active?
      pads |= 1 << idx                                           '  yes, set associated bit

  return pads

  
dat { license }

{{

  Copyright (C) 2015 Jon McPhalen

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}