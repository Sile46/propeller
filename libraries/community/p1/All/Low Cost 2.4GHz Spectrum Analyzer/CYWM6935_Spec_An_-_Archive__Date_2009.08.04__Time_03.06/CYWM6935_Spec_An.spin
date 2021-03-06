{{      
┌──────────────────────────────────────────┐
│ CYWM6935 2.4GHz Spectrum Analyzer v1.0   │
│ Author: Pat Daderko (DogP)               │               
│ Copyright (c) 2009                       │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

2.4GHz Spectrum Analyzer using a low-cost CYWM6935 module, outputting to a VGA monitor.  This appliction
sweeps from 2.400GHz to 2.527GHz in 1MHz steps, using the RSSI values of channels 0 through 127 to determine
power level.  Levels are from 0 to 31, although the values aren't calibrated to any standard measurement.

There is code for enabling a peak hold as well as a cursor, although I didn't define an interface for
controlling these.  It could be connected to buttons, keypad, serial port, etc.  

The interface to this module is SPI, as well as misc pins, several of which can likely be omitted if desired.
Note that the module uses a 12 pin 2mm connector rather than the standard 0.1".  This could probably be used
in a custom circuit using the CYWUSB6935 chip as well.  The CYWM6935 module has trace antennas on the board.

This program could be expanded on to make use of the communication features as well, although it's probably
not one of the best communication devices, since the speed is slow and the range is quite limited.  The module
is FCC Approved though, so it may be of use to some.  Make sure you only transmit in the channels legal for
your territory (according to the manual, US FCC regulations allow only from channel 2 to 79).

I borrowed a lot of the code from the Beau Schwabe's Audio Spectrum Analyzer and SPI Demo, as well as some C
code floating around for a similar project on the AVR, which doesn't seem to have a home or author.       
}}

CON
    _clkmode = xtal1 + pll16x                           
    _xinfreq = 5_000_000

OBJ
SPI     :       "SPI_Asm"                              ''The Standalone SPI ASM engine
gr      :       "VGA.graphics"                         ''VGA Graphics driver

CON

    ''512x192
    tiles = gr#tiles

    ''CYWM6935 Pin Definitions
    IRQ    = 8
    nRESET = 9
    MOSI   = 10
    nSS    = 11
    SCK    = 12
    MISO   = 13
    nPD    = 14    

    ''Commands
    WRITE_REG = %10000000
    READ_REG  = %00000000

    ''Register Definitions
    REG_ID             = $00
    REG_CONTROL        = $03
    REG_DATA_RATE      = $04
    REG_CONFIG         = $05
    REG_SERDES_CTL     = $06
    REG_RX_INT_EN      = $07
    REG_RX_INT_STAT    = $08
    REG_RX_DATA_A      = $09
    REG_RX_VALID_A     = $0A
    REG_RX_DATA_B      = $0B
    REG_RX_VALID_B     = $0C
    REG_TX_INT_EN      = $0D
    REG_TX_INT_STAT    = $0E
    REG_TX_DATA        = $0F
    REG_TX_VALID       = $10
    REG_PN_CODE        = $11 '$11 to $18
    REG_THRESHOLD_L    = $19
    REG_THRESHOLD_R    = $1A
    REG_WAKE_EN        = $1C
    REG_WAKE_STAT      = $1D    
    REG_ANALOG_CTL     = $20
    REG_CHANNEL        = $21
    REG_RSSI           = $22
    REG_PA             = $23
    REG_CRYSTAL_ADJ    = $24
    REG_VCO_CAL        = $26
    REG_PWR_CTL        = $2E
    REG_CARRIER_DETECT = $2F
    REG_CLOCK_MANUAL   = $32
    REG_CLOCK_ENABLE   = $33
    REG_SYN_LOCK_CNT   = $38
    REG_MID            = $3C '$3C to $3F
    
VAR
  byte buffer[128] 'buffer used for 

PUB Spec_An|i, level, peakhold, cursor

    SPI.start(15,0)                ' Initialize SPI Engine with Clock Delay of 15 and Clock State of 0

    gr.start                       'Start the VGA graphics driver
    repeat i from 0 to tiles - 1   'init tile colors
      gr.color(i,$3000)
      
    LOW(nPD)                       'Hold in reset until ready    
    HIGH(nSS)                      
    HIGH(nRESET)                   
    waitcnt(cnt+clkfreq/100)       'wait for everything to stablilze
    HIGH(nPD)
    waitcnt(cnt+clkfreq/100)       'wait for power up

    ''peak hold option
    peakhold := 0

    ''cursor position
    cursor := 0

    ''verify communication to module is good (check ID register) 
    if ReadReg(REG_ID) == $7 'good communication
      ''set up options
      WriteReg(REG_CLOCK_MANUAL, $41)
      WriteReg(REG_CLOCK_ENABLE, $41)        
      WriteReg(REG_CONTROL, $10)
      WriteReg(REG_ANALOG_CTL, $40)                  
      WriteReg(REG_CARRIER_DETECT, $80)

      ''main loop
      repeat
        ''cycle though all channels
        repeat i from 0 to 127
          ''buffer RSSI values (creates the fastest sweep to get as instantaneous of a reading as possible, and a faster draw)
          WriteReg( REG_CHANNEL, i) 'select channel         
          WriteReg( REG_CONTROL, $90) 'enable receiver
          level := ReadReg( REG_RSSI )&$1F 'get RSSI value
          if (NOT peakhold) OR (peakhold AND (level>buffer[i]))
            buffer[i] := level 'update value
          WriteReg( REG_CONTROL, $10 ) 'disable receiver

        ''set up screen
        gr.clear
        gr.pointcolor(1) 
        gr.text(32,10,string("VGA 2.4GHz Spectrum Analyzer"))      
        gr.text(20,350,string("2.400"))
        gr.text(420,350,string("2.527"))
        gr.line(70, 330,127*3+70,330)

        ''draw cursor to screen
        gr.text(20,40,string("Cursor -"))
        gr.line(cursor*3+70, 345,cursor*3+70,98)
        gr.text(170,40,string("FRQ:"))
        gr.SimpleNum(310,40,2400+cursor,3)
        gr.text(350,40,string("PWR:"))
        gr.SimpleNum(475,40,buffer[cursor],0)

        ''draw spectrum to screen                
        repeat i from 1 to 127
          gr.line((i-1)*3+70, 330-7*buffer[i-1],i*3+70,330-7*buffer[i]) 'draw line from previous to current

        ''display HOLD if in peak hold mode
        if peakhold
          gr.text(240,350,string("HOLD"))
            
    else 'bad communication
      gr.text(16,0,string("Failed to connect to module"))    
      repeat


PUB WriteReg(reg, val)
  ''Write CYWM6935 Register
    LOW(nSS)
    SPI.SHIFTOUT(MOSI, SCK, SPI#MSBFIRST , 8, WRITE_REG|reg)
    SPI.SHIFTOUT(MOSI, SCK, SPI#MSBFIRST , 8, val)
    HIGH(nSS)

PUB ReadReg(reg)|rcv_byte
  ''Read CYWM6935 Register
    LOW(nSS)
    SPI.SHIFTOUT(MOSI, SCK, SPI#MSBFIRST , 8, READ_REG|reg)
    rcv_byte := SPI.SHIFTIN(MISO, SCK, SPI#MSBPRE, 8)
    HIGH(nSS)    
    return rcv_byte
     
PUB HIGH(Pin)
  ''Make pin output and write high
    dira[Pin]~~
    outa[Pin]~~
         
PUB LOW(Pin)
  ''Make pin output and write low
    dira[Pin]~~
    outa[Pin]~

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}    