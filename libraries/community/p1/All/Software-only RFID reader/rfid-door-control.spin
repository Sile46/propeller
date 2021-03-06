{

Access control example using rfid-lf
────────────────────────────────────

This is a functioning example for the rfid-lf module.
It scans for RFID cards that match a list of accepted codes.
When one is found, we activate a relay momentarily.
A bi-color LED indicates when access is allowed or denied.

See the rfid-lf module for the RFID reader schematic.

Other parts include a reed relay (don't forget the protection
diode) and a bi-color LED with two current limiting resistors.

There is also a TV output on pin 12, for debugging.

Micah Dowty <micah@navi.cx>

 ┌───────────────────────────────────┐
 │ Copyright (c) 2008 Micah Dowty    │               
 │ See end of file for terms of use. │
 └───────────────────────────────────┘

}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  TV_PIN           = 12
  RED_LED_PIN      = 23 ' Active high (bi-color LED)
  GREEN_LED_PIN    = 22
  RELAY_PIN        = 17 ' Active low

OBJ
  debug : "TV_Text"
  rfid  : "rfid-lf"

  ' Important: This is a separate file which supplies a list of
  ' accepted codes that will grant access. Since this data is
  ' effectively a list of passwords, it is stored in a separate
  ' file so it's easy to back up and maintain this data separately
  ' from the source code.
  '
  ' To generate an access list, copy the "access-list-sample.spin"
  ' file and modify it to include your codes. Some devices have their
  ' code printed on the tag itself, but the easiest way to find codes
  ' is to attach a TV and watch the codes that we print to the screen.
  
  acl : "access-list"

VAR
  long  buffer[16]
  
PUB main | i, format, isMatch
  debug.start(TV_PIN)
  hardwareInit
  rfid.start

  debug.out(0)
  debug.str(string("RFID Access Control system", 13, "Micah Dowty <micah@navi.cx>", 13, 13))

  repeat
    if format := rfid.read(@buffer)

      if isMatch := matchCode(format, @buffer)
        LED_Green
      else
        LED_Red

      debug.out("[")
      debug.hex(format, 8)
      debug.str(string("] "))
        
      repeat i from 0 to (format & $FFFF) - 1
        debug.hex(buffer[i], 8)
        debug.out(" ")
      debug.out(13)

      if isMatch
        ' Pulse the relay, and wait for the door to actuate.
        ' After we're done, flush the RFID buffer so we don't
        ' immediately read another matching code.

        Relay_Actuate
        rfid.read(@buffer)

      LED_Off

  
PRI matchCode(format, bufPtr) : isMatch | pBuf, pTable, tFormat, len
  ' Check a received code against a table of authorized codes.
  ' The table consists of a zero-terminated list of longs. Each
  ' code has one long for its format code, followed by a variable
  ' number of longs for the code data itself.

  isMatch~
  pTable := acl.ptr

  repeat while tFormat := LONG[pTable]
    len := tFormat & $FFFF
    pTable += 4

    if tFormat == format and longCompare(bufPtr, pTable, len)
      isMatch~~
      return

    pTable += len << 2

PRI longCompare(bufA, bufB, count) : equal
  repeat count
    if LONG[bufA] <> LONG[bufB]
      equal~
      return
    bufA += 4
    bufB += 4
  equal~~
  return 
      
PRI hardwareInit
  LED_Off
  Relay_Off
  dira[RED_LED_PIN]~~
  dira[GREEN_LED_PIN]~~
  dira[RELAY_PIN]~~

PRI LED_Red
  outa[RED_LED_PIN]~~
  outa[GREEN_LED_PIN]~

PRI LED_Green
  outa[RED_LED_PIN]~
  outa[GREEN_LED_PIN]~~

PRI LED_Yellow
  outa[RED_LED_PIN]~~
  outa[GREEN_LED_PIN]~~

PRI LED_Off
  outa[RED_LED_PIN]~
  outa[GREEN_LED_PIN]~

PRI Relay_On
  outa[RELAY_PIN]~

PRI Relay_Off
  outa[RELAY_PIN]~~

PRI Relay_Actuate
  Relay_On
  waitcnt(clkfreq + cnt)
  Relay_Off
  waitcnt(clkfreq * 5 + cnt)
      