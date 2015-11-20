'' =================================================================================================
''
''   File....... jm_time.spin
''   Purpose.... Asyncrhonous (accumulator) timer
''               -- methods must be called every ~53.686s (@80MHz) or sooner to prevent error
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2014-2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 29 SEP 2015
''
'' =================================================================================================


var

  long  sync                                                     ' sync point (snapshot of cnt)
  long  msecs                                                    ' milliseconds accumulator
  long  rawtix                                                   ' timing (ticks) accumulator
  long  holdstate                                                ' when <> 0, time on hold


dat

  ' these values are common across all copies of the object type

  ustix       long      0                                        ' ticks per microsecond    
  mstix       long      0                                        ' ticks per millisecond
  posxms      long      0                                        ' millis in posx
  deltatix    long      0                                        ' tix delta for rollover      


pub null

  ' This is not a top-level object
  
  
pub start 

'' Start or restart the timer object

  return startx(cnt)                                             ' start now
                                                                  
                                                                  
pub startx(now)
                                                                  
'' Start the timer object with specific sync point                
'' -- for synchronizing with another timer
                                            
  sync     := now                                                ' set sync point
  ustix    := clkfreq / 1_000_000                                ' set ticks/microsecond
  mstix    := clkfreq / 1_000                                    ' set ticks/millisecond
  posxms   := posx / mstix                                       ' millis in posx
  deltatix := posx + (posx // mstix) + 2                         ' delta correction for rollover

  longfill(@msecs, 0, 2)                                         ' clear msecs, rawtix { no longer clears hold }
                                                                  
  return sync


pub set(ms)

'' Sets the timer with ms milliseconds
'' -- hold state is maintained

  startx(cnt)
  msecs := ms


pub set_secs(secs)

'' Sets the timer with s seconds
'' -- hold state is maintained

  startx(cnt)
  msecs := secs * 1000

  
pub millis

'' Returns milliseconds accumulator

  return mark                                                    ' return milliseconds
                                                                  
                                                                  
pub seconds                                                       
                                                                  
'' Returns seconds (from ms accumulator)                          

  return mark / 1_000                                            ' return seconds


pub adjust(ms)

'' Adjust milliseconds register

  mark

  msecs += ms


pub adjust_secs(secs)

'' Adjust ms register by seconds

  mark

  msecs += (secs * 1000) 


pub mark | now, delta 

'' Marks the current point
'' -- updates ticks and ms accumulators
'' -- returns current milliseconds

  now := cnt                                                     ' capture cnt

  if (holdstate)                                                 ' if held
    return msecs                                                 '  do not update ms

  delta := now - sync                                            ' delta since last capture
                                                                  
  ' Note on correction when delta is negative                     
  ' -- NEGX (2^31) == POSX+1                                    
  ' -- POSX is used twice in delta correction, hence the +2       
                                                                  
  if (delta < 0)                                                 ' rollover past posx?
    msecs += posxms   { posx / mstix }                           ' add posx millis
    delta += deltatix { posx + (posx // mstix) + 2 }             ' correct delta
                                                                  
  rawtix += delta                                                ' increment ticks
  msecs += rawtix / mstix                                        ' update millis
  rawtix //= mstix                                               ' udpate ticks    
                                                                  
  sync := now                                                    ' reset sync point
                                                                  
  return msecs                                                   ' return millis
                                                                  

pub sync_point 

'' Returns sync point
'' -- used to syncronize multiple timers

  if (holdstate)
    return cnt                                                   ' sync not valid if on hold
  else
    return sync


pub hold 

'' Puts timer in hold state
'' -- msecs frozen at present time

  holdstate := true


pub release 

'' Releases timer to run with mark(ed) methods

  sync := cnt
  longfill(@rawtix, 0, 2)                                        ' clear rawtix, holdstate
  

pub on_hold 

'' Returns true when timer is in hold state

  return holdstate
  
  
pub pause(ms) | t

'' Pause ms milliseconds
'' -- must be positive!
     
  t := cnt - 1168                                                ' sync with overhead correction
  repeat ms                                                       
    waitcnt(t += mstix)                                          ' wait 1ms
                                                                  
                                                                  
pub pause_us(us)                                                  

'' Pause us microseconds
'' -- must be positive, minimum of ~50us (@80MHz)
'' -- if too low, program will hang

  waitcnt(cnt + (us * ustix) - 992)
  
    
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