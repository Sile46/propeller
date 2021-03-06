{{

Demonstation of the finite state machine runner in "FSMRunner.spin". See the
comments in that object for a full description of the state machine
syntax.

See the end of this file for terms of use.     

This example state machine simulates the coin input for a 25 cent soda
machine (those were the days). Launch this program and then launch the
serial terminal. Type the characters 'N', 'D', and 'Q' to put in a
nickel, dime, or quarter. Type the character 'S' to request a soda.


 N = INPUT nickel
 D = INPUT dime
 Q = INPUT quarter
 SODA = INPUT give-soda
 
 n = REFUND nickel
 d = REFUND dime
 q = REFUND quarter
 soda = Dispense soda

 For instance, if the machine is in state S10 (ten cents received) and
 the user puts in a quarter (Q) then the machine transitions to state
 S25 and reunds a dime (d) along the way.   

                  ┌────────────────────┐
                  │                    │
       ┌──────────┼─────────┐ ┌────────┼──────────┐  
      D│         D│          │D                 
    ┌──┴──┐N   ┌──┴──┐N   ┌───┴─┐N   ┌─────┐N   ┌─────┐Q
 ┌─│ S0  ├───│ S5  ├───│ S10 ├───│ S15 ├───│ S20 ├─┐
 │  └──┬──┘    └──┬──┘    └──┬──┘   D└─┬─┬─┘    └─┬─┬─┘ │d,d
 │     │Q         │Q        Q│  ┌──────┘ │Q      N│ │D  │
 │     │          │n        d│  │  ┌─────┘d,n     │ │n  │
 │     │          └───────┐  │  │  │  ┌───────────┘ │   │
 │     └───────────────┐  │  │  │  │  │  ┌──────────┘   │
 │                                               │
 │                    ┌────────────────────┐            │
 │                    │                    │            │
 │  soda         SODA │        S25         │───────────┘
 └────────────────────┤                    │
                      └─┬──────┬─────┬─────┘
                        │N n  │D d │Q q
                        └───┘  └───┘ └───┘                                                 
}}

CON
  _clkmode        = xtal1 + pll16x
  _xinfreq        = 5_000_000
  
OBJ    
    PST  : "Parallax Serial Terminal"
    FSM  : "FSMRunner"

pri PauseMSec(Duration)
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
      
PUB Main | fn, param, retVal
    
  PauseMSec(2000)
  PST.Start(115200)

 ' Main loop
  mainLoop(@S0)
  ' Does not return      

PRI mainLoop(state) | fn, retVal

  FSM.init(state,@@0)
  repeat
    ' Wait for a function request
    repeat while FSM.isFunctionRequest == 0

    ' Dispatch the function
    fn := FSM.getFunctionNumber
    retVal := dispatch(fn)

    ' Return any response
    FSM.replyToFunctionRequest(retVal)

    
PRI GetEvent | c
  '' This function is called by the state machine runner to check for any
  '' pending event. Return 0 if there are no events. Or return a pointer
  '' to the event name string.

  c := PST.RxCount
  if c ==0
    return 0

  c := PST.CharIn

  case c
    "N" :
      PST.str(string("<click> You put in a nickel",13))
      return @STR_NICKEL
    "D" :
      PST.str(string("<bink> You put in a dime",13))
      return @STR_DIME
    "Q" :
      PST.str(string("<clunk> You put in a quarter",13))
      return @STR_QUARTER
    "S" :
      PST.str(string("You pressed the soda button",13))
      return @STR_SODA 

PRI refundNickel
  PST.str(string("You got back a nickel",13))
  
PRI refundDime
  PST.str(string("You got back a dime",13))
  
PRI refundQuarter
  PST.str(string("You got back a quarter",13))
  
PRI dispenseSoda
  PST.str(string("You have a nice cold soda",13))

PRI showDeposit | val

  ' The state machine can pass parameters to the function
  val := FSM.getFunctionParameter(0)
  
  PST.str(string("Total of "))
  PST.dec(val)
  PST.str(string(" cents deposited.",13))

DAT

' These are event name strings that match the event names in the
' state machine declaration following. These are used by the code above
' to inject events into the state machine.

' Notice these are WORD and not BYTE. These match the WORD definitions in the
' machine declaration (see below).

STR_NICKEL  word "##NICKEL##" 
STR_DIME    word "##DIME##"   
STR_QUARTER word "##QUARTER##"
STR_SODA    word "##SODA##"

' This is the state machine declaration that the runner uses. This was crated
' by hand from the picture in the comments at the top.

fsmData

' Notice that entries are WORD and not BYTE. This allows 16-bit pointers for
' target state declaration. Your function arguments can also be 16-bit pointers
' to other items in DAT (like images, tables, etc).

S0
  ' This is an "enter state" function. It is called anytime the state is entered.
  ' The "0" here is an argument to the function. You can list as many as you like
  ' or none at all. If you want to call multiple functions use the "%%" separator
  ' as in state "S15" below.
  word "##!##", FN_showDeposit, 0

  ' This is an example of a timeout function. After 50*100ms (5 seconds) the
  ' timeout goes back to state S0 and you get a free nickel. Again, just an
  ' example. Uncomment the next line to see the timeout in action.
'  word "##T##", 50,   @S0, FN_refundNickel

  ' These are events. The name of the event and the target state is required.
  ' You can also call one or more "edge" functions on the way to the target
  ' state. These edge functions can return a new destination state thus
  ' override the specified destination.
  word "##NICKEL##",  @S5
  word "##DIME##",    @S10
  word "##QUARTER##", @S25

  ' This is the marker for the end of the state
  word "@@"

S5
  word "##!##", FN_showDeposit, 5
  word "##NICKEL##",  @S10
  word "##DIME##",    @S15
  word "##QUARTER##", @S25, FN_refundNickel
  word "@@"

S10
  word "##!##", FN_showDeposit, 10
  word "##NICKEL##",  @S15
  word "##DIME##",    @S20
  word "##QUARTER##", @S25, FN_refundDime
  word "@@"

S15
  word "##!##", FN_showDeposit, 15
  word "##NICKEL##",  @S20
  word "##DIME##",    @S25
  word "##QUARTER##", @S25, FN_refundDime, "%%", FN_refundNickel
  word "@@"

S20
  word "##!##", FN_showDeposit, 20
  word "##NICKEL##",  @S25
  word "##DIME##",    @S25, FN_refundNickel
  word "##QUARTER##", @S25, FN_refundDime, "%%", FN_refundDime
  word "@@"   
    
S25
  word "##!##", FN_showDeposit, 25
  word "##NICKEL##",  @S25, FN_refundNickel
  word "##DIME##",    @S25, FN_refundDime
  word "##QUARTER##", @S25, FN_refundQuarter
  word "##SODA##",    @S0,  FN_dispenseSoda
  word "@@"
  

CON
  ' There are no "pointers to functions" in SPIN so we use a dispatch
  ' table to reference a function by name.
  FN_refundNickel  = 256
  FN_refundDime    = 257
  FN_refundQuarter = 258
  FN_dispenseSoda  = 259
  FN_showDeposit   = 260
  
PRI dispatch(fn)
  CASE fn
    0:
      return GetEvent        
      
    FN_refundNickel:
      return refundNickel
         
    FN_refundDime:
      return refundDime
      
    FN_refundQuarter:
      return refundQuarter
      
    FN_dispenseSoda:
      return dispenseSoda

    FN_showDeposit:
      return showDeposit

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