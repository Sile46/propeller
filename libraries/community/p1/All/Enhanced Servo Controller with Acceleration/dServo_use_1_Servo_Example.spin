{{

┌──────────────────────────────────────────┐
│ dservo_use_1_Servo_Example          v1.0 │
│ Author: Diego Pontones                   │               
│ Copyright (c) 2010 Diego Pontones        │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

INTRODUCTION

The following object is an example on how to use the dServo object to control 1 servo (most basic use).

HISTORY
  v1.0  2010-03-24  Beta release
                          
}}   


CON
   
  _clkmode        = xtal1 + pll16x           ' Feedback and PLL multiplier = 80 MHz  
  _xinfreq        = 5_000_000                ' External oscillator = 5 MHz

  NumServos = 1                              ' Number of servos to control 1 to 14

  
VAR

  byte pin[NumServos]                        ' Propeller pin numbers for each servo. 
  long CurrPos[NumServos]                    ' Contains the current Pulse Width (Position) for each servo, -1000 to 1000 
  long NewPos[NumServos]                     ' Enter the desired New Pulse Width (Position) for each servo, -1000 to 1000 
  long NumPulses[NumServos]                  ' Number of Pulses to be sent for each servo. (pulse period is 20 ms, 50 ms = 1 sec)
  long GradMove                              ' One bit for each servo. If bit is set then movement will be gradual.
  long AccDecMove                            ' One bit for each servo. If bit is set then movement will have Acceleration/Deceleration. 
  long HoldPulse                             ' One bit for each servo. If bit is set then pulses will be sent continuously to hold the new position


OBJ

   servos : "dServo"                         ' Declare Servos object

PUB testServos  | index, startOK             ' Example on how to control one servo

  pin[0]   := 15               'Initialize value of propeller pin connected to the servo    
  NumPulses[0] := 0            'Initialize number of pulses pending to be sent to the servo as cero
  NewPos[0] := CurrPos[0]:= 0  'Initialize starting and current servo positions

  'Once the initial positions have been initialized start the servos object in a new cog.
  startOK := servos.start(@pin[0], @CurrPos[0], @NewPos[0], @NumPulses[0],@GradMove,@AccDecMove,@HoldPulse, NumServos)            

  'Move servo to position 800, using Accelerated/Decelerated move, lasting 2 seconds, and sending holding pulses at the end.
  GradMove:= %0 'No Gradual Movement
  AccDecMove:= %1  'Use Accelerated/Decelerated movement
  HoldPulse:= %1   'Send holding pulses
  NewPos[0]:= 800
  NumPulses[0]:= 100 'Execute movement
  repeat while NumPulses[0] 'Wait for movement to complete

  waitcnt(clkfreq * 4 + cnt) 'Wait 4 seconds

  'Move servo to position -800, using Gradual move, lasting 6 seconds, and then idle the servo at the end.
  GradMove:= %1 'Gradual Movement
  AccDecMove:= %0  'Do not use Accelerated/Decelerated movement
  HoldPulse:= %0   'Do not Send holding pulses
  NewPos[0]:= -800
  NumPulses[0]:= 300 'Execute movement
  repeat while NumPulses[0] 'Wait for movement to complete

  waitcnt(clkfreq * 4 + cnt) 'Wait 4 seconds

  'Move servo to position 0 (center), using Immediate move, send 40 pulses, and then idle the servo at the end.
  GradMove:= %0 'No Gradual Movement
  NewPos[0]:= 0
  NumPulses[0]:= 40 'Execute movement
  repeat while NumPulses[0] 'Wait for movement to complete

  waitcnt(clkfreq * 4 + cnt) 'Wait 4 seconds  

  servos.stop            'Stop the servos object.



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