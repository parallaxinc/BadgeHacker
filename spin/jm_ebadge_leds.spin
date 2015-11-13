'' =================================================================================================
''
''   File....... jm_ebadge_leds.spin
''   Purpose.... Charlieplex driver for Parallax Electronic Conference Badge (#
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (C) 2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started....
''   Updated.... 12 NOV 2015
''               -- added confirmation return in set methods
''               -- changed rgb references from 2 and 1 to 1 and 0
''               -- added set_rgbn() method 
''
'' =================================================================================================

{{

   Blue LEDs (enable bits in ledbits.byte[0] as %00543210)      

       B5   B4   B3   B2   B1   B0                                      Layout       
       ---  ---  ---  ---  ---  ---                              --------------------
   P8   Z    Z    H    L    H    L                               B5                B0
   P7   L    H    L    Z    Z    H                               B4                B1
   P6   H    L    Z    H    L    Z                               B3                B2


   RGB LEDs (enable bits in ledbits.byte[1] as %00RGBrgb)

       R2   G2   B2   r1   g1   b1                                      Layout   
       ---  ---  ---  ---  ---  ---                              -------------------- 
   P3   H    Z    L    L    Z    H                                   G2        g1  
   P2   L    L    Z    H    H    Z                                                   
   P1   Z    H    H    Z    L    L                                 R2  B2    r1  b1

}}


con { fixed io pins }

  RX1      = 31                                                  ' programming / terminal
  TX1      = 30

  SDA      = 29                                                  ' eeprom / i2c
  SCL      = 28

  BLU_CP2  =  8  { LEDc }                                        ' blue led charlieplex pins 
  BLU_CP1  =  7  { LEDb }
  BLU_CP0  =  6  { LEDa }

  RGB_CP2  =  3  { RGBc }                                        ' rgb led charlieplex pins 
  RGB_CP1  =  2  { RGBb }
  RGB_CP0  =  1  { RGBa }


con { rgb colors }

  OFF     = %000

  BLACK   = %000
  BLUE    = %001
  GREEN   = %010
  CYAN    = %011
  RED     = %100
  MAGENTA = %101
  YELLOW  = %110
  WHITE   = %111


obj


var

  long  cog                                                      ' cog running led driver

  long  ledbits                                                  ' active leds (blue in byte0, rgb in byte1)
  long  cycleticks                                               ' ticks in refresh cycle
  

pub start

'' Start conference badge charlieplex driver

  stop                                                           ' stop cog if running

  ledbits.byte[0] := BLU_CP0                                     ' base of blue group
  ledbits.byte[1] := RGB_CP0                                     ' base of rgb group
  cycleticks      := (clkfreq / 300) / 6                         ' update LEDs at 300Hz 
  
  cog := cognew(@charlie, @ledbits) + 1                          ' start pasm cog
                                                                  
  return cog


pub stop

'' Stops charlieplex cog if running

  if (cog)                                                       ' running?
    cogstop(cog - 1)                                             ' yes, stop it
    cog := 0                                                     ' mark stopped

  ledbits := 0                                                   ' clear led bits (for re-start)


pub blue_on(n)

'' Turns off selected blue LED, 0..5

  if ((n => 0) and (n =< 5))                                     ' valid LED?
    ledbits.byte[0] |= 1 << n                                    ' turn it on  

  return ledbits.byte[0]
  

pub blue_off(n)

'' Turns off selected blue LED, 0..5

  if ((n => 0) and (n =< 5))                                     ' valid LED?
    ledbits.byte[0] &= !(1 << n)                                 ' turn it off

  return ledbits.byte[0]
    

pub set_blue(bits)

'' Set blue LEDs with single value 

  ledbits.byte[0] := bits & %00111111                            ' update all blue LEDs

  return ledbits.byte[0]
  

pub set_rgbn(n, bits)

'' Set rgb module n
'' -- bits passed as 3-bit binary in form: %rgb
''    * see color constants (above)

  if (n == 0)
    return set_rgb0(bits)  
  elseif (n == 1)
    return set_rgb1(bits)   


pub set_rgb0(bits)

'' Set rgb module #0 (right, looking at badge)
'' -- bits passed as 3-bit binary in form: %rgb
''    * see color constants (above)

  ledbits.byte[1] := (ledbits.byte[1] & %00111000) | (bits & %111)

  return ledbits.byte[1]
  
  
pub set_rgb1(bits)

'' Set rgb module #1 (left, looking at badge)
'' -- bits passed as 3-bit binary in form: %rgb
''    * see color constants (above)

  ledbits.byte[1] := (ledbits.byte[1] & %00000111) | ((bits & %111) << 3)

  return ledbits.byte[1] 


pub set_rgbx(bits1, bits0)

'' Set both rgb modules
'' -- bits passed as 3-bit binary in form: %rgb
''    * see color constants (above)

  ledbits.byte[1] := ((bits1 & %111) << 3) | (bits0 & %111)

  return ledbits.byte[1]


pub set_rgb(bits)

'' Set rgb LEDs with single value 

  ledbits.byte[1] := bits & %00111111                            ' update all rgb LEDs

  return ledbits.byte[1]
  

pub set_all(bits)

'' Allows simulateous control of all LEDs
'' -- use 16-bit value as %00rgbrgb_00bbbbbb
''    * upper byte holds rgb LED bits (x2), lower byte holds blue LED bits

  ledbits := bits

  return ledbits


pub clear

'' Clears all LEDs

  ledbits := $00_00                                              ' clear rgb and blue leds

  return ledbits


pub get_blue

'' Return state of blue LEDs

  return ledbits.byte[0]


pub get_rgb

'' return state of rgb leds (packed byte = %00rgbrgb)

  return ledbits.byte[1]


pub get_all

'' Returns all LED bits
'' -- upper byte is rgb modules
'' -- lower byte is blue leds

  return ledbits & %00111111_00111111
  

dat { pasm charlieplex driver }


                        org     0

charlie                 mov     t1, par                          ' t1 = @ledbits
                        rdlong  t2, t1                           ' read pins
                        mov     bluebase, t2                     ' copy to bluebase
                        and     bluebase, #$1F                   ' extract
                        mov     rgbbase, t2                      ' copy to rgbbase
                        shr     rgbbase, #8                      ' extract
                        and     rgbbase, #$1F
                        add     t1, #4                           ' t1 = @cycletick
                        rdlong  cycletix, t1                     ' read cycle ticks

                        mov     t1, #0                           ' clear ledbits
                        wrlong  t1, par

                        
                        mov     cycletimer, cycletix             ' start cycle timer
                        add     cycletimer, cnt

                        mov     cidx, #0                         ' initialize cycle index

                        
cp_main                 rdlong  ctrlbits, par                    ' read ledbits

                        mov     ledmask, #1                      ' create mask for this cycle
                        shl     ledmask, cidx                           

                        
check_blue              test    ctrlbits, ledmask       wc       ' current (cidx) led on?
                        mov     bluouts, #0                      ' clear temp regs         
                        mov     bludirs, #0                                                
        if_nc           jmp     #check_rgb                       ' if C = 0, leave off

                        mov     t1, #case_blue_0                 ' point to blue jump table
                        add     t1, cidx                         ' update for current index
                        jmp     t1                               ' jump to current led

case_blue_0             jmp     #blue_0
case_blue_1             jmp     #blue_1
case_blue_2             jmp     #blue_2
case_blue_3             jmp     #blue_3
case_blue_4             jmp     #blue_4
case_blue_5             jmp     #blue_5
 
blue_0                  mov     bluouts, #%010                   ' CP2 = L, CP1 = H, CP0 = Z   
                        mov     bludirs, #%110                                                      
                        jmp     #check_rgb 
                        
blue_1                  mov     bluouts, #%100                   ' CP2 = H, CP1 = Z, CP0 = L          
                        mov     bludirs, #%101                                                          
                        jmp     #check_rgb                                                              
                        
blue_2                  mov     bluouts, #%001                   ' CP2 = L, CP1 = Z, CP0 = H           
                        mov     bludirs, #%101                                                          
                        jmp     #check_rgb 

blue_3                  mov     bluouts, #%100                   ' CP2 = H, CP1 = L, CP0 = Z          
                        mov     bludirs, #%110                                                          
                        jmp     #check_rgb

blue_4                  mov     bluouts, #%010                   ' CP2 = Z, CP1 = H, CP0 = L           
                        mov     bludirs, #%011                                                          
                        jmp     #check_rgb

blue_5                  mov     bluouts, #%001                   ' CP2 = Z, CP1 = L, CP0 = H             
                        mov     bludirs, #%011                                                               
'                       jmp     #check_rgb                                                   
                       

check_rgb               shl     ledmask, #8                      ' update mask for ctrlbits.byte[1]
                        mov     rgbouts, #0                      ' clear temp regs
                        mov     rgbdirs, #0  
                        test    ctrlbits, ledmask       wc       ' current (cidx) led on?
        if_nc           jmp     #update_leds                     ' if C = 0, leave off

                        mov     t1, #case_rgb_b1                 ' point to rgb jump table
                        add     t1, cidx                         ' update for current index
                        jmp     t1                               ' jump to current led

case_rgb_b1             jmp     #rgb_b1
case_rgb_g1             jmp     #rgb_g1
case_rgb_r1             jmp     #rgb_r1
case_rgb_b2             jmp     #rgb_b2
case_rgb_g2             jmp     #rgb_g2
case_rgb_r2             jmp     #rgb_r2

rgb_b1                  mov     rgbouts, #%100                   ' CP2 = H, CP1 = Z, CP0 = L        
                        mov     rgbdirs, #%101                                                                    
                        jmp     #update_leds                       

rgb_g1                  mov     rgbouts, #%010                   ' CP2 = Z, CP1 = H, CP0 = L        
                        mov     rgbdirs, #%011                                                                     
                        jmp     #update_leds                                                 

rgb_r1                  mov     rgbouts, #%010                   ' CP2 = L, CP1 = H, CP0 = Z         
                        mov     rgbdirs, #%110                                                                     
                        jmp     #update_leds          

rgb_b2                  mov     rgbouts, #%001                   ' CP2 = L, CP1 = Z, CP0 = H           
                        mov     rgbdirs, #%101                                                                      
                        jmp     #update_leds  

rgb_g2                  mov     rgbouts, #%001                   ' CP2 = Z, CP1 = L, CP0 = H           
                        mov     rgbdirs, #%011                                                                     
                        jmp     #update_leds 

rgb_r2                  mov     rgbouts, #%100                   ' CP2 = H, CP1 = L, CP0 = Z       
                        mov     rgbdirs, #%110                                                                  
'                       jmp     #update_leds 


update_leds             mov     dira, #0                         ' prevent ghosting

                        shl     bluouts, bluebase                ' setup touts with blue
                        mov     touts, bluouts
                        shl     bludirs, bluebase                ' setup tdirs for blue
                        mov     tdirs, bludirs

                        shl     rgbouts, rgbbase                 ' add rgb to touts
                        or      touts, rgbouts
                        shl     rgbdirs, rgbbase                 ' add rgb to tdirs
                        or      tdirs, rgbdirs                        

                        mov     outa, touts                      ' update outputs
                        mov     dira, tdirs                      ' update dirs

                        add     cidx, #1                         ' update cycle
                        cmp     cidx, #6                wc, wz   ' roll-over 5 --> 0 if needed
        if_e            mov     cidx, #0

                        waitcnt cycletimer, cycletix             ' let cycle time expire

                        jmp     #cp_main                         ' back to top

                        
' -------------------------------------------------------------------------------------------------

bluebase                res     1                                ' base pin of blue group
rgbbase                 res     1                                ' base pin of rgb group

cycletix                res     1                                ' time between LED updates
cycletimer              res     1                                ' for timing led cycle
cidx                    res     1                                ' cycle index

ctrlbits                res     1                                ' led control bits
ledmask                 res     1                                ' mask to test LED status

bluouts                 res     1                                ' blue charlieplex outputs
bludirs                 res     1
rgbouts                 res     1                                ' rgb charlieplex outputs
rgbdirs                 res     1
touts                   res     1                                ' outputs for this cycle
tdirs                   res     1                                ' dirs for current cycle

t1                      res     1                                ' work vars
t2                      res     1

                        fit     496
                        

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