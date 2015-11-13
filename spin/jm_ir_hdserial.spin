'' =================================================================================================
''
''   File....... jm_ir_hdserial.spin
''   Purpose.... Half-duplex, true-mode serial IO or IR
''   Author..... Jon "JonnyMac" McPhalen 
''               Copyright (c) 2009-2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 28 JUL 15
''
'' =================================================================================================

{{

    Example IR Connections
 
              ┌───┐
              │(*)│ 3.3-5v (device dependent)
              └┬┬┬┘ 
         rx ──┘│└──┘
                


              IR
      3.3v ──────┐
                    │
        tx ──────┘
               33


              33  IR
        tx ───────┐
                            

}}


con { configuration }

  BUF_SIZE = 128                                                 ' power of 2  (2..512)
  BUF_MASK = BUF_SIZE - 1
    

var

  long  cog                                                      ' cog flag/id

  long  rxhead                                                   ' rx head index
  long  rxtail                                                   ' rx tail index
  long  rxhub                                                    ' hub address of rxbuf
  
  long  txhead                                                   ' tx head index
  long  txtail                                                   ' tx tail index
  long  txhub                                                    ' hub address of txbuf

  long  rxpin                                                    ' rx pin (in)
  long  txpin                                                    ' tx pin (out)
  long  bitticks                                                 ' bit timing (ticks)
  long  frsetup                                                  ' ctrx setup for freq

  byte  rxbuf[BUF_SIZE]                                          ' rx and tx buffers
  byte  txbuf[BUF_SIZE]


pub start(rxd, txd, baud, freq) 

'' Half-duplex, true mode UART 
'' -- rxd is rx pin (in)
'' -- txd is tx pin (out)
'' -- baud is baud rate for coms (2400 suggested)
'' -- freq is IR modulation frequency (e.g., 38000)

  stop                                                           ' stop UART driver
                                                                  
  longfill(@rxhead, 0, 6)                                        ' clear (for restart)

  rxhub := @rxbuf                                                ' provide buffer locations                                              
  txhub := @txbuf  

  longmove(@rxpin, @rxd, 2)                                      ' copy pins
                                                                  
  bitticks := clkfreq / baud                                     ' set bit time for baud rate
  frsetup  := ($8000_0000 / (clkfreq / freq)) << 1               ' modulation setup              
                                                              
  dira[rxd] := 0                                                 ' disable pins in calling cog
  dira[txd] := 0                                                  
                                                 
  cog := cognew(@irhds, @rxhead) + 1                             ' start UART cog

  return cog


pub stop

'' Stops IR UART cog

  if (cog)
    cogstop(cog - 1)
    cog := 0


con

  { --------------------- }
  {  R X   M E T H O D S  }
  { --------------------- }
  

pub rx | c

'' Pulls c from receive buffer if available
'' -- will wait if buffer is empty

  repeat while (rxtail == rxhead)
  c := rxbuf[rxtail]
  rxtail := ++rxtail & BUF_MASK

  return c
  

pub rxcheck | c

'' Pulls c from receive buffer if available
'' -- returns -1 if buffer is empty

  c := -1

  if (rxtail <> rxhead)                                          ' something in buffer?
    c := rxbuf[rxtail]                                           ' get it
    rxtail := ++rxtail & BUF_MASK                                ' update tail pointer
                                                                  
  return c


pub rxtime(ms) | t, c

'' Wait ms milliseconds for a byte to be received
'' -- returns -1 if no byte received, $00..$FF if byte

  t := cnt
  repeat until ((c := rxcheck) => 0) or ((cnt - t) / (clkfreq / 1000) > ms)

  return c


pub rxflush

'' Flush receive buffer

  repeat while (rxcheck => 0)


con

  { --------------------- }
  {  T X   M E T H O D S  }
  { --------------------- }


pub tx(c)

'' Move c into transmit buffer if room is available
'' -- will wait if buffer is full

  repeat until (txtail <> ((txhead + 1) & BUF_MASK))
  txbuf[txhead] := c
  txhead := ++txhead & BUF_MASK


pub str(p_zstr)

'' Transmit z-string at pntr

  repeat strsize(p_zstr)
    tx(byte[p_zstr++])
    
    
pub dec(value) | i, x                  
                                       
'' Transmit a value in decimal format              
                                       
  x := (value == negx)                                           ' mark max negative
                     
  if (value < 0)                                                 ' if negative                   
    value := ||(value + x)                                       ' make positive and adjust
    tx("-")                                                      ' print sign
                                                                  
  i := 1_000_000_000                                             ' set divisor
                                                                  
  repeat 10                                                       
    if value => i                                                ' non-zero digit for this divisor?                  
      tx(value / i + "0" + x * (i == 1))                         '  print digit                    
      value //= i                                                '  remove from value
      result~~                                                   '  set printing flag                      
    elseif ((result) or (i == 1))                                ' if printing or last digit            
      tx("0")                                                    '  print zero
    i /= 10                                                      ' update divisor

  
pub rjdec(val, width, pchar) | tmpval, pad

'' Transmit right-justified decimal value
'' -- val is value to print
'' -- width is width of (pchar padded) field for value

'  Original code by Dave Hein
'  Modified by Jon McPhalen

  if (val => 0)                                                  ' if positive
    tmpval := val                                                '  copy value
    pad := width - 1                                             '  make room for 1 digit
  else                                                            
    if (val == negx)                                             '  if max negative
      tmpval := posx                                             '    use max positive for width
    else                                                         '  else
      tmpval := -val                                             '    make positive
    pad := width - 2                                             '  make room for sign and 1 digit
                                                                  
  repeat while (tmpval => 10)                                    ' adjust pad for value width > 1
    pad--                                                         
    tmpval /= 10                                                  
                                                                  
  repeat pad                                                     ' transmit pad
    tx(pchar)                                                       
                                                                  
  dec(val)                                                       ' trasnmit value

  
pub hex(value, digits)

'' Transmit a value in hexadecimal format              

  value <<= (8 - digits) << 2
  repeat digits
    tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


pub tx_bin(value, digits)

'' Transmit a value in binary format              

  value <<= (32 - digits)
  repeat digits
    tx((value <-= 1) & 1 + "0")       


pub txflush

'' Wait for transmit buffer to empty, then wait for byte to transmit

  repeat until (txtail == txhead)
  repeat 11                                                      ' start + 8 + 2
    waitcnt(bitticks + cnt)


con

  { ----------------------------- }
  {  I R   U A R T   D R I V E R  }
  { ----------------------------- } 
  

dat { ir uart }

                        org     0

irhds                   mov     t1, par                          ' start of structure
                        mov     rxheadpntr, t1                   ' save hub address of rxhead
                                                                  
                        add     t1, #4                            
                        mov     rxtailpntr, t1                   ' save hub address of rxtail

                        add     t1, #4                            
                        rdlong  rxbufpntr, t1                    ' read address of rxbuf[0]
                                                          
                        add     t1, #4                            
                        mov     txheadpntr, t1                   ' save hub address of txhead
                                                                  
                        add     t1, #4                            
                        mov     txtailpntr, t1                   ' save hub address of txtail
                                                                  
                        add     t1, #4                            
                        rdlong  txbufpntr, t1                    ' read address of txbuf[0]
                          
                        add     t1, #4                            
                        rdlong  t2, t1                           ' get rxpin
                        mov     rxmask, #1                       ' make pin mask
                        shl     rxmask, t2                        
                        andn    dira, rxmask                     ' force to input
                                                                  
                        add     t1, #4                            
                        rdlong  t2, t1                           ' get txpin
                        mov     txmask, #1                       ' make pin mask
                        shl     txmask, t2
                        andn    dira, txmask                     ' disable modulation

                        add     t1, #4                            
                        rdlong  bit1x0tix, t1                    ' read 1.0 bit timing
                        mov     bit1x5tix, bit1x0tix             ' create 1.5 bit timing
                        shr     bit1x5tix, #1                     
                        add     bit1x5tix, bit1x0tix   

                        add     t1, #4                           ' get mod frequency
                        rdlong  frqa, t1                         ' setup ctra modulation
                        or      t2, NCO_SE                       ' on tx pin
                        mov     ctra, t2                         ' activate counter



' =========                                                       
'  RECEIVE                                                        
' =========                                                       
                                                                  
rxserial                mov     rxtimer, cnt                     ' start timer 
                        test    rxmask, ina             wc       ' look for start bit
        if_c            jmp     #txserial                        ' if no start, check tx
                                                                  
receive                 add     rxtimer, bit1x5tix               ' skip start bit
                        mov     rxwork, #0                       ' clear work var
                        mov     rxcount, #8                      ' rx 8 bits     
                                                                  
rxbyte                  waitcnt rxtimer, bit1x0tix               ' wait for middle of bit
                        test    rxmask, ina             wc       ' rx --> c
                        shr     rxwork, #1                       ' prep for next bit
                        muxc    rxwork, #%1000_0000              ' add bit to rxwork
                        djnz    rxcount, #rxbyte

                        waitcnt rxtimer, #0                      ' let last bit finish
                        test    rxmask, ina             wc       ' verify stop bit
        if_nc           jmp     #txserial                        ' skip if bad IR input
                                                                  
putrxbuf                rdlong  t1, rxheadpntr                   ' t1 := rxhead
                        add     t1, rxbufpntr                    ' t1 := rxbuf[rxhead]
                        wrbyte  rxwork, t1                       ' rxbuf[rxhead] := rxwork
                        sub     t1, rxbufpntr                    ' t1 := rxhead 
                        add     t1, #1                           ' inc t1
                        and     t1, #BUF_MASK                    ' rollover if needed
                        wrlong  t1, rxheadpntr                   ' rxhead := t1
                                          
                                                                  
                                                                  
' ==========
'  TRANSMIT
' ==========

txserial                rdlong  t1, txheadpntr                   ' t1 = txhead  
                        rdlong  t2, txtailpntr                   ' t2 = txtail
                        cmp     t1, t2                  wz       ' byte(s) to tx?
        if_z            jmp     #rxserial                        ' check rx
                                                                  
gettxbuf                mov     t1, txbufpntr                    ' t1 := @txbuf[0]
                        add     t1, t2                           ' t1 := @txbuf[txtail]
                        rdbyte  txwork, t1                       ' txwork := txbuf[txtail] 
                                                                  
updatetxtail            add     t2, #1                           ' inc txtail
                        and     t2, #BUF_MASK                    ' wrap to 0 if necessary
                        wrlong  t2, txtailpntr                   ' save
                                                                  
transmit                or      txwork, STOP_BITS                ' set stop bit(s)
                        shl     txwork, #1                       ' add start bit
                        mov     txcount, #11                     ' start + 8 data + 2 stop
                        mov     txtimer, bit1x0tix               ' load bit timing
                        add     txtimer, cnt                     ' sync with system counter
                                                                  
txbit                   shr     txwork, #1              wc       ' move bit0 to C
                        muxnc   dira, txmask                     ' enable modulation if C == 0
                        waitcnt txtimer, bit1x0tix               ' let timer expire, reload   
                        djnz    txcount, #txbit                  ' update bit count

                        jmp     #txserial                         
                                                                  
                                                                  
' -------------------------------------------------------------------------------------------------

NCO_SE                  long    %00100 << 26                     ' S/E NCO mode  
STOP_BITS               long    $FFFF_FF00                        

rxheadpntr              res     1                                ' head pointer
rxtailpntr              res     1                                ' tail pointer
rxbufpntr               res     1                                ' hub address of rxbuf[0]
txheadpntr              res     1                                ' head pointer
txtailpntr              res     1                                ' tail pointer
txbufpntr               res     1                                ' hub address of txbuf[0]
                                                                
rxmask                  res     1                                ' rx pin mask
txmask                  res     1                                ' tx pin mask
bit1x0tix               res     1                                ' 1.0 bit timing
bit1x5tix               res     1                                ' 1.5 bit timing  

rxwork                  res     1                                ' rx byte in
rxcount                 res     1                                ' bits to receive
rxtimer                 res     1                                ' timer for bit sampling

txwork                  res     1                                ' tx byte out
txcount                 res     1                                ' bits to transmit
txtimer                 res     1                                ' timer for bit output
                                                                  
t1                      res     1                                ' work vars
t2                      res     1                                 
t3                      res     1                                 
                                 
                        fit     496
                        

dat { license }

{{

  Copyright (C) 2009-2015 Jon McPhalen

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