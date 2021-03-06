{{
  TMP102 Temperature Sensor Driver
  Version 1.0       Kyle Crane (2011)

  - Access to Temperature in F and C
  - Access to Configuration Register
  - Access to THIGH and TLOW registers
  - All needed I2C communication
  - Supports low-power one-shot sampling
  
  - Does not support extended resolution mode
  - Does not presently handle negative temperatures, I have no way to test that right now

  Driver for Texas Instruments TMP102 I2C temperature sensor.  This driver runs in the
  same cog as the spin code that uses it. See datasheet for complete schematic. I2C
  interface is included in the driver.  Note A0 can be connected in any of 4 ways to
  allow up to 4 devices on the same I2C bus.  

                               +3.3V                     
     TMP102 SparkFun Mod.                             
        ┌──────────┐           ┣──┐
        │      VDD ├┐          │  │
        │          ├┘             4.7K
       ┌┤ALR   SCL ├┐ ────────┻──┼──────────────────< Prop Pin SCL
       └┤          ├┘             │
  ┌────┌┤A0    SDA ├┐ ───────────┻────────────────── Prop Pin SDA
  │    └┤          ├┘                      
  │     │      GND ├┐ 
       │          ├┘
 GND    └──────────┘

  With access to all the registers and functions the object is a little heavy-weight.  Stripping out what
  you do not need would allow for a trimmer footprint on a project.  I wanted to allow the widest possible
  use so leaned towards more access functions and convienince functions over keeping it light-weight.

  Please report any bugs to origin7511@yahoo.com

}}


CON
  CONF_REG_OS = %10000000_00000000    'One-shot conversion
  CONF_REG_RS = %01100000_00000000    'Converter Resolution
  CONF_REG_FQ = %00011000_00000000    'Fault Queue
  CONF_REG_PL = %00000100_00000000    'Alert Polarity
  CONF_REG_TM = %00000010_00000000    'Thermostat Mode
  CONF_REG_SD = %00000001_00000000    'Shutdown Mode
  CONF_REG_CR = %00000000_11000000    'Conversion Rate
  CONF_REG_AL = %00000000_00100000    'Alert Bit
  CONF_REG_EM = %00000000_00010000    'Extended Mode

  TEMP_REG_ADDR = $00
  CONF_REG_ADDR = $01
  TLOW_REG_ADDR = $02
  THGH_REG_ADDR = $03

  CONV_RATE_4S  = $00       
  CONV_RATE_1HZ = $01
  CONV_RATE_4HZ = $02
  CONV_RATE_8HZ = $03

  FAULT_REQ1    = $00
  FAULT_REQ2    = $01
  FAULT_REQ4    = $02
  FAULT_REQ6    = $03  

VAR
  long  started
  long  i2cAddr
  long  sclPin
  long  sdaPin
  long  tempRaw
  long  autoSample

PUB init(addr, cp, dp, as) | td
{{  Initialize the sensor and internal data.  Confirm that the sensor is attached and
    answering.

    addr -  I2C address of the sensor
    cp   -  SCL pin
    dp   -  SDA pin
    as   -  Autosample, if true any call to get temperature forces a sample, if false
            you must manually call SampleTemp to update the readings }}
  

  started := false
  i2cAddr := 0
  tempRaw := 4096     'This is an invalid temperature reading, should never occur in operation
  autoSample := false   
  
  if DevicePresent
    i2cAddr := addr
    sclPin := cp
    sdaPin := dp
    autoSample := as
    started := true
  else
    started := false

  return started
PUB GetDeviceAddress
{{ Returns the I2C address configured in the init statement }}

  return i2cAddr
    
PUB GetConfigRegister | msb, lsb
{{  Gets the current value of the config register as a full 16 bit value }}

  if !started                     ' If the object was not initalized then no I2C
    return                        ' activity is allowed
    
  return ReadRegister(CONF_REG_ADDR)

PUB SetConfigRegister(val) | msb, lsb
{{ Sets the control register directly to the value specified }}

  if !started                     ' If the object was not initalized then no I2C
    return                        ' activity is allowed

  WriteRegister(CONF_REG_ADDR, val)

PUB SetConversionFreq(val) | cnfVal
{{ Sets the conversion frequency to one of 4 (0-3) possible rates.
   0 -  0.25Hz
   1 -  1Hz
   2 -  4Hz
   3 -  8Hz }}
      
  cnfVal := GetConfigRegister

  if ((val => 0) AND (val =< 3))
    cnfVal &= !CONF_REG_CR
    val <<= 6
    cnfVal := cnfVal | val
    SetConfigRegister(cnfVal)
      
  return cnfVal 

PUB SetFaultQueue(val) | cnfVal
{{  Sets the number of consecutive faults required to trigger ALERT
    0 -   1
    1 -   2
    2 -   4
    3 -   6 }}

  cnfVal := GetConfigRegister

  if ((val =>0) AND (val =< 3))
    cnfVal &= !CONF_REG_FQ
    val <<= 11
    cnfVal := cnfVal | val
    SetConfigRegister(cnfVal)

  return cnfVal


PUB SetShutdownMode(val) | cnfVal
{{ Set the shutdown mode. All conversion circuits are disabled unless a one-shot
   conversion is requested
     0 - Continuous Conversion
    !0 - Shutdown Mode Active }}

  cnfVal := GetConfigRegister

  if val
    cnfVal &= !CONF_REG_SD            'Clear just this bit if it's set
    cnfVal := cnfVal | CONF_REG_SD    'Set this bit
  else
    cnfVal &= !CONF_REG_SD            'Clear just this bit

  SetConfigRegister(cnfVal)           'Write it to the config register
  
  return cnfVal   

PUB SetAlertHighC(temp) | tC, msb, lsb
{{  Writes a temperature to the THIGH register on the sensor.  Temp format
    must be formated as tenths of a degree.
    Example: 20.4 would be 204  }}

    tC := TempToCountC(temp)
    tC <<= 4    
    WriteRegister(THGH_REG_ADDR, tC)

    return tC


PUB SetAlertLowC(temp) | tC
{{  Writes a temperature to the TLOW register on the sensor.  Temp format
    must be formated as tenths of a degree.
    Example: 23.4 would be 234  }}

    tC := TempToCountC(temp)
    tC <<= 4
    WriteRegister(TLOW_REG_ADDR, tC)

    return tC


PUB GetAlertHighC | rVal
{{  Returns the temperature set in the THIGH register as degrees C. Temp
    is formated as the number of tenths of a degree.  234 = 23.4 }}
    
  rVal := ReadRegister(THGH_REG_ADDR)
  rVal >>= 4
  result := CountToTempC(rVal)
  

PUB GetAlertLowC | rVal
{{  Returns the temperature set in the TLOW register as degrees C. Temp
    is formatted as the number of tenths of a degree. 234 = 23.4 }}
    
  rVal := ReadRegister(TLOW_REG_ADDR)
  rVal >>= 4
  result := CountToTempC(rVal)
  

PUB GetAlertBit | alert
{{ Returns the state of the ALERT bit from the configuration register. The
   polarity of that bit depends on the setting for PL in the register. ALERT
   is read-only }}

  alert := GetConfigRegister
  alert &= CONF_REG_AL
  alert >>= 5

  return alert
  
PUB SetAlertPolBit(val) | cnfVal
{{  Sets the oneshot bit to 1 and returns }}

  cnfVal := GetConfigRegister

  if val
    cnfVal &= !CONF_REG_PL            'Clear just this bit if it's set
    cnfVal := cnfVal | CONF_REG_PL    'Set this bit
  else
    cnfVal &= !CONF_REG_PL            'Clear just this bit

  SetConfigRegister(cnfVal)           'Write it to the config register
  
  return cnfVal 
                
PUB DoOneShot | cnfVal, tMS, Td
{{  Performs a one-shot conversion.  This fuction blocks for approx 26ms to allow
    time for the conversion to take place.  If that is not compatible with timing
    requirements then you will need to manually set the OS bit and check it later
    for to see if  }}

  cnfVal := GetConfigRegister
  cnfVal := cnfVal | CONF_REG_OS      'Set the bit no matter what

  SetConfigRegister(cnfVal)           'Write out the one-shot request 

  tMS := clkfreq / 1000
  tD  := tMS * 26
  waitcnt(td + cnt)                   'Wait for conversion to complete    

  SampleTemp                          'Sample the new temp

  return cnfVal

  
PUB SetOneShotBit | cnfVal
{{  Sets the oneshot bit to 1 and returns }}

  cnfVal := GetConfigRegister
  cnfVal := cnfVal | CONF_REG_OS      'Set the bit to 1
  SetConfigRegister(cnfVal)

  return cnfVal 

PUB GetOneShotBit | cnfVal
{{ Get the status of the One-Shot bit and return it }}

  cnfVal := getConfigRegister
  cnfVal >>= 15
  return cnfVal
    
PUB SetThermostatMode (val) | cnfVal
{{  Set the function of the ALERT pin to either comparator or interrupt mode. See
    data sheet for details
    0   -   Comparator Mode
   !0   -   Interrupt Mode }}
   
  cnfVal := GetConfigRegister

  if val
    cnfVal |= CONF_REG_TM             'Set the bit
  else
    cnfVal &= !CONF_REG_TM            'Clear the bit

  SetConfigRegister(cnfVal)

  return cnfVal

    
PUB GetTempRaw
  {{  Returns the basic temperature count from the device
      Return value is the *count* of 0.0625 celcius units the device
      is sensing. }}
      
  if autoSample
    SampleTemp

  return tempRaw

  
PUB GetTempC | calcTemp, rounding, returnTemp
  {{  Returns the temperature in (rounded) 0.1 degree C units
      Example: 254 is 25.4 degrees rounded to the nearest tenth }} 
  
  if autoSample
    SampleTemp

  return CountToTempC(tempRaw)

  
PUB GetTempF | calcTemp, rounding, returnTemp
  {{ Returns the temperature in (rounded) 0.1 degree F units
     Example: 704 is 70.4 degrees rounded to the nearest tenth }}

  if autoSample
    SampleTemp

  return CountToTempF(tempRaw)


PUB GetTempWholeC
  {{ Gets the whole number portion of the temperature in degrees C - Does not round }}

  return getTempC / 10


PUB GetTempWholeF
  {{ Gets the whole number portion of the temperature in degrees F - Does not round }}

  return getTempF / 10


PUB GetTempFracC
  {{ Gets the decimal number portion of the temperature in degrees C }}
  
  return getTempC // 10


PUB GetTempFracF
  {{ Gets the decimal number portion of the temperature in degrees C }}
  
  return getTempF // 10


PUB DevicePresent
  {{  Writes the address to the I2C bus and returns the ACK
      responce seen.  false - No ACK, true - ACK }}

  StartDataTransfer
  result := TransmitPacket(i2cAddr<<1)
  StopDataTransfer
  

PUB SampleTemp | msb, lsb, inbuff, delay, tD, tMS
  {{  Sample the temperature over the I2C bus and store the result into the
      the rawTemp variable.  Also returns the most recent reading as raw output
      from the sensor. }}
      
  'tD := (clkfreq / 1_000)*26
  'waitcnt(tD + cnt)    

  if !started                     ' If the object was not initalized then no I2C
    return                        ' activity is allowed
     
  startDataTransfer
  transmitPacket(i2cAddr<<1)      ' Say hello
  transmitPacket(0)               ' Point register to the temperature register
  stopDataTransfer

  startDataTransfer
  transmitPacket((i2cAddr<<1)| 1) ' Say hello and request a read operation
  msb := receivePacket(true)      ' Read the MSB portion
  lsb := receivePacket(false)     ' Read the LSB portion
  stopDataTransfer
  
  msb <<= 4                       ' Assemble the shifted MSB and LSB
  lsb >>= 4
  tempRaw := msb | lsb            ' Update the stored temperature to the most
                                  ' recent reading.

PRI TempToCountC (tempC) | rounding
' Converts a C temperature from number of tenths to the binary format of the
' device.

  tempC *= 10000
  tempC /= 625
  rounding := tempC // 10
  tempC /= 10

  if rounding => 5
    tempC++

  return tempC

PRI TempToCountF (tempF) | rounding
   

PRI CountToTempC (countC) | calcTemp, rounding, finalTemp
  'Returns the temperature in (rounded) 0.1 degree C units
  'Example: 204 is 20.4 degrees rounded to the nearest tenth

  'Avoid floating point math 
  calcTemp  := countC
  calcTemp  *= 625

  'Round to the tenth place 
  rounding    := calcTemp // 1000
  finalTemp  := calcTemp / 1000
  if rounding >= 500
    finalTemp++

  return finalTemp

PRI CountToTempF (countF) | calcTemp, rounding, finalTemp
  'Returns the temperature in (rounded) 0.1 degree F units
  'Example: 704 is 70.4 degrees rounded to the nearest tenth

  'Avoid floating point math
  calcTemp  := countF      
  calcTemp  *= 625

  'Convert from C to F
  calcTemp  := (calcTemp*9/5)+320000

  'Round to the tenth place
  rounding    := calcTemp // 1000
  finalTemp   := calcTemp / 1000
  if rounding >= 500
    finalTemp++

  return finalTemp

PRI WriteRegister(pnt, val)| msb, lsb
' Write data to the requested register on the sensor

  if !started
    return

  lsb := val & %00000000_11111111
  msb := val & %11111111_00000000
  msb >>= 8
  
  startDataTransfer
  transmitPacket(i2cAddr<<1)      ' Say hello
  transmitPacket(pnt)             ' Point register to the requested register
  transmitPacket(msb)             ' ....and send the data
  transmitPacket(lsb)
  stopDataTransfer

PRI ReadRegister(pnt) | msb, lsb
' Read data from the requested register on the sensor

  if !started
    return

  startDataTransfer
  transmitPacket(i2cAddr<<1)      ' Say hello
  transmitPacket(pnt)             ' Point register to the requested register
  stopDataTransfer

  startDataTransfer
  transmitPacket((i2cAddr<<1)| 1) ' Say hello and request a read operation
  msb := receivePacket(true)      ' Read the MSB portion
  lsb := receivePacket(false)     ' Read the LSB portion
  stopDataTransfer

  msb <<= 8                       ' Assemble the data  
  return msb | lsb
  
PRI TransmitPacket(value)
' Low level write of one byte to the I2C bus.

  value := ((!value) >< 8)  'Invert and reverse the data for transmission

  repeat 8
    dira[sdaPin] := value   ' Write a bit to the data line
    dira[sclPin] := false   ' Clock it out
    dira[sclPin] := true    ' Release the clock
    value >>= 1             ' Shift out the last bit off the edge
         
  dira[sdaPin] := false     
  dira[sclPin] := false
  result := not(ina[sdaPin])
  dira[sclPin] := true 
  dira[sdaPin] := true    

PRI ReceivePacket(aknowledge)
' Do a low level read of I2C data.

  dira[sdaPin] := false

  repeat 8
    result <<= 1              'Shift the data over one 
    dira[sclPin] := false     'Clock the line
    result |= ina[sdaPin]     'Read the data bit
    dira[sclPin] := true      'Release the clock
   
  dira[sdaPin] := aknowledge  'Send ACK if requested 
  dira[sclPin] := false       'One more clock 
  dira[sclPin] := true        'Release the clock
  dira[sdaPin] := true        'Release the data line

PRI StartDataTransfer
' Produce an I2C start condition
'SCL  
'SDA  

  dira[sdaPin] := true
  dira[sclPin] := true     

PRI StopDataTransfer
' Produce an I2C stop condition 
'SCL  
'SDA  

  dira[sclPin] := false 
  dira[sdaPin] := false
      

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

}}           