'' =================================================================================================
''
''   File....... jm_fullduplexserial.spin
''   Purpose.... Buffered serial communications
''   Authors.... Chip Gracey, Jeff Martin, Daniel Harris 
''               -- reformatted and minor updates to PASM code by Jon McPhalen
''               -- see below for terms of use
''   E-mail.....  
''   Started.... 
''   Updated.... 07 OCT 2014
''
'' =================================================================================================

{{

   Revisions:

     07 OCT 2014 - Reformatted by Jon McPhalen
                 - updated buffer size
                 - includes rjdec() method for right-justified decimal values

     01 MAY 2011 - additional comments added

     07 MAY 2009 - Fixed bug in dec method causing largest negative value
                    (-2,147,483,648) to be output as -0

     01 MAR 2006 - Initial release


   Connections:
   
             3.9K
     rxpin ───── TTL level RX line (5.0v tolerant with 3.9K)      
     txpin ─────── TTL level TX line (3.3v)

     For open-drain/source connections use a 3.3K-10K pull-up (open-drain) or
     pull-down (open-source) resistor on RX and TX line(s)

}}


con { fixed io pins }

  RX1 = 31                                                       ' programming / terminal
  TX1 = 30
  
  SDA = 29                                                       ' eeprom / i2c
  SCL = 28


con { buffer setting }

  BUF_SIZE = 256                                                 ' 16, 32, 64, 128, 256, or 512
  BUF_MASK = BUF_SIZE - 1

  
con { pst formatting }

  HOME    =  1
  GOTOXY  =  2
  CRSR_LF =  3
  CRSR_RT =  4
  CRSR_UP =  5
  CRSR_DN =  6
  BELL    =  7
  BKSP    =  8
  TAB     =  9
  LF      = 10
  CLREOL  = 11
  CLRDN   = 12
  CR      = 13
  GOTOX   = 14
  GOTOY   = 15
  CLS     = 16


var { object globals }

  long  cog                                                      ' cog (+1) running uart code

  ' 9 longs, MUST be contiguous
  
  long  rxhead                 
  long  rxtail
  long  txhead
  long  txtail
  long  rxpin
  long  txpin
  long  rxtxmode
  long  bitticks
  long  bufpntr
                     
  byte  rxbuffer[BUF_SIZE]                                       ' transmit and receive buffers
  byte  txbuffer[BUF_SIZE] 


pub null

  ' This is not a top-level object
  

pub start(rxp, txp, mode, baudrate)

'' Start serial driver (uses a cog, returns 1 to 8 if successful)
'' -- rxp.... recieve pin (0..31)
'' -- txp.... transmit pin (0..31)
'' -- mode... %xxx1 = invert rx
''            %xx1x = invert tx
''            %x1xx = open-drain/open-source tx
''            %1xxx = ignore tx echo on rx (for half-duplex on one pin)

  stop                                                           ' stop if running
                                                                  
  longfill(@rxhead, 0, 4)                                        ' clear buffer indexes
  longmove(@rxpin, @rxp, 3)                                      ' copy pins and mode
  bitticks := clkfreq / baudrate                                 ' system ticks per bit
  bufpntr := @rxbuffer                                           ' hub address of rxbuffer
                                                                  
  cog := cognew(@fdsuart, @rxhead) + 1                           ' start the fds uart cog
                                                                  
  return cog


pub stop

'' Stop serial driver - frees a cog

  if (cog)
    cogstop(cog - 1)
    cog := 0


pub rxflush

'' Flush receive buffer

  repeat while (rxcheck => 0)
  
    
pub rxcheck | rxbyte

'' Check if byte received (never waits)
'' returns -1 if no byte received, $00..$FF if byte

  rxbyte := -1                                                   ' assume no byte ready
                                                                  
  if (rxtail <> rxhead)                                          ' if byte(s) in buffer                                      
    rxbyte := rxbuffer[rxtail]                                   ' get next available
    rxtail := ++rxtail & BUF_MASK                                ' increment pointer, wrap if needed
                                                                  
  return rxbyte


pub rxtime(ms) | t, rxbyte

'' Wait ms milliseconds for a byte to be received
'' returns -1 if no byte received, $00..$FF if byte

  t := cnt
  repeat until ((rxbyte := rxcheck) => 0) or ((cnt - t) / (clkfreq / 1000) > ms)

  return rxbyte


pub rxticks(tix) | t, rxbyte

'' Wait tix system ticks for a byte to be received               ' added by Jon McPhalen (MODBUS support)
'' returns -1 if no byte received, $00..$FF if byte

  t := cnt
  repeat until ((rxbyte := rxcheck) => 0) or ((cnt - t) / tix)

  return rxbyte  


pub rx | rxbyte

'' Receive byte (may wait for byte)
'' returns $00..$FF

  repeat while ((rxbyte := rxcheck) < 0)

  return rxbyte


pub txflush

'' Wait for transmit buffer to empty, then wait for byte to transmit

  repeat until (txtail == txhead)
  repeat 11                                                      ' start + 8 + 2
    waitcnt(bitticks + cnt)


pub tx(txbyte)

'' Send byte
'' -- may wait for room in buffer 

  repeat until (txtail <> (txhead + 1) & BUF_MASK)               ' wait for room in buffer
  txbuffer[txhead] := txbyte                                     ' move byte to buffer
  txhead := ++txhead & BUF_MASK                                  ' increment buffer index, wrap if needed
                                                                  
  if (rxtxmode & %1000)                                          ' if half-duplex on same pin
    rx                                                           '  pull tx'd byte from rx buffer
                                                                  

pub str(p_zstr)

'' Send string                    

  repeat strsize(p_zstr)
    tx(byte[p_zstr++])


pub dec(value) | divisor, x

'' Print a decimal number

  x := (value == NEGX)                                           ' check for max negative
  if (value < 0)                                                    
    value := ||(value+x)                                         ' if negative, make positive; adjust for max negative
    tx("-")                                                      ' and output sign
                                                                  
  divisor := 1_000_000_000                                       ' initialize divisor
                                                                  
  repeat 10                                                      ' loop for 10 digits
    if (value => divisor)                                                 
      tx(value / divisor + "0" + x*(divisor == 1))               ' if non-zero digit, output digit; adjust for max negative
      value //= divisor                                          ' and digit from value
      result~~                                                   ' flag non-zero found
    elseif (result or (divisor == 1))                                     
      tx("0")                                                    ' if zero digit (or only digit) output it
    divisor /= 10                                                ' update divisor


pub rjdec(val, width, pchar) | tmpval, pad

'' Print right-justified decimal value
'' -- val is value to print
'' -- width is width of (padded) field for value
'' -- pchar is [leading] pad character (usually "0" or " ")

'  Original code by Dave Hein
'  Added (with modifications) to FDS by Jon McPhalen

  if (val => 0)                                                  ' if positive
    tmpval := val                                                '  copy value
    pad := width - 1                                             '  make room for 1 digit
  else                                                            
    if (val == NEGX)                                             '  if max negative
      tmpval := POSX                                             '    use max positive for width
    else                                                         '  else
      tmpval := -val                                             '    make positive
    pad := width - 2                                             '  make room for sign and 1 digit
                                                                  
  repeat while (tmpval => 10)                                    ' adjust pad for value width > 1
    pad--                                                         
    tmpval /= 10                                                  
                                                                  
  repeat pad                                                     ' print pad
    tx(pchar)                                                     
                                                                  
  dec(val)                                                       ' print value

  
pub hex(value, digits)

'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


pub bin(value, digits)

'' Print a binary number

  value <<= 32 - digits
  repeat digits
    tx((value <-= 1) & 1 + "0")

    
dat { pasm driver }

                        org     0

fdsuart                 mov     r1, par                          ' get structure address
                        add     r1, #16                          ' skip past heads and tails (4 longs)
                                                                  
                        rdlong  r2, r1                           ' get rxpin
                        mov     rxmask, #1                       ' convert to mask
                        shl     rxmask, r2                        
                                                                  
                        add     r1, #4                           ' get txpin
                        rdlong  r2, r1                            
                        mov     txmask, #1                       ' convert to mask
                        shl     txmask, r2                        
                                                                  
                        add     r1, #4                           ' get rxtxmode
                        rdlong  iomode, r1                        
                                                                  
                        add     r1, #4                           ' get bitticks
                        rdlong  bittix, r1                        
                                                                  
                        add     r1, #4                           ' get bufpntr
                        rdlong  rxhub, r1                         
                        mov     txhub, rxhub                      
                        add     txhub, #BUF_SIZE                  
                                                                  
                        test    iomode, #%0100          wz       ' init tx pin according to mode
                        test    iomode, #%0010          wc        
        if_z_ne_c       or      outa, txmask                      
        if_z            or      dira, txmask                      
                                                                  
                        mov     txcode, #transmit                ' initialize ping-pong multitasking
                                                                  
                                                                  
' -----------------                                               
'  Receive Process                                                
' -----------------                                               
'                                                                 
receive                 jmpret  rxcode, txcode                   ' run a chunk of transmit code, then return
                                                                  
                        test    iomode, #%0001          wz       ' wait for start bit on rx pin
                        test    rxmask, ina             wc        
        if_z_eq_c       jmp     #receive                          
                                                                  
                        mov     rxbits, #9                       ' ready to receive byte
                        mov     rxcnt, bittix                     
                        shr     rxcnt, #1                         
                        add     rxcnt, cnt                           
                                                                  
:bit                    add     rxcnt, bittix                    ' ready next bit period
                                                                  
:wait                   jmpret  rxcode, txcode                   ' run a chuck of transmit code, then return
                                                                  
                        mov     r1, rxcnt                        ' check if bit receive period done
                        sub     r1, cnt                           
                        cmps    r1, #0                  wc        
        if_nc           jmp     #:wait                            
                                                                  
                        test    rxmask, ina             wc       ' receive bit on rx pin
                        rcr     rxdata, #1                        
                        djnz    rxbits, #:bit                     
                                                                  
                        shr     rxdata, #32-9                    ' justify and trim received byte
                        and     rxdata, #$FF                      
                        test    iomode, #%0001          wz       ' if rx inverted, invert byte
        if_nz           xor     rxdata, #$FF                      
                                                                  
                        rdlong  r2, par                          ' save received byte and inc head
                        add     r2, rxhub                         
                        wrbyte  rxdata, r2                        
                        sub     r2, rxhub                         
                        add     r2, #1                            
                        and     r2, #BUF_MASK                    ' wrap buffer index back to 0
                        wrlong  r2, par                           
                                                                  
                        jmp     #receive                         ' byte done, receive next byte
                                                                  
                                                                  
' ------------------                                              
'  Transmit Process                                               
' ------------------                                              
'                                                                 
transmit                jmpret  txcode, rxcode                   ' run a chunk of receive code, then return
                                                                  
                        mov     r1, par                          ' check for head <> tail
                        add     r1, #8                            
                        rdlong  r2, r1                           ' r1 = @txhead
                        add     r1, #4                            
                        rdlong  r3, r1                           ' r1 = @txtail
                        cmp     r2, r3                  wz       ' equal?
        if_z            jmp     #transmit                        ' if yes, check again
                                                                  
                        add     r3, txhub                        ' get byte and inc tail
                        rdbyte  txdata, r3                        
                        sub     r3, txhub                         
                        add     r3, #1                            
                        and     r3, #BUF_MASK                    ' wrap buffer index back to 0   
                        wrlong  r3, r1                            
                                                                  
                        or      txdata, STOP_BITS                ' add stop bit(s)
                        shl     txdata, #1                       ' add start bit
                        mov     txbits, #11                      ' bits = start + 8 + 2 stop
                        mov     txcnt, cnt                        
                                                                  
:bit                    test    iomode, #%0100          wz       ' output bit on tx pin according to mode
                        test    iomode, #%0010          wc        
        if_z_and_c      xor     txdata, #1                        
                        shr     txdata, #1              wc        
        if_z            muxc    outa, txmask                      
        if_nz           muxnc   dira, txmask                      
                        add     txcnt, bittix                    ' ready next cnt
                                                                  
:wait                   jmpret  txcode, rxcode                   ' run a chunk of receive code, then return
                                                                  
                        mov     r1, txcnt                        ' check if bit transmit period done
                        sub     r1, cnt                           
                        cmps    r1, #0                  wc        
        if_nc           jmp     #:wait                            
                                                                  
                        djnz    txbits, #:bit                    ' another bit to transmit?
                                                                  
                        jmp     #transmit                        ' byte done, transmit next byte

' --------------------------------------------------------------------------------------------------

STOP_BITS               long    $FFFF_FF00


iomode                  res     1                                ' mode bits
bittix                  res     1                                ' ticks per bit
                                                                  
rxmask                  res     1                                ' mask for rx pin
rxhub                   res     1                                ' hub address of rxbuffer                             ' 
rxdata                  res     1                                ' received byte
rxbits                  res     1                                ' bit counter for rx
rxcnt                   res     1                                ' bit timer for rx
rxcode                  res     1                                ' cog pointer for rx process
                                                                  
txmask                  res     1                                ' mask for tx pin
txhub                   res     1                                ' hub address of txbuffer
txdata                  res     1                                ' byte to transmit
txbits                  res     1                                ' bit counter for tx
txcnt                   res     1                                ' bit timer for tx
txcode                  res     1                                ' cog pointer for tx process
                                                                  
r1                      res     1                                ' working registers
r2                      res     1                                 
r3                      res     1

                        fit     496


dat { license }

{{

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