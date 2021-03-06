{{
The purpose of this controller is to receive information from the Pulsadis Head via
serial communication, format it and add a timestamp, then display it on the Parallax Serial Terminal or any
other terminal and store the messages on an SD card for further analysis.
}}
CON
_clkmode = xtal1 + pll16x
_clkfreq = 80_000_000

' IO pins used for sdcard
  'CD  = 4       ' Propeller Pin 4 - Uncomment this line if you are using the Chip Detect function on the card. See below. 
  CS  = 3       ' Propeller Pin 3 - Set up these pins to match the Parallax Micro SD Card adapter connections.
  DI  = 2       ' Propeller Pin 2 - For additional information, download and refer to the Parallax PDF file for the Micro SD Adapter.                        
  CLK = 1       ' Propeller Pin 1 - The pins shown here are the correct pin numbers for my Micro SD Card adapter from Parallax                               
  D0  = 0       ' Propeller Pin 0 - In addition to these pins, make the power connections as shown in the following comment block.
' IO pins used to communicate serially with Pulsadis controller
  rxpin = 24       ' mouse pins 24 and 25 used as RX and TX serial pins via a mouse connector
  txpin = -1
  baudrate = 19200 ' baudrate used for this serial communication                                      
                      
OBJ
RTC     : "RealTimeClock"                               ' keep running clock and perform time and date formatting
vp      : "Parallax Serial Terminal"                    ' output to terminal
com     : "Full-Duplex_COMEngine.spin"                  ' serial input from Pulsadis header
sdfat   : "fsrw"                                        ' sd card driver                                                         

VAR
byte inbuf[512]  ' serial comm buffer - bigger than really needed

PUB start | returncode
  vp.start(115200)              ' open link with display terminal on PC
  waitcnt(clkfreq * 3 + cnt)    ' wait to give enough time to run logging terminal application
  vp.str(string(16,"hello",13))

  com.COMEngineStart(RXpin,TXpin,baudRate) ' open link with Pulsadis Header
  com.receiverFlush                        ' just to be clean

  ' let's check if sdcard present an mountable, then let's unmount it 
  returncode := \sdfat.mount_explicit(D0, CLK, DI, CS)        ' Here we call the 'mount' method using the 4 pins described in the 'CON' section.
  if returncode < 0                                           ' If mount returns a zero...
    vp.str(string(13,"Micro SD Card not found, Insert card, or check your connections.",13)) ' Remind user to insert card or check the wiring.
    abort                                                      ' Then we abort the program.
  sdfat.unmount                           ' This line    dismounts the card so you can safely remove it.   
  vp.str(string(13,"Micro SD card was found!",13))                  ' Let the user know the card is properly inserted.
  vp.str(string(13,"press <ENTER> to start",13))                        ' Remind the user to press <ENTER> after each entry
  vp.CharIn                                       ' wait for any key pressed to continue
  
  InitClock                     ' ask operator what's current time and set clock accordingly

  vp.str(RTC.ReadStrdate(0))                 ' get timestamp and print it. Parameter zero means European date format  
  vp.char(" ")
  vp.str(rtc.readstrtime)
  vp.char(" ")
  vp.str(string("Ready"))
  vp.newline
      
  repeat                                                 ' main loop      
    inbuf := com.readString(@inbuf, 512)       ' wait for a line of data from pulsadis header
    vp.str(RTC.ReadStrdate(0))                 ' get timestamp and display it. Parameter zero means European date format  
    vp.char(" ")
    vp.str(rtc.readstrtime)
    vp.char(" ")
    vp.str(@inbuf)                             ' recopy data from pulsadis header to display terminal
    returncode := \sdfat.mount_explicit(D0, CLK, DI, CS)        ' Let's remount the sdcard.
     if returncode < 0                                           ' If error..
        vp.str(string(13,"Micro SD Card not found or error.",13)) ' Remind user to insert card or check the wiring.
        abort                                                 
    sdfat.popen(string("pulsadis.txt"), "a")  ' Open output file in append mode "a". Overwrite would be "w".
    sdfat.pputs(rtc.readstrdate(0))           ' copy timestamp in the file as record header
    sdfat.pputc(" ")                          ' append a separator
    sdfat.pputs(rtc.readstrtime)
    sdfat.pputc(" ")                
    sdfat.pputs(@inbuf)                     ' Recopy data from Pulsadis header.
    sdfat.pputc(10)                         ' mark end of record 
    sdfat.pputc(13)                         ' mark end of record 
    sdfat.pclose                            ' Close the file
    sdfat.unmount                           ' Redismount to make it hot swappable.    

   

pub InitClock | hh,mm, dd, value
 'Preset time/date manually in the code, could be automated via an external time source such as DCF77
   RTC.Start                     'Start Real time clock COG used for logging timestamp

   repeat
    vp.Chars(vp#CS, 1)
    vp.Str(String("Enter day : "))   
    dd := vp.decin
    vp.Chars(vp#NL, 1)                                                      

    vp.Str(String("Enter hours : "))                                  '
    hh := vp.DecIn                                                         'Get number (in decimal).
    vp.Chars(vp#NL, 1)
                                                     
    vp.Str(String("Enter minutes : "))                                 
    mm := vp.DecIn                                                         'Get number (in decimal).

    RTC.SetTime(hh,mm,00)                         
    RTC.SetDate(dd,05,13)
   
    waitcnt(cnt+clkfreq) ' wait for clock to setup     
    
    vp.str(RTC.ReadStrdate(0))                 ' get timestamp and print it. Parameter zero means European date format  
    vp.char(" ")
    vp.str(rtc.readstrtime)
    vp.char(" ")
                                                                                        
    vp.Str(String("OK? (Y/N):"))                        'Prompt to repeat
    value := vp.CharIn
       
   while (value <> "Y") and (value <> "y")  

   vp.Chars(vp#NL, 2) 