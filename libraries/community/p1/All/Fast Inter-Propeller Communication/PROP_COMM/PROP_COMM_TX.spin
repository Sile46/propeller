''*********************************************
''*  Fast Prop-Prop Comm TX v1.0              *
''*  Sends information quickly between Props  *
''*  Author: Brandon Nimon                    *
''*  Created: 16 September, 2009              * 
''***********************************************************************************
''* Requires pull-down on communication line.                                       *
''*  TX Prop──┳──RX Prop                                                          *
''*            10K                                                                 *
''*                                                                                *
''* The difference in clock speed between the two Propellers cannot excede 0.2%.    *
''* Transfers information at 2 instructions per bit (8 cycles).                     *
''* Data transfers have been tested at 100MHz with 0 errors. That is 12.5Mbaud.     *
''*                                                                                 *
''* Outputs at about 8.66 million bits per second (@80MHz), including PASM          *
''* overhead. This ends up being 270K longs every second (over 1MB/s). Transferred  *
''* at bursts of 10Mbaud.                                                           *
''*                                                                                 *
''* Transmission methodology puts one high start cycle, and after each long (while  *
''* the next long in the buffer is being retrieved) line will remain low as a stop  *
''* bit. After entire buffer is sent, the cog waits for an acknowledge bit on the   *
''* same line.                                                                      * 
''*                                                                                 *
''* To be sure that both Propellers are operating at the same clockspeed, it may be *
''* good practice to send a $5555_5555 value as the first long, and check on the RX *
''* cog to make sure that value came through.                                       *
''***********************************************************************************  

CON
                                     
  BUFFER_SIZE = 512                                    ' longs to send and recieve (always sends all longs), must be equal or less than RX cog
  
OBJ

VAR

  '' DO NOT REARRANGE LONGS
  long conf                                             ' confirmation to send values, and confirmation when completed transmition
  long buffer[BUFFER_SIZE]   
  byte save_pin                                         ' save pin number for later (for watchdog timeout)      
  byte cogon, cog

PUB send (pin)
'' starts TX cog

  stop
  conf := 0
  txpin := pin
  save_pin := pin
  cogon := (cog := cognew(@tx_entry, @buffer))
  RETURN @buffer

PUB stop
'' Stops cog if running
              
  IF (cogon~)
    cogstop(cog)

PUB transmit
'' sends instruction to PASM to send current buffer
'' if the buffer is altered before it has completed the previous transmition, transmitted data may be different than what is expected

  REPEAT WHILE (conf)                                   ' make sure previous message has completed sending and ACK bit recieved
  conf := true                                          ' send what is currently in buffer
  RETURN @buffer

PUB transmitwait
'' sends instruction to PASM to send current buffer, then waits for it to complete transmission
'' this (or the watchdog version) is the recommended for use, to make sure altertaions to the buffer do not occur 

  conf := true                                          ' send what is currently in buffer
  REPEAT WHILE (conf)                                   ' wait until message is sent and ACK bit recieved
  RETURN @buffer

PUB transmitwait_wd (watchdogms) | waitstart, waitlen
'' sends instruction to PASM to send current buffer, then waits for it to complete transmission
'' this will also time out based on the watchdogms time (time in milliseconds to wait)
'' returns address of buffer after reception of ACK bit
'' if watchdog times out, returns false (0) and restart send cog

  conf := true                                          ' send what is currently in buffer
  waitlen := clkfreq / 1_000 * watchdogms               ' calculate time to wait
  waitstart := cnt                                      ' start watchdog timer
  REPEAT UNTIL (NOT(conf) OR cnt - waitstart => waitlen)
  IF NOT(conf)
    RETURN @buffer
  ELSE
    send(save_pin)                                      ' restart cog (timeout probably caused by lack of ACK return)
    RETURN false
    

DAT
                        ORG 0
tx_entry
                        MOV     txmask, #1
                        SHL     txmask, txpin           ' setup mask

                        MOV     txconfAddr, PAR
                        SUB     txconfAddr, #4
                        
                        MOV     CTRA, nco
                        ADD     CTRA, txpin             ' NCO on this pin number
                        MOV     DIRA, txmask            ' set pin as output

tx_bloop                MOV     txptr, PAR              ' get input buffer address
                        MOV     txbidx, txbsize
                        
:wait                   RDLONG  p1, txconfAddr  WZ      ' wait for "send" command
              IF_Z      JMP     #:wait

tx_loop                 RDLONG  txval, txptr            ' get current output long
                        ADD     txptr, #4               ' move read pointer one long
                        MOV     txidx, #31              ' set for 32 bits (a long)
                        
                        MOV     PHSA, txnegone          ' send a one-instruction pulse
                        MOV     PHSA, txval             ' setup NCO output

:loop                   SHL     PHSA, #1                ' set next bit
                        DJNZ    txidx, #:loop

                        MOV     PHSA, #0                ' make sure 0 output

                        DJNZ    txbidx, #tx_loop        ' do next long until done with buffer

                        MOV     DIRA, #0
                        WAITPEQ txmask, txmask          ' this if for a simple ACK bit from RX object
                        WRLONG  zero, txconfAddr        ' reset send command
                        MOV     DIRA, txmask
                        
                        JMP     #tx_bloop                        

txnegone                LONG    -1
nco                     LONG    %00100 << 26
txbsize                 LONG    BUFFER_SIZE
txpin                   LONG    0                       ' set in SPIN
zero                    LONG    0

txval                   RES
txmask                  RES
txidx                   RES
txbidx                  RES
txptr                   RES
p1                      RES
txconfAddr              RES

                        FIT 496                        
  
 