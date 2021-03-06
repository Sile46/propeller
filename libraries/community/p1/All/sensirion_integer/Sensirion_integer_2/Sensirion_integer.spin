''=============================================================================
'' @file     sensirion_integer.spin
'' @target   Propeller with Sensirion SHT1x or SHT7x   (not SHT2x)
'' @author   Thomas Tracy Allen, EME Systems
'' Copyright (c) 2013 EME Systems LLC
'' See end of file for terms of use.
'' version 1.3
'' uses integer math to return values directly in degC*100 and %RH*10
'  bad read or out-of-range are returned as negx
'' no floating point required
''
'' derived from sensirion.spin by
'' @author   Cam Thompson, Micromega Corporation
'' Copyright (c) 2006 Micromega Corporation
'' http://obex.parallax.com/objects/21/
'' See end of file for terms of use.
'' @version  V1.0 - July 11, 2006
'' @changes
''  - original version
''=============================================================================

CON
  CMD_TEMPERATURE = %00011                              ' measure temperature
  CMD_HUMIDITY    = %00101                              ' measure humidity
  CMD_READSTATUS  = %00111                              ' read status
  CMD_WRITESTATUS = %00110                              ' write status
  CMD_RESET       = %11110                              ' soft reset

  T_OFFSET_5V0 = 4000
  T_OFFSET_3V3 = 3964
  T_OFFSET_3V0 = 3960

  T_OFFSET = T_OFFSET_3V3
           
VAR
  long  t100
  byte  dpin, cpin, mode

PUB Init(data_pin, clock_pin)
  ' assign SHT-11 clock and data pins and reset device
  dpin := data_pin                                      ' assign data pins                       
  cpin := clock_pin                                     ' assign clock pin
  outa[cpin]~                                           ' set clock low
  dira[cpin]~~
  outa[dpin]~~                                          ' set data high
  dira[dpin]~~                                           
  repeat 9                                              ' send 9 clock pulses for reset
    !outa[cpin]                                         
    !outa[cpin]

PUB ReadTemperature | ack
  ' read SHT-11temperature value
  ack := SendCommand(CMD_TEMPERATURE)                   ' measure temperature, 14 bit, 3.3V supply
  if Wait == 1                                          ' wait until done
    return negx                                         ' timeout
  t100 := ReadWord               '                      ' calculate in units of 1/100th degC
  if mode
    t100 <<= 2                                           ' 12 bit RH left 2 to become 14 bit
  if t100 ==0 OR t100 > $3ff0                           ' traps data line stuck at zero, or temperature >124 degC
    t100 := negx
  else
    t100 -= T_OFFSET
  return t100                                           ' Celsius temperature as integer xxxx, in units of 1/100 degree Celsius

PUB ReadHumidity : rh100 | ack, raw
  ' read SHT-11 humidity value
  ' expected range is 98 at 0%RH to 2226 at 100%
  if t100==negx
    return negx                                         ' don't bother if temperature is bad
  ack := SendCommand(CMD_HUMIDITY)                      ' measure humidity, 12 bit
  if Wait == 1
    return negx                                         ' timeout
  raw := ReadWord
  if mode
    raw <<= 4                                           ' 8 bit RH left 4 to become 12 bit
  if raw < 50 OR raw > $FFC                             ' traps data line stuck low, or impossibly low or high value
    return negx                                         ' out of range
  rh100 :=  (4 * raw) + (214748365 ** raw) -(1202591 ** (raw * raw)) - 400      ' linearize to unit of 1/100 %RH
  rh100 := (t100 - 2500)  ** (343597 * raw + 42949673) + rh100                  ' temperature compensate
  return (rH100+5)/10                                   ' round off to xx.x
                                                        ' Note that values still are possibly <0 or >100 at extremes

{computation logic:
  rhLinear = -4.0 + (0.0405 * raw) - (-2.8e-6 * raw * raw)   from data sheet
  rh100linear = -400 + (4 * raw) + (0.05 * raw) - (-2.8e-4 * raw * raw)   two fixed decimal places
      0.05*RH---> 214748365 ** raw              integer math redux
      2.8e-4 * raw * raw = 1202591 ** (raw * raw)

  rhTrue = (t - 25.0) * (0.01 + 0.00008 * rawRH) + rhLinear    from data sheet
  rh100true = (t100 - 2500) * (0.01 + 0.00008 * rawRH) + rh100    two fixed decimal places
      0.01 *2^32 =42949673                integer math redux
      (0.00008 * raw) * 2*32 = (0.00008 * 2^32) * raw  = 343597 * raw
}
PUB ReadStatus | ack
  ' read SHT-11 status  register
  ack := SendCommand(CMD_READSTATUS)                    ' read status
  return ReadByte(1)
  
PUB WriteStatus(n) | ack
  ' set SHT-11 status register
  ack := SendCommand(CMD_WRITESTATUS)                   ' write status
  mode := n & 1                                         ' bit zero of status, 0=hiRes 14 bit degC 12 bit RH, 1=loRes 12 bit degC 8 bit RH
  WriteByte(n & $47)                                    ' (mask out reserved bits)
  
PUB Reset | ack
  ' soft reset the SHT-11
  ack := SendCommand(CMD_RESET)                         ' write status
  waitcnt(cnt+clkfreq*15/1000)                          ' delay for 15 msec
  
PRI SendCommand(cmd)
  ' send transmission start sequence
  ' clock  
  ' data   
  dira[dpin]~                                           ' data high (pull-up)                                '
  outa[cpin]~                                           ' clock low                                   
  outa[cpin]~~                                          ' clock high                                 
  outa[dpin]~                                           ' data low
  dira[dpin]~~
  outa[cpin]~                                           ' clock low
  outa[cpin]~~                                          ' clock high
  dira[dpin]~                                           ' data high (pull-up)                                '
  outa[cpin]~                                           ' clock low

  return WriteByte(cmd)                                 ' send command and return ACK

PRI ReadWord                                            ' read 16-bit value
  return (ReadByte(0) << 8) + ReadByte(1)
  
PRI ReadByte(ack)                                       ' read 8-bit value
  ' data is valid before rising edge of clock
  ' clock   
  ' data   

  dira[dpin]~                                           ' data input
  repeat 8
    result := (result << 1) | ina[dpin]                 ' get next bit
    !outa[cpin]                                         ' send clock pulse 
    !outa[cpin]

  dira[dpin]~~                                          ' enable data output
  outa[dpin] := ack                                     ' write ACK bit
  !outa[cpin]                                           ' send clock pulse 
  !outa[cpin]
  dira[dpin]~                                           ' enable data input
  
PRI WriteByte(value)                                    ' write 8-bit value, return ACK
  ' data must be valid on rising edge of clock and while clock is high
  ' clock   
  ' data   

  dira[dpin]~~                                          ' enable data output   
  repeat 8
    outa[dpin] := value >> 7                            ' output next bit
    value := value << 1
    !outa[cpin]                                         ' send clock pulse
    !outa[cpin]

  dira[dpin]~                                           ' enable data input
  result := ina[dpin]                                   ' read ACK bit
  !outa[cpin]                                           ' send clock pulse 
  !outa[cpin]
  
PRI Wait : x | t                                        ' wait for data low (300 msec timeout)
  t := cnt                                              
  repeat
   x:=ina[dpin]
  until x==0 or (cnt - t) > clkfreq * 3 / 10

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
