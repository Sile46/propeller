{{
┌───────────────────────────────────────────────────┐
│ GOLDEtest.spin version 1.0.0                      │
├───────────────────────────────────────────────────┤
│                                                   │               
│ Author: Mark M. Owen                              │
│                                                   │                 
│ Copyright (C)2015 Mark M. Owen                    │               
│ MIT License - see end of file for terms of use.   │                
└───────────────────────────────────────────────────┘

Description:

  Minimal tests of GOLDE_UI.spin and associated code.

Revision History:
  Initial release 2015-Feb-10

}}

CON
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000                       ' external crystal 5MHz

  ULCDCTS       = 13            ' AKA IO1
  ULCDRESET     = 14            ' active low
  ULCDTX        = 15     
  ULCDRX        = 16

OBJ
  UI    : "GOLDE_UI"

PUB Main  | n, n8,nout
  UI.Start(ULCDRX,ULCDTX,ULCDCTS,ULCDRESET)
  UI.Textsize(1)
  UI.ClearHome
  UI.GetGeometry
  UI.GetCharGeometry
  
  UI.ColorBG(UI#BLACK)
  UI.Clear

  UI.LinePattern(%0011_1000_0111_1101)
  UI.Color(UI#RED)
  UI.MoveTo(0,0)
  UI.LineTo(UI.Xmax,UI.Ymax)
  UI.LinePattern(0)
  UI.Color(UI#RED)
  UI.Rectangle(0,0)
   
  UI.Color(UI#GREEN)
  UI.MoveTo(UI.Xmax>>2,UI.Ymax>>2)
  UI.Rectangle(UI.Xmax>>1,UI.Ymax>>1)
   
  UI.LinePattern($0)
  UI.Color(UI#BLUE)
  UI.MoveTo(UI.Xmax>>1+1,UI.Ymax>>1+1)
  UI.Circle(32)
   
  UI.FillMode(UI#SOLIDFILL)
  UI.Color(UI#YELLOW)
  UI.MoveTo(UI.Xmax>>1,UI.Ymax>>1)
  UI.Circle(16)
  UI.FillMode(UI#OUTLINE)
   
  UI.OneLED(UI.Xmax>>1,UI.Ymax>>1,UI#BLUE)
  UI.SetStrAtIx(string("Aetherial"),0)
  UI.SetStrAtIx(string("Enterprises"),1)
   
  UI.TextOpacity(UI#TRANSPARENT)
  UI.Textsize(2)
  UI.TextAttributes(UI#NORMAL)
  UI.StrIxAt(0,0,1)
  UI.Textsize(1)
  UI.TextAttributes(UI#ITALIC)
  UI.StrIxAt(1,3,4)
   
  UI.TextOpacity(UI#OPAQUE)
  UI.TextAttributes(UI#UNDERLINED)
  UI.StrAt(string("hex  count:"),3,10)
   
  n~
  n8~
  repeat
    if n8<>(n>>8)
      n8 := n>>8 
      UI.EightLEDs(25,UI.Ymax-20,n8)
    nout := n &$FFFF
    UI.EightLEDs(25,UI.Ymax-10,nout)
    UI.Hex4At(nout,3,11)
    UI.PrintIntAt(nout,8,11)
    UI.Str(string(" "))
    n++
   
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