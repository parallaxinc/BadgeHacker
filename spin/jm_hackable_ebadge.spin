'' =================================================================================================
''
''   File....... jm_hackable_ebadge__2015-11-19.spin
''   Purpose.... Demo code for Parallax Hackable badge
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (C) 2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started....
''   Updated.... 19 NOV 2015
''
'' =================================================================================================

{
  19 NOV 2015 -- Changed default value of ResetDB to NO
                 * badge does not clear contacts when reprogrammed

  17 NOV 2015 -- Modified contact transmission for improved reliability
              -- Changed PING response per Brett for better BadgeHacker cooperation
              -- update object filenames for x-platform compatibility

  12 NOV 2015 -- Added LED settings persistence between power cycles

  08 NOV 2015 -- Updates to assist BadgeHacker
                 * added blank start-up message (CLS [#16], CLRDN [#12])
                   -- when AUTO_ME is NO
                 * all messages termianted with CLRDN [#12]
                 * added WIPE option to CONTACTS

  05 NOV 2015 -- Modified show_logo method to add flashing rgb lights
              -- added AUTO_ME switch (set to NO to stop ME display after setting user string)
              -- removed call to lamp test

  04 NOV 2015 -- Accelerometer mode disabled
                 Shaking badge re-displays logo
                 Original behavior easy to restore 
}


{

  This badge demo has two modes:

  0 (default) This displays your name on the OLED. If you press the OSH logo on the badge, your
    contact information will be transmitted via IR to other badges (they should be within a few
    feet and facing you). Likewise, your badge can receive contact information from other badges.
    If your badge receives a contact that is already stored, it will be ignored. This allows the
    badge to store up to 250 unique contacts. These contacts are stored in the upper 32K of the
    64K EEPROM; this means they are safe from being overwritten should you wish to experiment with
    other applications on the badge. Restore this code to see the contacts. Viewing contacts is
    done by connecting the badge to a terminal set to 115200 baud. Open the terminal and then enter
    the word CONTACTS followed by a the [Enter] key (see commands below).

  1 This mode displays X and Y accelerometer information as 0.0 (flat) to 90.0 (on an edge) degrees. 
    The value is signed based on the direction of tilt. The RGB LEDs (left for X, right for Y) will
    be green, yellow, or red depending on tilt (0 is green). The blue LEDs behave like a rotating
    bubble level.


    To switch between modes, shake the firmly for about 1/4 second. After switching modes, the
    badge will prevent mode swithcing for full second. Usually, a storng yet quick flick of the 
    wrist will change the badge mode (the RGB LED modules are the easiest way to detect the mode
    has changed).

    
    Interactivity

    Badge features can be accessed through a serial connection (115200 baud). With a terminal
    connected, the user can enter commands and get responses from the badge. Using this feature,
    the user can change the display strings and contact infomation as well.

    All requests/commands are terminated with a CR ([Enter] key on keyboard).

    Requests:

      HELP will display all available requests and commands.

      ME will display user information strings (non-scrolling message, scrolling message, 
         contactinformation) and scrolling status.

      BUTTONS displays the state of the badge contact buttons.

      ACCEL will display the axis values from the accelerometer in 1/10 Gs. If an axis
            (X, Y, or Z) is specified, only that axis will be displayed.


    Commands:

      NSMSG allows the user to set one or both non-scrolling message strings. These strings have
      a maximum length of 8 characters. Examples:

        NSMSG Jon McPhalen   
        NSMSG 1 Jon
        NSMSG 2 McPhalen

        
      SMSG allows the user to set one or both scrolling message strings. These strings have
      a maximum length of 31 characters. Examples:

        SMSG "Jon McPhalen" "King of Propellers"   
        SMSG 1 "Jon McPhalen"
        SMSG 2 "King of Propellers"

      Important Note: Strings that contain whitespace or special characters must be enclosed in
      quotes. When in doubt, use quotes.


      SCROLL allows the user to set which message is displayed. Examples:

        SCROLL YES
        SCROLL NO
        SCROLL ON
        SCROLL OFF

      Note: For most commands YES and ON are interchangable, as are NO and OFF.


      CONTACTS displays the number of contacts and the contacts database (if any available)


      BUTTONS display the state of the badge buttons in IBIN7 format (i.e., %0000000)


      LED allows the user to control one or all of the blue LEDs associated with the touch buttons.
          When modifying all the the IBIN6 format is suggested (but not required). Examples:

        LED 0 ON
        LED 1 OFF
        LED ALL %000111


      RGB allows the user to control one or both RGB modules. Control of either module is through
          the available color set: BLACK, BLUE, GREEN, CYAN, RED, MAGENTA, YELLOW, WHITE. The
          badge will accept OFF in place of BLACK. Both RGB modules can be updated by specifying
          two colors, or a single module can be modifiedy by specify the moduel (LEFT, 1, RIGHT, 0)
          and the color. Examples

        RGB BLUE RED
        RGB LEFT BLUE
        RGB 1 BLUE
        RGB RIGHT RED
        RGB 0 RED

      Note: The jm_ebadge_leds object dated 12 NOV 2015 is required.
    
}

dat

  DATE_CODE     byte    "Parallax eBadge (v101.10 2015-11-19)", 0


con { timing }

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000                                           ' use 5MHz crystal

  CLK_FREQ = (_clkmode >> 6) * _xinfreq                          ' system freq as a constant
  MS_001   = CLK_FREQ / 1_000                                    ' ticks in 1ms
  US_001   = CLK_FREQ / 1_000_000                                ' ticks in 1us

  IR_BAUD  =   2_400  { max supported using IR connection }
  IR_FREQ  =  36_000  { matches receiver on DC22 badge }

  T_BAUD   = 115_200  { for terminal io } 
  

con { io pins }

  RX1      = 31                                                  ' programming / terminal
  TX1      = 30

  SDA      = 29                                                  ' eeprom / i2c
  SCL      = 28

  BTN_0    = 27                                                  ' touch buttons (right)
  BTN_1    = 26
  BTN_2    = 25

  IR_OUT   = 24                                                  ' IR coms
  IR_IN    = 23
  
  OLED_DAT = 22                                                  ' OLED connections 
  OLED_CLK = 21
  OLED_DC  = 20  
  OLED_RST = 19  
  OLED_CS  = 18

  BTN_5    = 17                                                  ' touch buttons (left)
  BTN_4    = 16
  BTN_3    = 15  

  TV_DAC2  = 14                                                  ' composite video (J503)  
  TV_DAC1  = 13
  TV_DAC0  = 12
  
  AUD_RT   = 10                                                  ' audio (J503)
  AUD_LF   =  9  

  BLU_CP2  =  8                                                  ' blue led charlieplex pins 
  BLU_CP1  =  7 
  BLU_CP0  =  6

  BTN_OS   =  5                                                  ' open source logo button
  
  ACC_INT  =  4                                                  ' accelerometer interrupt in
  
  RGB_CP2  =  3                                                  ' rgb led charlieplex pins 
  RGB_CP1  =  2 
  RGB_CP0  =  1

  BATT_MON =  0                                                  ' battery monitor(go/no-go)


con { buttons masks }
  
  PB0_MASK  = %0_000_001                                         ' upper right
  PB1_MASK  = %0_000_010                                         ' middle right
  PB2_MASK  = %0_000_100                                         ' lower right
  PB3_MASK  = %0_001_000                                         ' lower left
  PB4_MASK  = %0_010_000                                         ' middle left
  PB5_MASK  = %0_100_000                                         ' upper left
  PB6_MASK  = %1_000_000                                         ' open source logo

  OFF_MASK  = PB5_MASK | PB0_MASK
  

dat { touch pads configuration }

  TPCount       byte    7
  TPPins        byte    BTN_OS, BTN_5, BTN_4, BTN_3, BTN_2, BTN_1, BTN_0
  TPDischarge   byte    15
  

con { led control }

  #0, BLUE_0, BLUE_1, BLUE_2, BLUE_3, BLUE_4, BLUE_5             ' charlieplex control for blue leds
  #0, RGB_B1, RGB_G1, RGB_R1, RGB_B2, RGB_G2, RGB_R2             ' charlieplex control for rgb leds


con

  #0, NO, YES

  #0, M_TECH, M_ARTISTIC

  PGM_MODE = M_ARTISTIC                                          ' mode to run badge

  AUTO_ME = NO                                                   ' refresh display on string change

  BADGE_DEMOS = 2                                                ' when M_TECH mode is in use
  #0, DEMO_IR, DEMO_ACC                                          ' demo modes
  
  LOGO_MILLIS = 5000                                             ' display time for logo

  SHAKE_DELAY   = 25                                             ' read for shake every 25ms
  SHAKE_EVENT   = 150                                            ' switch mode if shaking for ~150ms
  SHAKE_HOLDOFF = 1000                                           ' ignore shake detection for 1s after app switch

  #-1, MSG_LOGO                                                  ' display messages
   #0, MSG_NAME
   #1, MSG_TX_NOW, MSG_TX_DONE
   #3, MSG_RX_NOW, MSG_RX_DONE, MSG_RX_DUP, MSG_RX_ERROR
   #9, MSG_WIPE

  NAME_CHARS  = 8                                                ' using 2x8 Parallax font mode in OLED
  SCROLL_MS   = 400
  
  CONTACT_LEN  = ee#PG_SIZE                                      ' use full page for access efficiency
  MAX_CONTACTS = 250                                             ' max size of contacts db
  LAST_CONTACT = MAX_CONTACTS - 1

  STX = 2                                                        ' start of text
  ETX = 3                                                        ' end of text
  EOT = 4                                                        ' end of transmission

  #0, RX_NEW, RX_DUPLICATE, RX_ERROR                             ' contact rx states
  
  TX_HOLDOFF = 1                                                 ' wait 1s before next TX attempt

  
obj

' main                                                           ' * master Spin cog
  time   : "jm_time"                                             '   timing and delays
  dtmr   : "jm_time"                                             '   display state timer
  scrtmr : "jm_time"                                             '   scroll timer
  shktmr : "jm_time"                                             '   shake hold-off timer
  io     : "jm_io"                                               '   io control
  ee     : "jm_24xx512"                                          '   64k eeprom access
  acc    : "jm_mma7660fc"                                        '   MMA7660 accelerometer
  pads   : "jm_touchpads"                                        '   touchpad input
  parser : "jm_parser"                                           '   string parser
  oled   : "OLED_AsmFast"                                        ' * OLED driver (TEMPORARY)
  leds   : "jm_ebadge_leds"                                      ' * charlieplexing driver for LEDs
  ir     : "jm_ir_hdserial"                                      ' * half-duplex serial via IR
  term   : "jm_fullduplexserial"                                 ' * full-duplex serial via terminal
                                                                  
' * Uses cog when loaded                                          


var

  long  cpcog                                                    ' charlieplex cog (>0 if loaded)

  long  badgemode                                                ' 0 for name/ir, 1 for accelerometer

  long  dstate                                                   ' display state
  long  msgms                                                    ' message/display milliseconds

  long  numcontacts                                              ' number of contacts in EEPROM

  long  scrolldirty                                              ' scroll was used
  long  scrollidx                                                ' scroll position
  long  scrollidxmax
  byte  scroll[32]                                               ' scroll buffer

  byte  buf1[CONTACT_LEN]                                        ' rx buffer
  byte  buf2[CONTACT_LEN]                                        ' check buffer


dat { name & contact information }

  Scroll_Msg    byte    NO

  
' Non-scrolling message (usually first & last name)
' -- Lines limited to 8 characters
'    * will be truncated if longer
' -- Scroll_Msg = NO  
 
  NSMsg0        byte    "Simon   ", 0                                
  NSMsg1        byte    "   Denny", 0  

  
' Specify scrolling lines without any space padding
' -- maximum length of either name is 31
' -- Scroll_Msg = YES

  SMsg0         byte    "Serpentine Galleries",    0[32-20]
  SMsg1         byte    "Products for Organising", 0[32-23]  


' Suggested structure of info in name, email, web site, telephone
' -- each element supports up to 31 characters
' -- note: each record stored as 128-byte page in EE

  MyInfo0       byte    "Serpentine Galleries",          0[32-20]  
  MyInfo1       byte    "info@serpentinegalleries.org",  0[32-28]  
  MyInfo2       byte    "Telephone 020 7402 6075",       0[32-23]  
  MyInfo3       byte    "@SerpentineUK",                 0[32-13]

  
' Note: If ResetDB is set to YES (any non-zero value), the contacts database in upper EEPROM will be
'       wiped clean
  
  ResetDB       byte    NO


' Non-scrolling messages
' -- Lines should be limited to 8 characters
'    * will be truncated if longer 
 
  Msg1_0        byte    "Sending", 0
  Msg1_1        byte    "Contact", 0
  
  Msg2_0        byte    "Contact", 0
  Msg2_1        byte    "Sent", 0

  Msg3_0        byte    "Getting", 0
  Msg3_1        byte    "Contact", 0
  
  Msg4_0        byte    "Contact", 0
  Msg4_1        byte    "Received", 0
  
  Msg5_0        byte    "Already", 0
  Msg5_1        byte    "Stored!", 0

  Msg6_0        byte    "Receive", 0
  Msg6_1        byte    "Error", 0

  Msg9_0        byte    "Database", 0
  Msg9_1        byte    "  Wipe", 0


  ' LEDs

  BlueLeds      byte    0
  RGBLeds       byte    0
  

pub main | c, addr, p_str

  setup                                                          ' setup io and badge objects
  
  check_db                                                       ' check for database reset  

  show_logo

  if (AUTO_ME == YES)                                            ' if terminal mode
    show_me(-1)                                                  '  show badge owner
  else
    term.tx(term#CLS)                                            ' blank message for BadgeHacker
    term.tx(term#CLRDN)

  repeat
    c := term.rxcheck                                            ' any serial input?
    if (c => 0)                                                  ' if yes, pass to parser
      if (parser.enqueue(c))                                     ' true when tokens are available
        process_cmd                                              ' process valid tokens
        parser.reset                                             ' reset parser for next command

    if (PGM_MODE == M_TECH)                                      ' technical mode?
      check_shake                                                ' want to change mode?    
      case badgemode        
        DEMO_IR  : ir_demo  
        DEMO_ACC : acc_demo 
        other    : ir_demo  

    else                                                         ' artistic mode
      check_logo_shake                                           ' want to show logo?
      ir_demo  


pub show_logo | n 

  leds.clear                                                     ' clear leds

  dstate := MSG_LOGO                                             ' show OSH logo 1st
  update_display(LOGO_MILLIS)                                    ' display until forced change

  n := (LOGO_MILLIS / 500) <# 4

  repeat n
    leds.set_rgbx(leds#GREEN, leds#WHITE)
    time.pause(250)
    leds.set_rgbx(leds#WHITE, leds#GREEN)
    time.pause(250)

  leds.clear
  dstate := MSG_NAME            
  update_display(posx)              
  scrollidx := -(NAME_CHARS-1)  
  scrtmr.set(-SCROLL_MS)

  leds.set_blue(BlueLeds)                                        ' restore user LED settings
  leds.set_rgb(RGBLeds)       

 
pub check_logo_shake | total, t 

'' Check shake for application switch

  if (shktmr.millis < 0)                                         ' shake hold-off still running?
    return

  total := 0                                                     ' clear shake count

  t := cnt                                                       ' sync loop timing
  repeat
    ifnot (acc.shake(-1))                                        ' read sensor for shake
      quit                                                       '  if no, abort

    total += SHAKE_DELAY                                         ' update shake timing
    if (total => SHAKE_EVENT)                                    ' if threshold reached
      show_logo
      return

    waitcnt(t += (MS_001 * SHAKE_DELAY))                         ' run loop every SHAKE_DELAY ms    
 

pub check_shake | total, t 

'' Check shake for application switch

  if (shktmr.millis < 0)                                         ' shake hold-off still running?
    return

  total := 0                                                     ' clear shake count

  t := cnt                                                       ' sync loop timing
  repeat
    ifnot (acc.shake(-1))                                        ' read sensor for shake
      quit                                                       '  if no, abort

    total += SHAKE_DELAY                                         ' update shake timing
    if (total => SHAKE_EVENT)                                    ' if threshold reached
      if (++badgemode == BADGE_DEMOS)                            ' switch to next app
        badgemode := 0                                           '  rollover if needed
      shktmr.set(-SHAKE_HOLDOFF)                                 ' set shake hold-off
      if (badgemode == DEMO_IR)                                  ' back to name display?
        leds.set_all(0)                                          ' acc leds off
        if (Scroll_Msg == NO)                                    ' not scrolling message?
          dstate := !MSG_NAME                                    '  force display refresh
          msgms := negx
      quit
      
    waitcnt(t += (MS_001 * SHAKE_DELAY))                         ' run loop every SHAKE_DELAY ms 


pub ir_demo

'' Display badge owner name and exchange contact info via IR
                                                                  
  if ((dstate <> MSG_NAME) and (dtmr.millis => msgms))           ' time to clear message
    dstate := MSG_NAME                                           ' go back to name
    update_display(posx)                                          
    leds.set_all(0)                                               
    scrollidx := -(NAME_CHARS-1)                                 ' reset for scrolling
    scrtmr.set(-SCROLL_MS)                                        
  else                                                            
    check_scroll

  check_receive                                                  ' data coming in?                   
  check_transmit                                                 ' time to send my contact info


pub check_scroll | len

'' Scroll SMsg0 and SMsg1 through display
'' -- scroll only in name display mode
'' -- scrolling must be enabled

  if (Scroll_Msg == NO)                                          ' abort if not scrolling
    return

  if (dstate == MSG_NAME)
    if (scrtmr.millis => 0)                                      ' if delay done             
      if (++scrollidx > scrollidxmax)                            ' at end of scroll window?                                                      
        scrollidx := -NAME_CHARS                                 '  reset (for scroll on)
                                                                     
      bytefill(@scroll, " ", 32)                                 ' fill scroll buf with spaces
      len := strsize(@SMsg0)                                     ' get length of segment     
      if (scrollidx < 0)                                         ' scroll on?
        bytemove(@scroll + ||scrollidx, @SMsg0, len)             ' put text on right side of display
      else                                                       ' scroll off
        if (scrollidx < len)                                     ' anything viewable for this index?
          bytemove(@scroll, @SMsg0 + scrollidx, len-scrollidx)   ' display current segment                                     
      oled.write2x8String(@scroll, 8, 0)                         ' write in oled

      bytefill(@scroll, " ", 32)
      len := strsize(@SMsg1)                                  
      if (scrollidx < 0)                                         
        bytemove(@scroll + ||scrollidx, @SMsg1, len)
      else
        if (scrollidx < len)                                     
          bytemove(@scroll, @SMsg1 + scrollidx, len-scrollidx) 
      oled.write2x8String(@scroll, 8, 1)                         

      oled.updateDisplay                                         ' refresh display
      scrtmr.set(-SCROLL_MS)                                     ' reset scrolling timer
      scrolldirty := true


pub check_receive | c, idx, check, checksum, found 

'' Looks for input from IR uart
'' -- contact string is framed with STX and ETX bytes

  if (numcontacts == MAX_CONTACTS)                               ' if no room in db
    ir.rxflush
    return                                                       '  abort
    
  c := ir.rxcheck                                                ' any ir traffic?
  if (c <> STX)                                                  ' if not STX, abort
    return

  bytefill(@buf1, 0, CONTACT_LEN)                                ' clear rx buffer
    
  dstate := MSG_RX_NOW
  update_display(posx)  
  leds.set_rgbx(leds#GREEN, leds#GREEN)                          ' show rx'ing

  ' rx bytes into buffer until t/o or ETX

  idx := 0                                                       ' set index to beginning
  check := 0                                                     ' clear running checksum
  
  repeat
    c := ir.rxtime(25)                                           ' use time-out in case packet breaks
    if (c < 0)                                                   ' time out
      rx_status(RX_ERROR)                                        ' show error
      return
    elseif (c == ETX)                                            ' end of contact transmission
      quit
    else
      buf1[idx++] := c                                           ' add byte to buffer
      check += c                                                 ' update working checksum

  check := $FF - (check & $FF)                                   ' clean-up working checksum
    
  checksum := ir.rxtime(25)                                      ' get checksum from sender
  if ((checksum < 0) or (checksum <> check))                     ' validate (no timeout or mismatch)
    rx_status(RX_ERROR) 
    return

  c := ir.rxtime(25)                                             ' get EOT
  if (c <> EOT)                                                  ' validate       
    rx_status(RX_ERROR) 
    return                                                   

  ' make sure we have something in the buffer

  if (strsize(@buf1) == 0)
    rx_status(RX_ERROR) 
    return  
    
  ' buffer now holds new contact

  idx := 0                                                       ' start at 1st contact
  found := false                                                 ' assume not found

  repeat numcontacts                                             ' loop through contacts
    read_record(idx, @buf2)                                      ' read contact from database
    if (strcomp(@buf1, @buf2))                                   ' if match in contacts db       
      found := true                                              '  mark as found                
      quit
    else
      ++idx

  ifnot (found)
    write_record(numcontacts, @buf1)                             ' write new contact to EE    
    ee.wr_long($8000, ++numcontacts)                             ' update count and save
    rx_status(RX_NEW)
  else      
    rx_status(RX_DUPLICATE)

  leds.set_all(0)        

 
pub rx_status(status) | color

'' Report RX status on OLED and via flashing RGB

  if (status == RX_NEW)                                          ' new contact rx'd
    dstate := MSG_RX_DONE
  elseif (status == RX_DUPLICATE)                                ' repeat contact
    dstate := MSG_RX_DUP
  elseif (status == RX_ERROR)                                    ' rx problem
    dstate := MSG_RX_ERROR
  else
    leds.set_all(0)                                              ' clear everything
    dstate := MSG_LOGO                                           ' force refresh in main loop
    msgms := 0
    return

  update_display(1000)                                           ' show status message

  color := lookupz(status : leds#GREEN, leds#YELLOW, leds#RED)

  flash_rgbs(color) 
       

pub check_transmit | idx, c, checksum

'' Send MyInfo strings between STX and ETX framing bytes
'' -- keep running checksum
'' -- tx checkum, then EOT to end transmission

  if (time.millis < 0)                                           ' in tx hold-off period?
    return

  repeat 3
    if (pads.read_pads <> PB6_MASK)                              ' OSH logo pressed?
      return
    time.pause(15)
         
  dstate := MSG_TX_NOW                                           ' show sending
  update_display(posx)

  leds.set_rgbx(leds#GREEN, leds#GREEN)

  ir.tx(STX)                                                     ' start of message

  ir.str(@MyInfo0)                                               ' send contact
  checksum := get_sum(@MyInfo0)                                  '  send a string
  ir.tx(13)                                                      '  add CR to end
  checksum += 13 
  ir.txflush                                                     ' let string finish

  ir.str(@MyInfo1)               
  checksum += get_sum(@MyInfo1)  
  ir.tx(13)                      
  checksum += 13                 
  ir.txflush

  ir.str(@MyInfo2)               
  checksum += get_sum(@MyInfo2)  
  ir.tx(13)                      
  checksum += 13                 
  ir.txflush

  ir.str(@MyInfo3)               
  checksum += get_sum(@MyInfo3)  
  ir.txflush                   
  
  ir.tx(ETX)                                                     ' end of info text
  
  checksum := $FF - (checksum & $FF)                             ' create checksum
  ir.tx(checksum)                                                ' send it

  ir.tx(EOT)                                                     ' end of transmission                                                   

  dstate := MSG_TX_DONE                                          ' show sending
  update_display(1000)
  flash_rgbs(leds#GREEN)    

  time.set_secs(-TX_HOLDOFF)                                     ' disable tx


pri get_sum(p_str) | sum

'' Provide sum of ASCII values in string

  sum := 0

  repeat strsize(p_str)
    sum += byte[p_str++]

  return sum


pub flash_rgbs(color)

  repeat 6
    leds.set_rgbx(color, color)          
    time.pause(75)                                 
    leds.set_all(0)                                
    time.pause(75)                                 


pub update_display(ms) | p_str0, p_str1

'' Displays "screen" based on dstate
'' -- if no match, Propeller beanie logo displayed
'' -- ms is milliseconds to display message   

  case dstate
    MSG_NAME:
      if (Scroll_Msg == NO)                                      ' non-scrolling name
        p_str0 := @NSMsg0
        p_str1 := @NSMsg1
      else
        bytefill(@scroll, " ", 8)                                ' blanks
        p_str0 := @scroll
        p_str1 := @scroll
        
    MSG_TX_NOW:
      p_str0 := @Msg1_0                                          ' sending contact
      p_str1 := @Msg1_1

    MSG_TX_DONE:
      p_str0 := @Msg2_0                                          ' contact sent
      p_str1 := @Msg2_1
      
    MSG_RX_NOW:
      p_str0 := @Msg3_0                                          ' receiving contact
      p_str1 := @Msg3_1

    MSG_RX_DONE:
      p_str0 := @Msg4_0                                          ' contact received
      p_str1 := @Msg4_1
      
    MSG_RX_DUP:
      p_str0 := @Msg5_0                                          ' already stored
      p_str1 := @Msg5_1

    MSG_RX_ERROR:
      p_str0 := @Msg6_0                                          ' receive error
      p_str1 := @Msg6_1
      
    MSG_WIPE:
      p_str0 := @Msg9_0                                          ' database wipe
      p_str1 := @Msg9_1

    other: { graphic }
      bytemove(oled.getBuffer, @Logo, 1024)
    
  if (dstate => MSG_NAME)
    'oled.clearDisplay
    bytefill(oled.getBuffer, 0, 1024)
    oled.write2x8String(p_str0, strsize(p_str0) <# 8, 0)  
    oled.write2x8String(p_str1, strsize(p_str1) <# 8, 1)

  oled.updateDisplay

  msgms := ms                                                    ' set message time
  dtmr.start                                                     ' restart display timer


pub read_record(idx, p_dest) | addr

'' Read record idx to destination
'' -- p_dest is pointer to destination

  bytefill(p_dest, 0, CONTACT_LEN )                               ' clear destination

  if ((idx < 0) or (idx > LAST_CONTACT))                         ' validate record idex
    return

  addr := $8000 + ((idx+1) * CONTACT_LEN)                        ' calculate EE address

  ee.rd_block(addr, CONTACT_LEN, p_dest)                         ' read from EE to destination  


pub write_record(idx, p_src) | addr

'' Writes record idx to EEPROM
'' -- idx is 0 to LAST_CONTACT 
'' -- p_src is pointer to data to write

  if ((idx < 0) or (idx > LAST_CONTACT))                         ' validate record idex
    return

  addr := $8000 + ((idx+1) * CONTACT_LEN)                        ' calculate EE address

  ee.wr_block(addr, CONTACT_LEN, p_src)                          ' write source to EE    
  

pub check_db | check

'' Checks to see if contacts database should be wiped clean

  numcontacts := ee.rd_word($8000)                               ' should be 0 to MAX_CONTACTS
  if (numcontacts > MAX_CONTACTS)
    wipe_db                       
    return

  check := ee.rd_word($8002)                                     ' should be 0 (new ee = $FFFF)
  if (check <> $0000)
    wipe_db
    return
  
  if (ResetDB <> NO) 
    wipe_db 


pub wipe_db | idx, addr, cycle

'' Clears contacts database and number of contacts

  dstate := MSG_WIPE                                             ' alert user we're clearing db
  update_display(posx)

  bytefill(@buf1, 0, CONTACT_LEN)                                ' clear buffer

  cycle := 0
  
  repeat idx from 0 to MAX_CONTACTS                              ' contacts + 1
    leds.set_blue(1 << cycle)                                    ' animate blue LEDs
    if (++cycle == 6)
      cycle := 0
    addr := $8000 + (idx * CONTACT_LEN)                          ' calculate ee address
    ee.wr_block(addr, CONTACT_LEN, @buf1)                        ' write block of 0s to EE  

  ResetDB := NO                                                  ' no need to wipe again
  ee.wr_byte(@ResetDB, ResetDB)                                  ' mark for next reset
  
  numcontacts := 0


dat { accelerometer angle table }

  Angle_X       byte    "X   0.0", $B0, 0                        ' $B0 is degrees symbol in Parallax font
  Angle_Y       byte    "Y   0.0", $B0, 0

  ' adapted from Appendix C of MMA7660FC documentation
  ' -- rounded to 0.1 degrees

  AngleTable    word      0,  27,  54,  81, 108, 136, 163  
                word    192, 220, 250, 280, 310, 342, 375
                word    410, 447, 486, 528, 575, 630, 696 
                word    799, 900
  

pub acc_demo | sensor, x, y

'' Display X & Y accelerometer axes in %

  acc.read_all_raw(@sensor)                                      ' read raw sensor bytes

  x := sensor << 26 ~> 26                                        ' extract signed X axis (sensor.byte[0])
  y := sensor << 18 ~> 26                                        ' extract signed Y axis (sensor.byte[1]) 
  
  update_acc_leds(x, y)   

  x := x * AngleTable[||x <# 22] / ||x                           ' convert to signed angle
  value_nn_n(x, @Angle_X[2])                                     ' update display string
  
  y := y * AngleTable[||y <# 22] / ||y
  value_nn_n(y, @Angle_Y[2]) 

  oled.write2x8String(@Angle_X, 8, 0)                            ' write new values
  oled.write2x8String(@Angle_Y, 8, 1)                                 
  oled.updateDisplay                                             ' refresh oled 
  

pub value_nn_n(value, p_str) | zflag

'' Write 3-digit justified value into p_str
'' -- format it -NN.N

  zflag := false

  if (value < 0)
    byte[p_str++] := "-"
    -value
  else
    byte[p_str++] := " "

  if (value => 100)
    byte[p_str++] := "0" + (value / 100)                         ' 10s digit (or space if < 100)
  else
    byte[p_str++] := " "

  byte[p_str++] := "0" + ((value // 100) / 10)                   ' 1s digit

  byte[p_str++] := "."                                           ' decimal separator  

  byte[p_str]   := "0" + (value // 10)                           ' 0.1s digit


pub update_acc_leds(x, y)

'' Use RGB and blue leds to assist in level display

  case x
    -2..2 : leds.set_rgb0(leds#GREEN)                            ' level
    -6..6 : leds.set_rgb0(leds#YELLOW)                           ' a little off
    other : leds.set_rgb0(leds#RED)                              ' way off

  case y
    -2..2 : leds.set_rgb1(leds#GREEN)
    -6..6 : leds.set_rgb1(leds#YELLOW)
    other : leds.set_rgb1(leds#RED)


  if (y < -2)
    if (x < -2)
      leds.set_blue(1 << BLUE_5)
      
    elseif (x > 2)
      leds.set_blue(1 << BLUE_3)
       
    else
      leds.set_blue(1 << BLUE_4)  
    
  elseif (y > 2)
    if (x < -2)
      leds.set_blue(1 << BLUE_0)
      
    elseif (x > 2)
      leds.set_blue(1 << BLUE_2)
       
    else
      leds.set_blue(1 << BLUE_1)  

  else
    if (x < -2)
      leds.set_blue(1 << BLUE_5 | 1 << BLUE_0)
                                        
    elseif (x > 2)                   
      leds.set_blue(1 << BLUE_3 | 1 << BLUE_2)
                                        
    else                                
      leds.set_blue(1 << BLUE_4 | 1 << BLUE_1)  


pub read_battery | level 

'' Returns battery level
'' -- value returned is RC charge time in microseconds
'' -- will require calibration for volts

  level := 0

  ctra := %01100 << 26 | BATT_MON                                ' setup counter to measure low
  frqa := 1
  outa[BATT_MON] := 0
  
  repeat 4
    dira[BATT_MON] := 1                                          ' discharge rc
    waitcnt(cnt + (MS_001 << 1))
    dira[BATT_MON] := 0                                          ' allow RC to charge
    phsa := 0                                                    ' clear sample
    repeat until ina[BATT_MON]                                   ' wait until finished
    level += phsa                                                ' add sample to level

  ctra := 0                                                      ' release counter

  return (level >> 2) / US_001                                   ' return average of 4 reads

  
pub lamp_test

'' Quick test of LEDs

  leds.set_blue(%111111)  

  leds.set_rgbx(leds#RED, leds#RED)
  time.pause(500)
  
  leds.set_rgbx(leds#GREEN, leds#GREEN)
  time.pause(500)
    
  leds.set_rgbx(leds#BLUE, leds#BLUE)
  time.pause(500)
  
  leds.set_all(0)


pub setup                              

'' Setup IO and objects for application

  time.start                                                     ' setup timing/delays for clock speed
  dtmr.start
  scrtmr.start
  shktmr.start

  io.start($0000, $0000)                                         ' clear all pins (this cog)
  
  ee.start(%000)                                                 ' connect to boot eeprom

  acc.start(SCL, SDA)                                            ' connect to accelerometer

  pads.start(TPCount, @TPPins, TPDischarge)                      ' setup touchpad interface

  oled.init(OLED_CS, OLED_DC, OLED_DAT, OLED_CLK, OLED_RST, {    ' start buffered oled driver
}           oled#SSD1306_SWITCHCAPVCC, oled#TYPE_128X64)
  oled.AutoUpdateOff  

  cpcog := leds.start                                            ' start charlieplexing driver
  
  ir.start(IR_IN, IR_OUT, IR_BAUD, IR_FREQ)                      ' start IR serial  
  
  term.start(RX1, TX1, %0000, T_BAUD)                            ' start serial for terminal

  parser.start(@CHAR_SET, @TOKEN_LIST, TOKEN_COUNT, true)        ' setup parser (without token list)

  setup_smsg
  

pub setup_smsg 
  
  if (strsize(@SMsg0) > 31)
    byte[@SMsg0][31] := 0                                        ' truncate if needed

  if (strsize(@SMsg1) > 31) 
    byte[@SMsg1][31] := 0     

  scrollidxmax :=  strsize(@SMsg0)                               ' find max idx for scrolling
  scrollidxmax #>= strsize(@SMsg1)


con { enumerated parser tokens }

  #0, T_NSMSG, T_SMSG, T_SCROLL                                              { 
   }, T_NO, T_YES                                                            { 
   }, T_INFO, T_ME                                                           { 
   }, T_CONTACTS, T_WIPE, T_USAGE                                            {
   }, T_BUTTONS                                                              {    
   }, T_LED, T_ALL, T_OFF, T_ON                                              { 
   }, T_RGB, T_LEFT, T_RIGHT                                                 { 
   }, T_BLACK, T_BLUE, T_GREEN, T_CYAN, T_RED, T_MAGENTA, T_YELLOW, T_WHITE  {
   }, T_ACCEL, T_X, T_Y, T_Z                                                 {
   }, T_HELP                                                                 {
   }, T_PING                                                                 { 
   }, TOKEN_COUNT
    

dat { valid command tokens }

  ' used to convert text token to #

  CHAR_SET      byte    "$%+-_"
                byte    "0123456789"
                byte    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
                byte    "abcdefghijklmnopqrstuvwxyz", 0

                
  TOKEN_LIST    byte    "NSMSG", 0    
                byte    "SMSG", 0     
                byte    "SCROLL", 0   
                byte    "NO", 0       
                byte    "YES", 0      
                byte    "INFO", 0     
                byte    "ME", 0       
                byte    "CONTACTS", 0
                byte    "WIPE", 0
                byte    "USAGE", 0
                byte    "BUTTONS",0   
                byte    "LED", 0      
                byte    "ALL", 0      
                byte    "OFF", 0      
                byte    "ON", 0       
                byte    "RGB", 0      
                byte    "LEFT", 0
                byte    "RIGHT", 0
                byte    "BLACK", 0    
                byte    "BLUE", 0     
                byte    "GREEN", 0    
                byte    "CYAN", 0     
                byte    "RED", 0      
                byte    "MAGENTA", 0  
                byte    "YELLOW", 0   
                byte    "WHITE", 0    
                byte    "ACCEL", 0
                byte    "X", 0
                byte    "Y", 0
                byte    "Z", 0
                byte    "HELP", 0
                byte    "PING", 0

                
  HELP_MSG      byte    "Commands:", 13
                byte    "  NSMSG line1 line2               -- non-scrolling, 8 chars max", 13
                byte    "  NSMSG [1|2] line                -- non-scrolling, 8 chars max", 13
                byte    "  SMSG line1 line2                -- scrolling, 31 chars max", 13
                byte    "  SMSG [1|2] line                 -- scrolling, 31 chars max", 13     
                byte    "  SCROLL [NO|YES]                 -- enable/disable scrolling", 13
                byte    "  INFO [1..4] string              -- set info string (1..4)", 13
                byte    "  ME                              -- display info strings", 13     
                byte    "  CONTACTS {COUNT | WIPE}         -- display/wipe stored contacts", 13
                byte    "  BUTTONS                         -- display touchpad buttons", 13
                byte    "  LED [0..5|ALL] [OFF|ON|pattern] -- set blue LEDs", 13
                byte    "  RGB [COLOR|LEFT|RIGHT|] COLOR   -- set RGB LEDs", 13
                byte    "  ACCEL [ALL|X|Y|Z]               -- read accelerometer", 13 
                byte    "  HELP                            -- display this screen", 13
                byte    0


pub process_cmd | tidx

'' Handle known tokens

  parser.ucase(0)                                                ' convert command to uppercase

  tidx := parser.get_token_id(parser.token_addr(0))              ' get index of command token

  case tidx
    T_NSMSG    : get_nonscroll_msg
    T_SMSG     : get_scrolling_msg
    T_SCROLL   : get_scroll 
    T_INFO     : get_info
    T_ME       : show_me(%1111)
    T_CONTACTS : get_contacts
    T_BUTTONS  : show_buttons
    T_LED      : get_led 
    T_RGB      : get_rgb
    T_ACCEL    : get_accel
    T_PING     : ping_reply 
    other      : show_help


pub get_nonscroll_msg | n, len

'' Get non-scrolling message elements

  if (parser.token_count == 1)                                   ' no parameters?
    term.tx(term#CLS)
    term.str(@NSMsg0)
    term.tx(term#CR)
    term.str(@NSMsg1)
    term.tx(term#CR)
    term.tx(term#CLRDN)
    return

  if (parser.token_count <> 3)                                   ' not 2 parameters?
    show_help
    return

  if (parser.token_is_number(1))                                 ' if 1st parm is # 
    n := parser.token_value(1)                                   '  get its value (should be 1 or 2)
    if (n == 1)
      update_str(@NSMsg0, parser.token_addr(2), 8)
      fix_nsmsg(@NSMsg0)
      ee_save_str(@NSMsg0)  

    elseif (n == 2)
      update_str(@NSMsg1, parser.token_addr(2), 8)
      fix_nsmsg(@NSMsg1)
      ee_save_str(@NSMsg1)  
      
    else
      show_help

  else                                                           ' two strings submitted
    update_str(@NSMsg0, parser.token_addr(1), 8)
    fix_nsmsg(@NSMsg0)
    ee_save_str(@NSMsg0)    
    update_str(@NSMsg1, parser.token_addr(2), 8)
    fix_nsmsg(@NSMsg1)
    ee_save_str(@NSMsg1)   

  if (AUTO_ME == YES)
    show_me(-1)
  else
    term.tx(term#CLS)
    term.tx(term#CLRDN)

  refresh_nsmsg(false)                                           ' update display


pub fix_nsmsg(p_str) | len, idx

'' Fixes non-scrolling message string to 8 characters

  len := strsize(p_str)
  if (len < 8)
    repeat idx from len to 7
      byte[p_str][idx] := " "  
    byte[p_str][8] := 0
  
  
pub refresh_nsmsg(checksd)

'' Refresh non-scrolling display
'' -- if checksd is true, require use scrolldirty flag

  if (badgemode == DEMO_IR)                                      ' can we display name?
    if (Scroll_Msg == NO)                                        ' is scrolling dispabled now?
      if ((checksd == false) or (scrolldirty))
        dstate := MSG_NAME                                       ' revert to name
        update_display(0)                                        ' refresh now
        scrolldirty := false                                     ' clear scrolling flag
        scrollidx := -NAME_CHARS                                 ' reset (for next scroll on)        


pub get_scrolling_msg  | n, tlen

'' Get scrolling message elements

  if (parser.token_count == 1)                                   ' no parameters?
    term.tx(term#CLS)
    term.str(@SMsg0)
    term.tx(term#CR)
    term.str(@SMsg1)
    term.tx(term#CR)
    term.tx(term#CLRDN)
    return

  if (parser.token_count <> 3)                                   ' not 2 parameters?
    show_help
    return

  if (parser.token_is_number(1))                                 ' if 1st parm is # 
    n := parser.token_value(1)                                   '  get its value (should be 1 or 2)
    if (n == 1)
      update_str(@SMsg0, parser.token_addr(2), 31)
      setup_smsg
      ee_save_str(@SMsg0) 
    elseif (n == 2)
      update_str(@SMsg1, parser.token_addr(2), 31)
      setup_smsg
      ee_save_str(@SMsg1)  
    else
      show_help

  else                                                           ' two strings submitted
    update_str(@SMsg0, parser.token_addr(1), 31)
    setup_smsg           
    ee_save_str(@SMsg0)     
    update_str(@SMsg1, parser.token_addr(2), 31)
    setup_smsg
    ee_save_str(@SMsg1)  

  if (AUTO_ME == YES)
    show_me(-1)
  else
    term.tx(term#CLS)
    term.tx(term#CLRDN)
  

pub update_str(p_dest, p_src, maxlen) | len

'' Update string at p_dest with string at p_src
'' -- maxlen is maximum length of p_dest

  len := strsize(p_src) <# maxlen                                ' determine/limit source string size

  bytefill(p_dest, 0, maxlen+1)                                  ' clear old string                        
  bytemove(p_dest, p_src, len)                                   ' copy new                       


pub get_scroll | tidx

'' Get scrolling status
'' -- valid parameters are YES, ON, NO, or OFF

  if (parser.token_count == 1)                                   ' no parameters
    term.tx(term#CLS)
    if (Scroll_Msg)
      term.str(string("Yes", 13))  
    else
      term.str(string("No", 13))
    term.tx(term#CLRDN)
    return  

  if (parser.token_count <> 2)                                   ' check token count
    show_help
    return

  parser.ucase(1)                                                ' make command ucase
  tidx := parser.get_token_id(parser.token_addr(1))              ' get token index

  tidx := lookdown(tidx : T_NO, T_OFF, T_YES, T_ON)              ' convert tidx to 1..4

  if (tidx == 0)                                                 ' bad command
    show_help
    return

  Scroll_Msg := (tidx => 3)                                      ' make true or false
  ee.wr_byte(@Scroll_Msg, Scroll_Msg)                            ' save to ee
  refresh_nsmsg(true)                                            ' refresh display if needed

  if (AUTO_ME == YES)
    show_me(-1)
  else
    term.tx(term#CLS)
    term.tx(term#CLRDN)
   
          
pub get_info | n, p_str, tlen

  if (parser.token_count == 1)                                   ' if no parameters
    term.tx(term#CLS)
    term.str(@MyInfo0)
    term.tx(term#CR)
    term.str(@MyInfo1)
    term.tx(term#CR)
    term.str(@MyInfo2)
    term.tx(term#CR)
    term.str(@MyInfo3)
    term.tx(term#CR)
    term.tx(term#CLRDN)
    return

  if (parser.token_count == 5)                                   ' everything in one go?
    update_str(@MyInfo0, parser.token_addr(1), 31)
    ee_save_str(@MyInfo0)
    update_str(@MyInfo1, parser.token_addr(2), 31)
    ee_save_str(@MyInfo1)  
    update_str(@MyInfo2, parser.token_addr(3), 31)
    ee_save_str(@MyInfo2)  
    update_str(@MyInfo3, parser.token_addr(4), 31)
    ee_save_str(@MyInfo3) 
    term.tx(term#CLS) 
    term.tx(term#CLRDN) 
    return
    
  if (parser.token_count <> 3)                                   ' one line at a time?
    show_help
    return

  ifnot (parser.token_is_number(1))                              ' second parameter must be #
    show_help
    return
  else
    n := parser.token_value(1)                                   ' validate info #
    if ((n < 1) or (n > 4))
      show_help     
      return

  case n
    1 :
      update_str(@MyInfo0, parser.token_addr(2), 31)
      ee_save_str(@MyInfo0)
      
    2 :
      update_str(@MyInfo1, parser.token_addr(2), 31)
      ee_save_str(@MyInfo1)
         
    3 :
      update_str(@MyInfo2, parser.token_addr(2), 31)
      ee_save_str(@MyInfo2)
                 
    4 :
      update_str(@MyInfo3, parser.token_addr(2), 31)
      ee_save_str(@MyInfo3) 

  if (AUTO_ME == YES)
    show_me(-1)
  else
    term.tx(term#CLS)
    term.tx(term#CLRDN)


pub spaced_string(spaces, id, p_str)

'' Print a string front padded with spaces
'' -- optional id can be 0..9 (followed by rparen and space)
'' -- p_str is pointer to string

  repeat spaces
    term.tx(" ")

  if ((id => 0) and (id =< 9))
    term.tx("0" + id)
    term.tx(")")
    term.tx(" ")
    
  term.str(p_str)
  term.tx(term#CR)

       
pub show_me(select)

'' Display badge owner messages and information

  term.tx(term#CLS)

  if (select & %1000)
    term.str(string("Non-scrolling Message", 13))
    spaced_string(2, 1, @NSMsg0)
    spaced_string(2, 2, @NSMsg1)
    term.tx(term#CR)

  if (select & %0100)
    term.str(string("Scrolling Message", 13))      
    spaced_string(2, 1, @SMsg0)
    spaced_string(2, 2, @SMsg1)
    term.tx(term#CR)

  if (select & %0010)
    term.str(string("Do Scroll?", 13))
    if (Scroll_Msg)
      spaced_string(2, -1, string("Yes", 13)) 
    else
      spaced_string(2, -1, string("No", 13))     

  if (select & %0001)
    term.str(string("Contact Information", 13))      
    spaced_string(2, 1, @MyInfo0)
    spaced_string(2, 2, @MyInfo1)
    spaced_string(2, 3, @MyInfo2)
    spaced_string(2, 4, @MyInfo3)     
    term.tx(term#CR)

  term.tx(term#CLRDN)

      
pub get_contacts | idx

'' Display all contacts

  term.tx(term#CLS)

  if (parser.token_count == 2)                                   ' parameter after CONTACTS?
    parser.ucase(1) 
    idx := parser.get_token_id(parser.token_addr(1))
    case idx
      T_WIPE:
        wipe_all_contacts
        term.tx(term#CLRDN)

      T_USAGE:
        show_contacts_usage
        term.tx(term#CLRDN)

      other:
        show_help 

    return

  if (parser.token_count <> 1)                                   ' invalid use of CONTACTS?     
    show_help 
    return    
  
  show_contacts_usage

  if (numcontacts == 0)                                          ' if no contacts
    term.tx(term#CLRDN)
    return                                                       '  abort
  else
    term.tx(term#CR)
    
  idx := 0                                                       ' set index to start of contacts
  
  repeat numcontacts                                             ' loop through contacts
    read_record(idx, @buf1)                                      ' copy from EE to RAM
    if (strsize(@buf1) =< 0)
      term.str(string("Contact Error ("))
      term.dec(idx)
      term.tx(")")
    else
      term.str(@buf1)                                            ' display on terminal
    repeat 2                                                     ' pad with blank lines
      term.tx(term#CR)
    ++idx
    time.pause(15)                                               ' prevent terminal buffer overrun

  term.tx(term#CLRDN)


pri wipe_all_contacts

  wipe_db                                                        ' clear the contacts
  leds.clear                                                     ' refresh display                   
  dstate := MSG_NAME           
  update_display(posx)         
  scrollidx := -(NAME_CHARS-1) 
  scrtmr.set(-SCROLL_MS)
  

pri show_contacts_usage

  term.dec(numcontacts)                                          ' display # of contacts
  term.str(string(" contact"))
  if (numcontacts <> 1)
    term.tx("s")
  term.str(string(" -- "))
  term.dec(MAX_CONTACTS - numcontacts)  
  term.str(string(" slots available"))
  term.tx(term#CR)  
  

pub show_buttons

'' Show current badge button inputs
'' -- uses IBIN7 format

  term.tx(term#CLS)
  term.tx("%")
  term.bin(pads.read_pads, 7)
  term.tx(term#CR)
  term.tx(term#CLRDN)

         
pub get_led | n, tidx

'' Update LED(s) near button pads

  term.tx(term#CLS)

  if (parser.token_count == 1)                                   ' requesting current state?
    term.tx("%")
    term.bin(BlueLeds, 6)
    term.tx(term#CR)
    term.tx(term#CLRDN)
    return

  if (parser.token_count <> 3)                                   ' check token count
    show_help
    return

  repeat n from 0 to 2                                           ' convert token to upper case
    parser.ucase(n)  

  if (parser.token_is_number(1))                                 ' set individual?
    n := parser.token_value(1)                                   ' get led #
    if ((n => 0) and (n =< 5))                                   ' valid LED?
      tidx := parser.get_token_id(parser.token_addr(2))          ' get index of command
      case tidx       
        T_ON, T_YES :
          BlueLeds := leds.blue_on(n)
        T_OFF, T_NO :
          BlueLeds := leds.blue_off(n)
        other :
          show_help
          return

      ee.wr_byte(@BlueLeds, BlueLeds)
      term.tx(term#CR)    
      term.tx(term#CLRDN) 
      return
      
    else
      show_help
      return

  tidx := parser.get_token_id(parser.token_addr(1))              ' get token index of command
  
  if (tidx == T_ALL)  
    if (parser.token_is_number(2))
      BlueLeds := leds.set_blue(parser.token_value(2))
    else
      tidx := parser.get_token_id(parser.token_addr(2))
      case tidx
        T_ON, T_YES :
          BlueLeds := leds.set_blue(%111111)
        T_OFF, T_NO :
          BlueLeds := leds.set_blue(%000000)
        other :
          show_help 
          return

    ee.wr_byte(@BlueLeds, BlueLeds)
    term.tx(term#CR)    
    term.tx(term#CLRDN)
    return              
         
  else
    show_help
    return

        
pub get_rgb | tidx, n, c1, c0

'' Update RGB LED(s)

  term.tx(term#CLS)

  if (parser.token_count == 1)                                   ' requesting current state?
    term.tx("%")
    term.bin(RGBLeds, 6)
    term.tx(term#CR)
    term.tx(term#CLRDN)
    return

  if (parser.token_count <> 3)
    show_help
    return

  repeat tidx from 0 to 2
    parser.ucase(tidx)

  ' check for numbered module (1 or 0)

  if (parser.token_is_number(1))                                 ' if specified by #
    n := parser.token_value(1)                                   ' get module (1 or 0)
    c1 := token_to_color(2)                                      ' get color
    if ((n => 0) and (n =< 1) and (c1 => 0))                     ' if valid color
      RGBLeds := leds.set_rgbn(n, c1)
      ee.wr_byte(@RGBLeds, RGBLeds)
      term.tx(term#CR)     
      term.tx(term#CLRDN)  
    else
      show_help
    return

  ' check for named moduel (LEFT or RIGHT)

  tidx := parser.get_token_id(parser.token_addr(1))              ' get command token
  if ((tidx == T_LEFT) or (tidx == T_RIGHT))
    c1 := token_to_color(2)
    if (c1 => 0)
      if (tidx == T_LEFT)
        RGBLeds := leds.set_rgb1(c1)
        ee.wr_byte(@RGBLeds, RGBLeds)  
      else
        RGBLeds := leds.set_rgb0(c1)
        ee.wr_byte(@RGBLeds, RGBLeds)
      term.tx(term#CR)     
      term.tx(term#CLRDN)      
    else
      show_help
    return

  ' validate two legal colors

  c1 := token_to_color(1)  
  c0 := token_to_color(2)
  if ((c1 => 0) and (c0 => 0))
    RGBLeds := leds.set_rgbx(c1, c0)
    ee.wr_byte(@RGBLeds, RGBLeds)
    term.tx(term#CR)     
    term.tx(term#CLRDN)     
  else
    show_help


pub token_to_color(n) | tidx

'' Convert token n to RGB color index if valid
'' -- returns -1 if not a color token

  tidx := parser.get_token_id(parser.token_addr(n))

  if ((tidx => T_BLACK) and (tidx =< T_WHITE))
    return tidx - T_BLACK

  elseif ((tidx == T_OFF) or (tidx == T_NO))
    return T_BLACK

  else
    return -1

    
pub get_accel | tidx

'' Get accelerometer information

  term.tx(term#CLS)
  
  if (parser.token_count == 1)                                   ' no parameter?
    show_accel_raw(0, 2)                                         ' show all
    return

  if (parser.token_count <> 2)                                   ' bad param count?
    show_help
    return

  parser.ucase(1)                                                ' convert cmd to uc
  tidx := parser.get_token_id(parser.token_addr(1))              ' get token id

  case tidx
    T_ALL : show_accel_raw(0, 2)
    T_X   : show_accel_raw(0, 0)     
    T_Y   : show_accel_raw(1, 1)
    T_Z   : show_accel_raw(2, 2)
    other : show_help


pub show_accel_raw(first, last) | sensor, ch, g

'' Read and display accelerometer values
'' -- first and last channel values are 0..2
'' -- first must be <= last

  acc.read_all_raw(@sensor)                                      ' read raw sensor bytes
  repeat ch from first to last
    term.tx("X" + ch)
    term.tx("=")
    g := (acc.raw_to_gforce(sensor.byte[ch]) + 5) / 10           ' convert to g-force, round to 10ths
    dec_nxn(g)
    term.tx(term#CR)

  term.tx(term#CLRDN)


pub dec_nxn(value) | td, div

'' Display value in N.N format

  value := -99 #> value <# 99

  if (value < 0)
    term.tx("-")
    ||value

  term.tx("0" + value / 10)
  term.tx(".")
  term.tx("0" + value // 10)


pub show_help

  term.tx(term#CLS)
  term.str(@HELP_MSG)
  term.tx(term#CLRDN)


pub ping_reply

  term.tx(term#CLS)
  term.str(@DATE_CODE)
  term.tx(term#CR)
  term.tx(term#CLRDN)
        

pub ee_save_str(p_str)

  ee.wr_str(p_str, p_str)
  

dat { Circle with Simon Denny }

  Logo          byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $C0, $E0, $F0 
                byte    $70, $78, $38, $3C, $1C, $1C, $1E, $0E, $0E, $0F, $07, $07, $07, $07, $07, $07 
                byte    $07, $07, $07, $07, $07, $07, $0F, $0E, $0E, $1E, $1C, $1C, $3C, $38, $78, $70 
                byte    $F0, $E0, $C0, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $80, $C0, $E0, $F8, $7C, $1E, $0F, $07, $03, $01, $01, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $01, $01, $03, $07, $0F, $1E, $7C, $F8, $E0, $C0, $80, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $C0, $F8, $FE, $3F, $0F, $03, $00, $00, $70, $F8, $DC, $8C, $8C, $8C, $1C 
                byte    $18, $00, $00, $FC, $FC, $00, $00, $FC, $FC, $70, $E0, $C0, $C0, $E0, $70, $FC 
                byte    $FC, $00, $00, $F0, $F8, $1C, $0C, $0C, $0C, $1C, $F8, $F0, $00, $00, $FC, $FC 
                byte    $E0, $C0, $80, $00, $FC, $FC, $00, $00, $00, $03, $0F, $3F, $FE, $F8, $C0, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $FE, $FF, $FF, $03, $00, $00, $00, $00, $00, $18, $38, $31, $31, $31, $3B, $1F 
                byte    $0E, $00, $00, $3F, $3F, $00, $00, $3F, $3F, $00, $00, $01, $01, $00, $00, $3F 
                byte    $3F, $00, $00, $0F, $1F, $38, $30, $30, $30, $38, $1F, $0F, $00, $00, $3F, $3F 
                byte    $00, $01, $03, $07, $3F, $3F, $00, $00, $00, $00, $00, $00, $03, $FF, $FF, $FE 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $7F, $FF, $FF, $C0, $00, $00, $00, $00, $FC, $FC, $0C, $0C, $0C, $1C, $F8, $F0 
                byte    $00, $00, $FC, $FC, $8C, $8C, $8C, $8C, $8C, $0C, $00, $00, $FC, $FC, $E0, $C0 
                byte    $80, $00, $FC, $FC, $00, $00, $FC, $FC, $E0, $C0, $80, $00, $FC, $FC, $00, $08 
                byte    $1C, $38, $F0, $C0, $C0, $F0, $38, $1C, $08, $00, $00, $00, $C0, $FF, $FF, $7F 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $03, $1F, $7F, $FC, $F0, $C0, $00, $3F, $3F, $30, $30, $30, $38, $1F, $0F 
                byte    $00, $00, $3F, $3F, $31, $31, $31, $31, $31, $30, $00, $00, $3F, $3F, $00, $01 
                byte    $03, $07, $3F, $3F, $00, $00, $3F, $3F, $00, $01, $03, $07, $3F, $3F, $00, $00 
                byte    $00, $00, $00, $3F, $3F, $00, $00, $00, $00, $C0, $F0, $FC, $7F, $1F, $03, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $01, $03, $07, $1F, $3E, $78, $F0, $E0, $C0, $80, $80, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $80, $80, $C0, $E0, $F0, $78, $3E, $1F, $07, $03, $01, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $03, $07, $0F 
                byte    $0E, $1E, $1C, $3C, $38, $38, $78, $70, $70, $F0, $E0, $E0, $E0, $E0, $E0, $E0 
                byte    $E0, $E0, $E0, $E0, $E0, $E0, $F0, $70, $70, $78, $38, $38, $3C, $1C, $1E, $0E 
                byte    $0F, $07, $03, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
                byte    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 


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