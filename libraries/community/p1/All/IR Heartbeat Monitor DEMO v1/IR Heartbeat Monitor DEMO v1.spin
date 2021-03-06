{{
*****************************************
* IR Heartbeat Monitor DEMO          v1 *
* Author: Beau Schwabe                  *
* Copyright (c) 2013 Parallax           *
* See end of file for terms of use.     *
*****************************************


 History:
                            Version 1 - 07-18-2013      initial release


Schematic:

                                      
          1k   2.2k    10u 10k  330
ADC I/O ──┳─────────┳──╋──┐
            0.047u  1M │    │    │
                 ┌─┐┌──┫    │    │
               RX  ││ ┌──┼────┘    │
                   ┣┌ 2n3904  │
            TX ┌┐ └┘ └┘    x2    │
               │                   │
               └────────────────────┘
               
Note: RX is reverse biased
      All "" = Vss
      All "" = Vdd
      
               
Theory of Operation:

The two 2n3904's, 1M and 10k resistor form an auto balanced transistor bias
with an output at the 1M and 10k node.  The RX in this design is reverse biased
and utilized as a capacitor which has a "leakage" proportional to the amount
of IR light that falls upon it resulting in a detectable signal.  The 10u
serves as a DC block only allowing an AC signal to pass.  The 1k, 2.2k, and
0.047u serve as the necessary components for a single pin Sigma Delta ADC.
The 330 Ohm resistor and TX provide the source IR for the RX detector.


Program:

This program maintains an ongoing average of the incoming data, and responds
when the incoming data is substantially different than the average data.  A
maximum value with decay, meaning that it slowly migrates back to zero, is
maintained to auto calibrate to the incoming heartbeat pulses.  Each pulse is
measured and the current beats per minute are displayed serially.

}}                            

CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

ADC_Samples = 25


OBJ

PST             : "Parallax Serial Terminal"
SD_ADC          : "Single Pin Sigma Delta ADC Driver v1"
PWM             : "PWM_32_v4"

VAR

long    ADC_Sample,ADC_Avg,ADC_DB,ADC_Out
long    Pulse,Rate,Decay,OldRate,ADC_Max

PUB start |i

    ctra := constant(%11111 << 26)                      'LOGIC Always
    frqa := 1                                           'Start CounterA

    PST.Start(19200{<- Baud})
    PWM.Start

    SD_ADC.Start(0,25000,@ADC_Sample) 

    repeat

      ADC_DB := ADC_DB - ADC_Avg + ADC_Sample
      ADC_Avg := ADC_DB / ADC_Samples

      ADC_Out := 0 #> (ADC_Sample-ADC_Avg) <# 100

      if ADC_Out > ADC_Max
         ADC_Max := ADC_Out

      if ADC_Out => ADC_Max and Pulse == 0
         Pulse := 1
         Rate := phsa / 10000
         Rate := 480000 / Rate
         phsa := 0

         If Rate > 200 or Rate < 25
            Rate := OldRate
         OldRate := Rate
         
      if ADC_Out == 0 and Pulse == 1
         Pulse := 0


      Decay += 1
      If Decay == 10
         ADC_Max := 0 #> (ADC_Max - 1)
         Decay := 0



      PST.dec(Rate)


      PST.Char(13{<- Return character})
      repeat i from 16 to 23
        PWM.Duty(i,ADC_Out,1500)      


DAT
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