{{
''*******************************************
''*  PWM DEMO Object                   V1.1 *
''*  Author: Beau Schwabe                   *
''*  Copyright (c) 2009 Parallax, Inc.      *               
''*  See end of file for terms of use.      *               
''*******************************************

Revision History:
  Version 1.0   - (05/01/2009) initial release
  Version 1.1   - (05/11/2011) edited some of the descriptive text

}}
CON
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000

OBJ     PWM     : "PWM_32_v4.spin"

PUB DEMO_Example | DutyCycle
''-------- This Block Starts the PWM Object ----------
    PWM.Start                   '' Initialize PWM cog


''-------- This Block sets a Standard servo on Pin 0 to it's center Position ----------
    PWM.Servo(0,1500)           '' Define Pin0 with a standard center position
                                '' servo signal ; 1500 = 1.5ms

                                 ' Most servo's will accept a value ranging from 1ms to 2ms
                                 ' Parallax servos will operate from 0.5ms to 2.5ms ... or 500us to 2500us

                                 ' The Width of this pulse determines the servo's position with 1500 positioned
                                 ' at center.  The pulse to the servo's must be repeated at a rate of 50 times
                                 ' per second.  The PWM.Servo takes care of this for you where all you need to
                                 ' do is set it and forget it and it will keep generating the signal for you. 


''-------- This Block creates a 3-Phase 60Hz square wave on Pins 1,2, and 3 -----------
    PWM.Duty(1,50,16666)        ''Create a 60Hz 50% duty cycle on Pin1
    PWM.Duty(2,50,16666)        ''Create a 60Hz 50% duty cycle on Pin2
    PWM.Duty(3,50,16666)        ''Create a 60Hz 50% duty cycle on Pin3
    
                                 ' The Period is calculated by taking the inverse of the desired frequency
                                 ' 1/60Hz = 16.666ms ; since the value entered is in micro seconds this
                                 ' value needs to be multiplied by 1000 so it becomes 16666

                                 ' If you wanted a 100Hz PWM , then 1/100Hz = 10ms -> X 1000 = 10000

                                 ' i.e. PWM.Duty(3,50,10000) produces a 100Hz 50% duty cycle on Pin 3  
        
    
    PWM.PhaseSync(1,2,5555)     ''Phase Sync Pin2 to Pin1 with a Phase leading by 120 Deg    
    PWM.PhaseSync(2,3,5555)     ''Phase Sync Pin3 to Pin2 with a Phase leading by 120 Deg

                                 ' If in the above example 16666 represents 1 period or 360 Deg, then
                                 ' 5555 represents 1/3rd of a period or 120 Deg

                                 ' In this same example, if you wanted the pins 90 Deg out of Phase, then
                                 ' 4166 would represent 1/4th of a Period

                                 ' i.e PWM.PhaseSync(1,3,4166) would sync Pin3 to Pin1 with a Phase leading
                                 ' by 90 Deg
    


''-------- This Block creates a PWM pulse on pin 4 with a duty ratio of 1:10 -----------
    PWM.PWM(4,1,10)             '' Creates a pulse with 1 On-Time unit and 10 Off-Time
                                '' units on Pin 4

                                 ' Each 'unit' is 8.2us so in this example there are a total of 11
                                 ' units. (1+10=11) or 90.2us (11x8.2us=90.2us).   Taking the inverse
                                 ' of this you can determine the base frequency.  In this case 11.09kHz

                                 ' Suppose you wanted a base frequency of 8kHz.  The inverse of 8kHz
                                 ' is a period of 125us.  125us divided by 8.2us yields about 15 units.

                                 ' i.e. PWM.PWM(4,1,14) ; Creates a pulse with 1 On-Time unit and 14
                                 ' Off-Time units resulting in a frequency of 8.13kHz on pin 4


''-------- This Block creates a speed up/down Motor test on Pin7 -----------
    repeat
      repeat DutyCycle from 0 to 100
        PWM.Duty(7,DutyCycle,5000)       '' Ramp Duty cycle up from 0 to 100               
        repeat 10000
      repeat 1000000                     '' Hold at 100% for a little bit
        
      repeat DutyCycle from 100 to 0
        PWM.Duty(7,DutyCycle,5000)       '' Ramp Duty cycle down from 100 to 0
        repeat 10000
      repeat 1000000                     '' Hold at 0% for a little bit


'-------- Extra Stuff -----------

'' PWM.StateMode(Pin,State)
' Used behind the scenes but available to the user, this function allows you to
' Enable/Disable a pin...  If State = 0 pin is Disabled, if State = 1 pin is Enabled



'' DutyMode(Pin,Mode)
' Also used behind the scenes but available to the user, this function allows you to
' Force the output state of a pin to a HIGH or a LOW regardless of what Ton or Toff is
' telling the pin to do .  This is especially useful when creating a pulse that needs to
' cover the full duty range of 0% to 100%
'
' If Mode = 1 then the Pin will be forced HIGH ; If Mode = 2 then the Pin will be forced
' LOW ; Any other value for Mode, causes the pin to resume it's default state which will
' follow what Ton and Toff are telling it to do.  

CON
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
