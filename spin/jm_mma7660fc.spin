'' =================================================================================================
''
''   File....... jm_mma7660fc.spin
''   Purpose.... MMA7660FC 3-Axis accelerometer interface
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (C) 2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started....
''   Updated.... 09 SEP 2015
''
'' =================================================================================================


con { fixed io pins }

  RX1 = 31                                                       ' programming / terminal
  TX1 = 30

  SDA = 29                                                       ' eeprom / i2c
  SCL = 28


con 

  MMA7660_WR = %1001_100_0                                       ' i2c address - write
  MMA7660_RD = %1001_100_1                                       ' i2c address - read 

  TAP_BIT    = %0010_0000                                        ' device has been tapped
  
  ALERT_BIT  = %0100_0000                                        ' set when reading could be corrupted
  ALERT_XYZT = $40_40_40_40                                      ' for reading x, y, z, and tilt at once

  SHAKE_BIT  = %1000_0000                                        ' device has been shaken

  #0, FRONT, BACK                                                ' side
  #0, LEFT, RIGHT, DOWN, UP                                      ' orientation
  

con { registers }

  XOUT  = $00                                                    ' signed 6-bit output value X
  YOUT  = $01                                                    ' signed 6-bit output value Y
  ZOUT  = $02                                                    ' signed 6-bit output value Z
  TILT  = $03                                                    ' Tilt Status
  SRST  = $04                                                    ' Sampling Rate Status
  SPCNT = $05                                                    ' Sleep Count
  INTSU = $06                                                    ' Interrupt Setup
  MODE  = $07                                                    ' Mode
  SR    = $08                                                    ' Auto-Wake/Sleep, P/L SPS, debounce filter
  PDET  = $09                                                    ' Tap Detection
  PD    = $0A                                                    ' Tap Debounce Count

  
obj

  i2c : "jm_i2c"                                                 ' Spin I2C driver


pub start(sclpin, sdapin)

'' Connect MMA7660FC to I2C buss

  i2c.setupx(sclpin, sdapin)

  write_reg(MODE,  $00)                                          ' stand-by
  write_reg(INTSU, $00)                                          ' no interrupts
  write_reg(SR,    $00)                                          ' 120 sps
  write_reg(PDET,  $6C)                                          ' tap detect on Z, threshold = 12
  write_reg(PD,    $08)                                          ' tap debounce count  
  write_reg(MODE,  $C1)                                          ' active, int pin is push-pull active-high
               

pub present

'' Returns true if device detected

  return i2c.present(MMA7660_WR)

  
pub read_x

'' Returns X axis as signed long (1/100th-gs)  

  return raw_to_gforce(read(XOUT))


pub read_y

'' Returns Y axis as signed long (1/100th-gs)       

  return raw_to_gforce(read(YOUT))


pub read_z

'' Returns Z axis as signed long (1/100th-gs)        

  return raw_to_gforce(read(ZOUT))


pub read_tilt

'' Returns tilt register (8 bits)

  return read(TILT)
  

pub read(axis) | value

'' Read specified axis or tilt register
'' -- returns raw value (signed, 6-bit value for x, y, and z)

  if ((axis < XOUT) or (axis > TILT))
    return 0  

  repeat
    value := read_reg(axis)                                      ' read axis or tilt
    ifnot (value & ALERT_BIT)                                    ' if no alert bit
      quit                                                       ' reading okay to use

  return value


pub read_all(p_axes) | regs 
                                  
'' Read all axes and tilt register from MMA7660FC
'' -- p_axes is pointer to array of four longs (x, y, z, tilt)
'' -- writes axis values as signed longs (1/100th-gs) to array at p_axes

  read_all_raw(@regs)                                            ' read raw registers                                            

  long[p_axes][XOUT] := raw_to_gforce(regs.byte[XOUT])           ' convert results
  long[p_axes][YOUT] := raw_to_gforce(regs.byte[YOUT])  
  long[p_axes][ZOUT] := raw_to_gforce(regs.byte[ZOUT])
  long[p_axes][TILT] := regs.byte[TILT]


pub read_all_raw(p_axes)

'' Read all axes and tilt register from MMA7660FC
'' -- p_axes is pointer to a long used as an array of four bytes
'' -- writes axis values as unsigned bytes

  repeat
    i2c.start
    i2c.write(MMA7660_WR)
    i2c.write(XOUT)                                              ' start at X axis
    i2c.start                                                    ' restart
    i2c.write(MMA7660_RD)                                        ' read axis registers
    byte[p_axes][XOUT] := i2c.read(i2c#ACK)
    byte[p_axes][YOUT] := i2c.read(i2c#ACK)
    byte[p_axes][ZOUT] := i2c.read(i2c#ACK)
    byte[p_axes][TILT] := i2c.read(i2c#NAK)
    i2c.stop

    ifnot (long[p_axes] & ALERT_XYZT)                            ' if no alert flags
      quit                                                       '  readings are good


pub side(tbits) 

'' Returns side based on tbits (tilt register bits)
'' -- if tbits < 0, read from MMA7660FC

  if (tbits < 0)
    tbits := read_tilt

  case (tbits & %11)
    %01 : return FRONT
    %10 : return BACK

  return -1                                                      ' error in side bits


pub orientation(tbits)

'' Returns orientation based on tbits (tilt register bits)
'' -- if tbits < 0, read from MMA7660FC

  if (tbits < 0)
    tbits := read_tilt

  case ((tbits >> 2) & %111)
    %001  : return LEFT
    %010  : return RIGHT
    %101  : return DOWN
    %110  : return UP

  return -1                                                      ' error in orientation bits


pub tap(tbits)

'' Returns tap status on tbits (tilt register bits)
'' -- if tbits < 0, read from MMA7660FC

  if (tbits < 0)
    tbits := read_tilt

  return (tbits & TAP_BIT) >> 5


pub shake(tbits)

'' Returns shake status of tbits (tilt register bits)
'' -- if tbits < 0, read from MMA7660FC

  if (tbits < 0)
    tbits := read_tilt

  return (tbits & SHAKE_BIT) >> 7


pub enable(state) | mreg

'' Enable/disable
'' -- put in stand-by mode (mode.0 = 0) for updating other registers

  mreg := read_reg(MODE)

  if (state)
    mreg := mreg & %11111001 | 1                                 ' clear TON, set MODE
  else
    mreg &= %11111000                                            ' clear TON, clear MODE

  write_reg(MODE, mreg)


pub write_reg(reg, value)

'' Write value to MMA7660FC register
                                                                                                      
  i2c.start
  i2c.write(MMA7660_WR)
  i2c.write(reg)                                                 ' set register address
  i2c.write(value)                                               ' write value
  i2c.stop


pub read_reg(reg) | value

'' Read current value of MMA7660FC register

  i2c.start
  i2c.write(MMA7660_WR)
  i2c.write(reg)                                                 ' set register addres
  i2c.start                                                      ' restart
  i2c.write(MMA7660_RD) 
  value := i2c.read(i2c#NAK)                                     ' read value
  i2c.stop

  return value


pub raw_to_gforce(raw)

'' Convert raw axis reading to signed long
'' -- result expressed in 1/100g
'' -- * 100 = 1.00g

  return (raw << 26 ~> 26) * 469 / 100                           ' raw * 4.69


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