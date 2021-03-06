{{
┌───────────────────────────────┬───────────────────┬────────────────────┐
│      GPS_Float.spin v1.0      │ Author: I.Kövesdi │ Rel.: 24. jan 2009 │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │ 
│  The 'GPS_Float' driver object bridges a SPIN program to the strings   │
│ and longs provided by the basic "GPS_Str_NMEA" driver and translates   │
│ them into descriptive status strings, long and float values and checks │
│ errors wherever appropriate. This driver contains basic algorithms for │
│ calculations in navigation. By using these procedures you can make your│
│ Propeller/GPS combination to be much more useful than just a part of   │
│ the onboard entertainment system of your car, ship or plane.           │
│  Given two locations, where one of them can be a measured position and │
│ the second one a destination, the driver calculates the distance and   │
│ the initial (actual) bearing for the shortest, so called Great-Circle  │
│ route to the second position. Alternatively, it can calculate the      │
│ constant bearing and the somewhat longer distance on that path to reach│
│ the same destination. This second type of navigation, where it is      │
│ easier to steer due to the constant bearing, is known as Rhumb-Line    │
│ navigation. Great-Circle courses where the bearing of the destination  │
│ is changing continuously during travel, are only jokes for a helmsman, │
│ but are quite appropriate for a computerized autopilot. In Rhumb-line  │
│ navigation the driver helps Dead-Reckoning by calculating the          │
│ destination from the known length and course of a leg.                 │                     
│  The driver contains procedures to check the proximity of a third      │
│ location while en-route from a first to a second point. For Great-     │
│ Circle routes it can calculate the Cross-Track distance of a given     │
│ off-track location and the Along-Track distance, which is the distance │
│ from the current position to the closest point on the path to that     │
│ third location. For Rhumb-Line navigation the driver calculates        │
│ Closest Point of Approach (CPA) related quantities, such as Time for   │
│ CPA (TCPA) and distance from object at CPA (DCPA), where the object is │
│ given by its Latitude, Longitude (and by its constant course and speed,│
│ if known) and we are cruising on a measured stable course with measured│
│ constant speed.                                                        │  
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│   Using 32 bit floats gives you simpler and easier to debug programming│
│ of computation intensive tasks and much higher dynamic range (>10^60)  │
│ when compared with 32 bit integer calculations. However, you have to   │
│ pay for these advantages with much longer execution times and with more│
│ COGs to use. Even the precision digit count of IEEE-754 floats (>7, <8)│
│ can be easily beaten with a carefully designed 32 bit integer math. In │
│ spite of all these good features of integer arithmetic, when ease of   │
│ program maintenance, expandability and adherence to a well proven      │
│ industry standard are factors in your decision, then you may use this  │
│ 'float' driver successfully in GPS data processing.                    │
│  However, if you want to be very fast, or smart, you can use clever and│
│ efficient integer arithmetic. Even then you also can use the lower     │
│ level 'GPS_Str_NMEA' or 'GPS_Str_NMEA_Lite' drivers as  stable and     │
│ robust data providers for your integer algorithms.                     │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  This driver has the "GPS_Float_Lite.spin v1.0" Driver as its smaller  │
│ and faster sibling but with less features. The Lite version keeps the  │
│ robustness of the full version, though.                                │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘


}}


CON

_CLKMODE         = XTAL1 + PLL16x
_XINFREQ         = 5_000_000


        
_RX_FM_GPS        = 7
_TX_TO_GPS        = 8

_GPS_SER_MODE     = %0000    '(Usual) serial comm mode with a GPS
'                    
'                    │││└─────Mode bit 0 = invert rx
'                    ││└──────Mode bit 1 = invert tx
'                    │└───────Mode bit 2 = open-drain/source tx
'                    └────────Mode bit 3 = ignore tx, echo on rx

 
_GPS_SER_BAUD     = 4_800    '(Usual) serial Baud rate with a GPS
                             'Cross-check this value with the actual
                             'setting of your GPS. If the unit supports
                             'higher baud rate switch to it!

'_GPS_SER_MODE     = %0001    'Serial comm mode with a Magellan 330 GPS                            
                             'One of the 3 different brand and type of GPS
                             'Talker used during testing and debugging


'_GPS_SER_BAUD     = 19_200   'GPS_NMEA.spin Driver were succesfully
'_GPS_SER_BAUD     = 38_400   'tested at these baud rates, as well
'_GPS_SER_BAUD     = 57_600
'_GPS_SER_BAUD     = 115_200

'RS-232 connection to GPS
'========================
'When you connect a GPS to the Propeller (or to a computer), you need to
'know something about the RS-232 serial ports since they are often used
'in GPS units or with active GPS antennas. GPSs usually have DBF-9 male 
'serial connectors configured as a DCE (see later). Active GPS antennas 
'can have special micro connectors or serial cables equipped with, for
'example, PS-2 male connector.
'Connection pinouts of DBF-9:
'----------------------------
'The RS-232 standard defines two classes of devices that may talk using
'RS-232 serial data - Data Terminal Equipment (DTE), and Data
'Communication Equipment (DCE). Computers and terminals are considered
'DTE, while peripherals, such as a GPS unit, are DCE. DTEs (PCs) transmit
'via Pin 3 and receive via Pin 2. DCEs (e.g. GPSs) transmit via Pin 2 and
'receive via Pin 3. So the standard defines pinouts for DTE and DCE such
'that a "straight through" cable (pin 2 to pin 2, 3 to 3, etc) can be used
'between a DTE and DCE. To connect two DTEs or two DCEs together, you need
'a "null modem" cable, that swaps pins between the two ends (e.g. pin 2 to
'3, 3 to 2). Unfortunately, there is sometimes disagreement whether a
'certain device is DTE or DCE. Consult carefully the description and data
'sheet of the GPS or use an oscilloscope to check pinout of the device to
'identify its Tx pin, voltage levels and baud rate.
'Voltages:
'---------
'RS-232 is single-ended, which means that the transmit and receive lines
'are referenced to a common ground. A typical RS-232 signal swings
'positive and negative. Standard RS-232 voltages, the MARK(1) and SPACE(0)
'signals on the line, are somewhere in the range -3 ...-15V and +3...+15V,
'respectively. So you may effectively kill your Prop or FPU if you just
'simply connect a Tx line directly to the pins. Many GPS devices, however,
'transmit and receive using only -5V/5V MARK(1)/SPACE(0) levels or just
'5V/0V TTL signal levels. Check this with a scope or read manual. The
'connection of the TTL level lines of a 5V/0V device is straightforward.
'You only need to use a 1-2K series resistor between the Tx line of the GPS
'and of the Rx Pin of the Prop. The TTL Rx line of the GPS can nicely
'accept the >3V output high level of the Prop directly. For standard RS-232
'connection use one of the MAX232(3) family of level converter chips.   
'Polarity:
'---------
'Standard RS-232 signals are inverted with respect to the TTL convention
'where 0V = Low and 5V = High. In RS232, for example,  -10V means High and
'+10V means Low. Fortunately, the RS-232 line drivers take us the favor
'and invert those signals. However, when you talk or listen through a
'custom made or home built level converter, you should be aware of this
'polarity inversion.
'Cable length and transmission speed:
'------------------------------------
'The standards for RS-232 and similar interfaces usually  restrict RS-232
'to 20K baud or less and line lengths of 15 m (50 ft) or less. These
'restrictions are mostly throwbacks to the days when 20K baud was             
'considered a very high line speed, and cables were thick, with high
'capacitance. However, in practice, RS-232 is far more robust than the 
'traditional specified limits of 20K baud over a 15 m line would imply.
'RS-232 is perfectly adequate at speeds up to 200K baud, if the cable is 
'well screened and grounded. The 15 m limitation for cable length can be
'stretched to about 100 m if the cable is low capacitance as well.
'Networking:
'-----------
'RS-232 is not Multi-drop. You can only connect one RS-232 device per 
'port. There are some devices designed to echo a command to a second unit
'of the same family of products, but this is very rare. This means that if
'you have 3 DCE peripherals to connect to a PC, which is a DTE as we know,
'you will need 3 ports on the PC.


'Units
_RAD             = 0       
_DEG             = 1
_KM              = 2
_MI              = 3
_NM              = 4
_M               = 5
_MPS             = 6
_KPH             = 7
_KNOT            = 8
_MPH             = 9 
_MIN             = 10
_HOUR            = 11

'Mean radius of Earth
_R_KM            =  6_371.01     '[km]
_R_NM            =  3_440.07     '[nmi]
_R_MI            =  3_958.76     '[mi]

'Geometry
_PI_4            = 0.78539816    'PI/4

        
VAR 

  
OBJ

NMEA              : "GPS_Str_NMEA"
  
F                 : "Float32Full"


PUB Init : oKay | oK1, oK2 
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Init │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
''     Action: -Starts those drivers that will launch a COG directly or
''              implicitly
''             -Checks for a succesfull start
'' Parameters: None                                 
''    Results: TRUE if start is succesfull, else FALSE                     
''+Reads/Uses: NMEA serial interface hardware and software parameters:
''             _RX_FM_GPS,
''             _TX_TO_GPS,
''             _GPS_SER_MODE,
''             _GPS_SER_BAUD                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA-------->NMEA.Start (uses 2 COGs + COG0)
''             Float32Full--------->F.Start    (uses 2 COGs + COG0)                           
'-------------------------------------------------------------------------

'Start 'GPS_Str_NMEA' Driver object. This Driver will launch 2 COGs
oK1 := NMEA.StartCOGs(_RX_FM_GPS,_TX_TO_GPS,_GPS_SER_MODE,_GPS_SER_BAUD)

'Start 'Float32Full' object. It will launch 2 COGs
oK2 := F.Start

oKay := oK1 AND oK2

IF NOT oKay
  IF oK1
    NMEA.StopCOGs
  IF oK2
    F.Stop

RETURN oKay


PUB Stop
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Stop │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Stops drivers that use separate COG
'' Parameters: None                                 
''    Results: None                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA---------------->NMEA.StopCOGs
''             Float32Full----------------->F.Stop                             
'-------------------------------------------------------------------------

NMEA.StopCOGs
F.Stop
'-------------------------------------------------------------------------


PUB Communication : oKay
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ Communication │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Checks active communication with GPS
'' Parameters: None                                 
''    Results: TRUE if NMEA sentences arrived, FALSE otherwise                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA---------------->NMEA.Counters                            
'-------------------------------------------------------------------------

IF NMEA.Long_NMEA_Counters(0)
  oKay := TRUE
ELSE
  oKay := FALSE

 RETURN oKay 
'-------------------------------------------------------------------------

PUB Reset_NMEA_Parser
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Reset_NMEA_Parser │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Resets NMEA parser
'' Parameters: None                                 
''    Results: None                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: NMEA.Reset                            
'-------------------------------------------------------------------------

NMEA.Reset
'-------------------------------------------------------------------------
  

PUB Long_NMEA_Counters(index)
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ Long_NMEA_Counters │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Reads various counters of the NMEA receiver object                                 
'' Parameters: Index: 0 - query No. of started NMEA sentences
''                    1 - query No. of checksum verified sentences
''                    2 - query No. of checksum failed sentences
''                    3 - query No. of decoded RMC sentences
''                    4 - query No. of decoded GGA sentences
''                    5 - query No. of decoded GLL sentences 
''                    6 - query No. of decoded GSV sentences 
''                    7 - query No. of decoded GSA sentences 
''                    8 - query last calculated checksum
''                    9 - query last received checksum
''    Results: Corresponding long value                                            
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Long_NMEA_Counters                       
'-------------------------------------------------------------------------

RETURN NMEA.Long_NMEA_Counters(index)
'-------------------------------------------------------------------------


PUB Str_Last_Decoded_Type(index)
'-------------------------------------------------------------------------
'--------------------------┌───────────────────────┐----------------------
'--------------------------│ Str_Last_Decoded_Type │----------------------
'--------------------------└───────────────────────┘----------------------
'-------------------------------------------------------------------------
''     Action: Returns last decoded/not recognised NMEA sentence type                                 
'' Parameters: index: 0 - query last decoded sentence
''                    1 - query last not recogniyed sentence                                  
''    Results: Pointer to the corresponding string                                                               
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Last_Decoded_Type
''       Note: Last not recognized sentence is reset to a null string
''             after each recognized one                                                               
'-------------------------------------------------------------------------

RETURN NMEA.Str_Last_Decoded_Type(index)
'-------------------------------------------------------------------------


PUB Str_Data_Strings
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ Str_Data_Strings │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Returns NMEA data strings from last received sentence                                   
'' Parameters: None                                 
''    Results: Pointer to a string buffer                                                               
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Data_Strings
''       Note: You can not print this buffer directly since it contains
''             many zero terminated strings. A standard Str procedure will
''             print only the first of them (e.g. GPRMC only). See a print
''             method in the Demo application that prints the whole buffer                                                               
'-------------------------------------------------------------------------

RETURN NMEA.Str_Data_Strings
'-------------------------------------------------------------------------


PUB Long_Data_Status : longVal | p, c
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Long_Data_Status │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Reads GPS data status                                 
'' Parameters: None                                 
''    Results: Codes for GPS data status:  1 for GPS data  not valid
''                                         2 for GPS data valid
''                                        -1 for status not available                                                            
''+Reads/Uses: None                                              
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_GPS_Status                                                                  
'-------------------------------------------------------------------------

p := NMEA.Str_GPS_Status
c := BYTE[p]
CASE c
  "V":RETURN 1
  "A":RETURN 2
  OTHER:RETURN -1
'-------------------------------------------------------------------------


PUB Str_Data_Status : strPtr | p, c
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Str_Data_Status │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Reads GPS data status string                                
'' Parameters: None                                 
''    Results: String for GPS data status: 'V' for GPS data not valid(Void)
''                                         'A" for GPS data valid(Autonom.) 
''                                       OTHER for status not available                                                            
''+Reads/Uses: None                                              
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_GPS_Status                                                               
'-------------------------------------------------------------------------

p := NMEA.Str_GPS_Status
c := BYTE[p]
CASE c
  "V":RETURN @strDataInvalid
  "A":RETURN @strDataValid
  OTHER:RETURN @strNotAvail
'-------------------------------------------------------------------------      


PUB Long_GPS_Mode | p, c
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Long_GPS_Mode │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns a long code for GPS working mode                                 
'' Parameters: None                                 
''    Results: 1 for 'A' = Autonomous
''             2 for 'D' = Differential GPS 
''             3 for 'E' = Estimated, (Dead Reckoning mode) 
''             4 for 'M' = Manual Input mode
''             5 for 'S' = Simulator mode 
''             6 for 'N' = Data not valid                                                              
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_GPS_Mode                                                                  
'-------------------------------------------------------------------------

p := NMEA.Str_GPS_Mode
IF STRSIZE(p)
  c := BYTE[p]
  CASE c
    "A":RETURN 1
    "D":RETURN 2
    "E":RETURN 3
    "M":RETURN 4
    "S":RETURN 5
    "N":RETURN 6
    OTHER:RETURN 0      
ELSE
  RETURN -1
'-------------------------------------------------------------------------

    
PUB Str_GPS_Mode : strPtr | p, c
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Str_GPS_Mode │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns a descriptive string of GPS mode                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                  
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_GPS_Mode                                                             
'-------------------------------------------------------------------------

p := NMEA.Str_GPS_Mode
IF STRSIZE(p)
  c := BYTE[p]
  CASE c
    "A":RETURN @strAutonomous
    "D":RETURN @strDGPS
    "E":RETURN @strDeadReckon
    "M":RETURN @strManual
    "S":RETURN @strSimulator
    "N":RETURN @strNoFix
    OTHER:RETURN @strDataInvalid
ELSE
  RETURN @strNotAvail
'-------------------------------------------------------------------------

  
PUB Long_Fix_Quality | p, c
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ Long_Fix_Quality │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns a long code of GPS Fix quality                                 
'' Parameters: None                                 
''    Results: GPS Fix quality (See DAT section of GPS_Str_NMEA driver)                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Fix_Quality                                                                 
'-------------------------------------------------------------------------

p := NMEA.Str_Fix_Quality
IF STRSIZE(p)
  c := BYTE[p]
  RESULT := c - $30
ELSE
  RESULT  := -1
'-------------------------------------------------------------------------


PUB Str_Fix_Quality : strPtr | p, c
'-------------------------------------------------------------------------
'-----------------------------┌─────────────────┐-------------------------
'-----------------------------│ Str_Fix_Quality │-------------------------
'-----------------------------└─────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns a descriptive string about the GPS fix quality                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Fix_Quality                                                             
'-------------------------------------------------------------------------

p := NMEA.Str_Fix_Quality
IF STRSIZE(p)
  c := BYTE[p]
  CASE c
    "0":RETURN @strNoFix
    "1":RETURN @strGPS_SPS
    "2":RETURN @strDGPS_SPS
    "3":RETURN @strGPS_PPS
    "4":RETURN @strInt_RTK
    "5":RETURN @strFloat_RTK
    "6":RETURN @strDR_FV
    "7":RETURN @strMan_NF
    "8":RETURN @strSim_NF
    OTHER:RETURN @strDataInvalid
ELSE
  RETURN @strNotAvail
'-------------------------------------------------------------------------
  

PUB Long_Pos_Mode_Selection | p, c
'-------------------------------------------------------------------------
'------------------------┌─────────────────────────┐----------------------
'------------------------│ Long_Pos_Mode_Selection │----------------------
'------------------------└─────────────────────────┘----------------------
'-------------------------------------------------------------------------
''     Action: It returns long code for positioning mode selection                                 
'' Parameters: None                                 
''    Results: 1 for manual selection mode
''             2 for automatic selection mode
''             0 for data not available                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Pos_Mode_Selection                                                               
'-------------------------------------------------------------------------

p := NMEA.Str_Pos_Mode_Selection
c := BYTE[p]
CASE c
  "M":RETURN  1
  "A":RETURN  2
  OTHER:RETURN 0
'-------------------------------------------------------------------------
  
  
PUB Str_Pos_Mode_Selection : strPtr | p, c
'-------------------------------------------------------------------------
'-----------------------┌────────────────────────┐------------------------
'-----------------------│ Str_Pos_Mode_Selection │------------------------
'-----------------------└────────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: It returns a descriptive string for pos. mode selection                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Pos_Mode_Selection                                                                
'-------------------------------------------------------------------------

p := NMEA.Str_Pos_Mode_Selection
c := BYTE[p]
CASE c
  "M":RETURN @strMan2D3D
  "A":RETURN @strAuto2D3D
  OTHER:RETURN @strNotAvail
'-------------------------------------------------------------------------

  
PUB Long_Actual_Pos_Mode | p, c
'-------------------------------------------------------------------------
'-------------------------┌──────────────────────┐------------------------
'-------------------------│ Long_Actual_Pos_Mode │------------------------
'-------------------------└──────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: It returns long code for the actual positioning mode                                 
'' Parameters: None                                 
''    Results: 1 = Fix not available
''             2 = 2D (<4 Sats used) 
''             3 = 3D (>3 Sats used)                                                               
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.NMEA.Str_Actual_Pos_Mode                                                             
'-------------------------------------------------------------------------

p := NMEA.Str_Actual_Pos_Mode
c := BYTE[p]
RESULT := c - $30
'-------------------------------------------------------------------------


PUB Str_Actual_Pos_Mode : strPtr | p, c
'-------------------------------------------------------------------------
'--------------------------┌─────────────────────┐------------------------
'--------------------------│ Str_Actual_Pos_Mode │------------------------
'--------------------------└─────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: It returns a descriptive string for actual pos. mode                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Actual_Pos_Mode                                                                    
'-------------------------------------------------------------------------

p := NMEA.Str_Actual_Pos_Mode
IF STRSIZE(p)
  c := BYTE[p]
  CASE c
    "1":RETURN @strNoFix 
    "2":RETURN @str2D
    "3":RETURN @str3D
    "X":RETURN @strNotAvail
    OTHER:RETURN @strDataInvalid   
ELSE
  RETURN @strNotAvail
'-------------------------------------------------------------------------
  

PUB Long_SatID_In_Fix(index) | i
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Long_SatID_In_Fix │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: It returns the satellite IDs used in Fix                                
'' Parameters: Index                                      
''    Results: No. of satellites used in fix (index = 0)
''             ID (PRN) of satellite(index)                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Sat_ID_In_Fix
''       Note: Index zero gives back the number of satellites in Fix
'-------------------------------------------------------------------------

CASE index
  0:
    i := S2L(NMEA.Str_Sat_ID_In_Fix(0) )
    IF i > 0 AND i < 13
      RETURN i
    ELSE
      RETURN 0  
  1..12:RETURN S2L(NMEA.Str_Sat_ID_In_Fix(index))
  OTHER:RETURN 0
'-------------------------------------------------------------------------

  
PUB Long_SatID_In_View(index) | i
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ Long_SatID_In_View │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: It returns the satellite IDs in view of the GPS receiver                
'' Parameters: Index                                      
''    Results: No. of satellites used in view (index = 0)
''             ID (PRN) of satellite(index)                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Sat_ID_In_View
''       Note: Index zero gives back the number of satellites in View                
'-------------------------------------------------------------------------

CASE index
  0:
    i := S2L(NMEA.Str_Sat_ID_In_View(0))
    IF i > 0 AND i < 13
      RETURN i
    ELSE
      RETURN 0  
  1..12:RETURN S2L(NMEA.Str_Sat_ID_In_View(index))
  OTHER:RETURN 0
'-------------------------------------------------------------------------  
 

PUB Long_Sat_Elevation(index)
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ Long_Sat_Elevation │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: It returns the elevation of a satellite in View                         
'' Parameters: Index                                      
''    Results: Elevation of satellite(index) in View                                                                                                  
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Sat_Elevation                                                                                     
'-------------------------------------------------------------------------

CASE index
  1..12:RETURN S2L(NMEA.Str_Sat_Elevation(index))
  OTHER:RETURN 0
'-------------------------------------------------------------------------  

    
PUB Long_Sat_Azimuth(index)
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Long_Sat_Azimuth │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: It returns the azimuth of a satellite in View                           
'' Parameters: Index                                      
''    Results: Azimuth of satellite(index) in View                                                                                                    
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Sat_Azimuth
'-------------------------------------------------------------------------

CASE index
  1..12:RETURN S2L(NMEA.Str_Sat_Azimuth(index))
  OTHER:RETURN 0
'-------------------------------------------------------------------------


PUB Long_Sat_SNR(index) | s
'-------------------------------------------------------------------------
'-------------------------------┌──────────────┐--------------------------
'-------------------------------│ Long_Sat_SNR │--------------------------
'-------------------------------└──────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: It returns the S/N ofsignal of a satellite in View                      
'' Parameters: Index                                      
''    Results: S/N of signal of satellite(index) in View                                                                                              
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Sat_SNR                            
'-------------------------------------------------------------------------

CASE index
  1..12:s := S2L(NMEA.Str_Sat_SNR(index))
  OTHER:s := -1
IF s == floatNaN
  s := -1
RETURN s  
'-------------------------------------------------------------------------

  
PUB Str_DOP(index) | p
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ Str_DOP │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: It returns DOP data                  
'' Parameters: index                                
''    Results: 0 - PDOP
''             1 - HDOP
''             2 - VDOP              
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_DOP                                
'-------------------------------------------------------------------------

p := NMEA.Str_DOP(index)
IF STRSIZE(p)
  RETURN p
ELSE
  RETURN STRING("--.-")
'-------------------------------------------------------------------------


PUB Long_Year | p, y
'-------------------------------------------------------------------------
'---------------------------------┌───────────┐---------------------------
'---------------------------------│ Long_Year │---------------------------
'---------------------------------└───────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC year                  
'' Parameters: None                                 
''    Results: UTC year as long, for example 2009                                  
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Date                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Date

CASE y := 10 * BYTE[p + 4] + BYTE[p + 5] + $5C0
  2008..2020:
  OTHER: y := -1
  
RETURN y  
'-------------------------------------------------------------------------


PUB Long_Month | p, m
'-------------------------------------------------------------------------
'--------------------------------┌────────────┐---------------------------
'--------------------------------│ Long_Month │---------------------------
'--------------------------------└────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC month                 
'' Parameters: None                                 
''    Results: UTC month as long, for example 2 for February                       
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Date                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Date

CASE m := 10 * BYTE[p + 2] + BYTE[p + 3] - $210 
  1..12:
  OTHER: m := -1

RETURN m
'-------------------------------------------------------------------------
  

PUB Long_Day | p, d            
'-------------------------------------------------------------------------
'---------------------------------┌──────────┐----------------------------
'---------------------------------│ Long_Day │----------------------------
'---------------------------------└──────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC day                   
'' Parameters: None                                 
''    Results: UTC day as long                                                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Date                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Date 

CASE d :=  10 * BYTE[p] + BYTE[p + 1] - $210
  1..31:
  OTHER: d := -1

RETURN d
'-------------------------------------------------------------------------


PUB Long_Hour | p, h
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ Long_Hour │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC hour                  
'' Parameters: None                                 
''    Results: UTC hour as long
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Time                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Time

CASE h := 10 * BYTE[p] + BYTE[p + 1] - $210
  0..24:
  OTHER: h := -1

RETURN h  
'-------------------------------------------------------------------------


PUB Long_Minute | p, m
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Long_Minute │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC minute                
'' Parameters: None                                 
''    Results: UTC minute as long
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Time                           
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Time

CASE m := 10 * BYTE[p + 2] + BYTE[p + 3] - $210
  0..59:
  OTHER: m := -1

RETURN m
'-------------------------------------------------------------------------


PUB Long_Second | p, s
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Long_Second │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC second                
'' Parameters: None                                 
''    Results: UTC second as long
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_UTC_Time
''       Note: Fractions of seconds are ingnored
'-------------------------------------------------------------------------

p := NMEA.Str_UTC_Time
CASE s := 10 * BYTE[p + 4] + BYTE[p + 5] - $210
  0..59:
  OTHER: s := -1

RETURN s  
'-------------------------------------------------------------------------
  

PUB Float_Latitude_Deg : floatVal | p, d, m, mf, fd
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Float_Latitude_Deg │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns Latitude in decimal degrees
'' Parameters: None                                 
''    Results: Latitude in signed float as decimal degrees
''+Reads/Uses: floatNaN                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA-------------->NMEA.Str_Latitude
''                                        NMEA.Str_Lat_N_S 
''             Float32Full--------------->F.FFloat
''                                        F.FAdd
''                                        F.FDiv
'-------------------------------------------------------------------------

p := NMEA.Str_Latitude

'Check for not "D", I.e. data received
IF BYTE[p] == "D"
  RETURN floatNaN
'Cross check decimal point to be sure
IF BYTE[p + 4] <> "."
  RETURN floatNaN
  
d := 10 * BYTE[p] + BYTE[p + 1] - $210
m := 10 * BYTE[p + 2] + BYTE[p + 3] - $210

CASE STRSIZE(p)
  8:
    mf := 10*(10*BYTE[p+5]+BYTE[p+6])+BYTE[p+7]-$14D0
    fd := 1000.0 
  9:
    mf := 10*(10*(10*BYTE[p+5]+BYTE[p+6])+BYTE[p+7])+BYTE[p+8]-$D050
    fd := 10_000.0
    
m := F.FAdd(F.FFloat(m),F.FDiv(F.FFloat(mf),fd))
d := F.Fadd(F.FFloat(d),F.FDiv(m,60.0))

'Check N S hemispheres
p := NMEA.Str_Lat_N_S
IF BYTE[p] == "S"
  d ^= $8000_0000           'Negate it

RETURN d
'-------------------------------------------------------------------------


PUB Float_Longitude_Deg : floatVal | p, d, m, mf, fd
'-------------------------------------------------------------------------
'------------------------┌─────────────────────┐--------------------------
'------------------------│ Float_Longitude_Deg │--------------------------
'------------------------└─────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: It returns Longitude in decimal degrees
'' Parameters: None                                 
''    Results: Longitude in signed float as decimal degrees
''+Reads/Uses: floatNaN                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA-------------->NMEA.Str_Longitude
''                                        NMEA.Str_Lon_E_W
''             Float32Full--------------->F.FFloat
''                                        F.FAdd
''                                        F.FDiv                  
'-------------------------------------------------------------------------

p := NMEA.Str_Longitude

'Check for not "D", I.e. data received
IF BYTE[p] == "D"
  RETURN floatNaN
'Cross check decimal point to be sure
IF BYTE[p + 5] <> "."
  RETURN floatNaN
  
d := 10 * ( 10 * BYTE[p] + BYTE[p + 1]) + BYTE[p + 2] - $14D0
m := 10 * BYTE[p + 3] + BYTE[p + 4] - $210
 
CASE STRSIZE(p)
  9:
    mf := 10*(10*BYTE[p+6]+BYTE[p+7])+BYTE[p+8]-$14D0
    fd := 1000.0 
  10:
    mf := 10*(10*(10*BYTE[p+6]+BYTE[p+7])+BYTE[p+8])+BYTE[p+9]-$D050
    fd := 10_000.0
    
m := F.FAdd(F.FFloat(m),F.FDiv(F.FFloat(mf),fd))
d := F.Fadd(F.FFloat(d),F.FDiv(m,60.0))

'Check E W hemispheres
p := NMEA.Str_Lon_E_W
IF BYTE[p] == "W"
  d ^= $8000_0000           'Negate it

RETURN d
'-------------------------------------------------------------------------


PUB Float_Course_Over_Ground 
'-------------------------------------------------------------------------
'-----------------------┌──────────────────────────┐----------------------
'-----------------------│ Float_Course_Over_Ground │----------------------
'-----------------------└──────────────────────────┘----------------------
'-------------------------------------------------------------------------
''     Action: It returns course over ground in decimal degrees
'' Parameters: None                                 
''    Results: course in float as decimal degrees (0.00 - 359.99)
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Course_Over_Ground
''             S2F                 
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Course_Over_Ground)
'-------------------------------------------------------------------------


PUB Float_Speed_Over_Ground 
'-------------------------------------------------------------------------
'-----------------------┌─────────────────────────┐-----------------------
'-----------------------│ Float_Speed_Over_Ground │-----------------------
'-----------------------└─────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It returns speed over ground in knots
'' Parameters: None                                 
''    Results: speed in knots as float
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Speed_Over_Ground
''             S2F
''       Note: Some GPS units does not calculate speed over a given limit.
''             Check manual                                                           
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Speed_Over_Ground)
'-------------------------------------------------------------------------


PUB Float_Altitude_Above_MSL
'-------------------------------------------------------------------------
'----------------------┌──────────────────────────┐-----------------------
'----------------------│ Float_Altitude_Above_MSL │-----------------------
'----------------------└──────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It returns altitude above MSL in a given unit
'' Parameters: None                                 
''    Results: float altitude usually in [m], but it can be in [ft], too
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Altitude_Above_MSL
''             S2F                               
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Altitude_Above_MSL)
'-------------------------------------------------------------------------


PUB Str_Altitude_Unit
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Str_Altitude_Unit │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns the unit of the altitude data
'' Parameters: None                                 
''    Results: [m] or [ft]
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Altitude_Unit                                                                            
'-------------------------------------------------------------------------

RESULT := NMEA.Str_Altitude_Unit
'-------------------------------------------------------------------------


PUB Float_Geoid_Height
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Float_Geoid_Height │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns the Geoid Height to WGS84 ellipsoid
'' Parameters: None                                 
''    Results: Float Geoid Height (usually in [m])
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Geoid_Height
''             S2F   
''       Note: Geoid Height is, in a very good approximation, the Mean See
''             Level (MSL) referred to the WGS84 ellipsoid                                                                                     
'-------------------------------------------------------------------------

RESULT := S2F(NMEA.Str_Geoid_Height)
'-------------------------------------------------------------------------


PUB Str_Geoid_Height_U
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Str_Geoid_Height_U │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It returns the unit of the Geoid Height
'' Parameters: None                                 
''    Results: Pointer to the string
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Geoid_Height_U                                                             
'-------------------------------------------------------------------------

RESULT := NMEA.Str_Geoid_Height_U
'-------------------------------------------------------------------------


PUB Str_Time_Stamp(index)
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ Str_Time_Stamp │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: It returns UTC time string of reception of various data                                 
'' Parameters: index
''    Results: Pointer to a string where the string is
''              Latitude time stamp for     index 0
''              Longitude time stamp for    index 1
''              Speed time stamp for        index 2
''              Course time stamp for       index 3   
''              Altitude time stamp for     index 4
''              Geoid Height time stamp for index 5
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Time_Stamp
''       Note: The result is the original UTC time data string.                                                                 
'-------------------------------------------------------------------------

RESULT := NMEA.Str_Time_Stamp(index)
'-------------------------------------------------------------------------


PUB Float_Mag_Var_Deg | p, v
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Float_Mag_Var_Deg │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Returns magnetic variation value in decimal degrees                                                                 
'' Parameters: None                                 
''    Results: Magnetic variation as a signed float                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: GPS_Str_NMEA------------->NMEA.Str_Mag_Variation
''                                       NMEA.Str_MagVar_E_W
''             S2F                                                                  
'-------------------------------------------------------------------------
'To calculate Magnetic heading from True heading

p := NMEA.Str_Mag_Variation

'Check for not "M", I.e., data received
IF BYTE[p] == "M"
  RETURN floatNaN

v := S2F(p)

IF v <> floatNaN 
  IF BYTE[NMEA.Str_MagVar_E_W] := "E"
    v ^= $8000_0000           'Remember: 'IF EAST MAGNETIC IS LEAST' 

RETURN v 
'-------------------------------------------------------------------------

 
PUB Float_GreatC_Dist(in,la1,lo1,la2,lo2,out)|r1,r2
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Float_GreatC_Dist │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: It calculates the distance of a Great-Circle course between
''             locations (la1,lo1)-(la2,lo2)                               
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Position of departure
''             -Position of destination
''             -Unit for distance result                                
''    Results: Course distance as float                                                                
''+Reads/Uses: Unit codes, Earth's mean radius in different units                                            
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.Radians
''                                        F.FSub
''                                        F.FMul
''                                        F.FAdd
''                                        F.FDiv
''                                        F.Sin
''                                        F.Cos
''                                        F.Asin
''                                        F.Sqr
''                                        F.Degrees
''       Note: -Shortest distance, as the crow flies, between 2 locations
''             -Not for human navigators, but great for autopilots
'-------------------------------------------------------------------------

IF in == _DEG
  la1 := F.Radians(la1)
  lo1 := F.Radians(lo1)    
  la2 := F.Radians(la2)
  lo2 := F.Radians(lo2)

r1 := F.Sin(F.FDiv(F.FSub(la2,la1),2.0))
r1 := F.FMul(r1,r1)
r2 := F.Sin(F.FDiv(F.FSub(lo2,lo1),2.0))
r2 := F.FMul(F.Cos(la1),F.FMul(r2,r2))
r2 := F.FSqr(F.FAdd(r1,F.FMul(F.Cos(la2),r2)))
r1 := F.FMul(F.ASin(r2),2.0)

CASE out
  _RAD:
    RESULT := r1
  _DEG:
    RESULT := F.Degrees(r1)
  _KM:
    RESULT := F.FMul(r1,_R_KM) 'Mean radius of Earth 6_371.01 [km]
  _NM:
    RESULT := F.FMul(r1,_R_NM) 'Mean radius of Earth 3_440.07 [nmi]  
  _MI:
    RESULT := F.FMul(r1,_R_NM) 'Mean radius of Earth 3_958.76 [mi]
'-------------------------------------------------------------------------
    

PUB Float_GreatC_Init_Brg(in,la1,lo1,la2,lo2,out)|r1,r2,r3,r4
'-------------------------------------------------------------------------
'-------------------------┌───────────────────────┐-----------------------
'-------------------------│ Float_GreatC_Init_Brg │-----------------------
'-------------------------└───────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It calculates the initial bearing of destination on a
''             Great-Circle course between locations (la1,lo1)-(la2,lo2)                               
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Position of departure
''             -Position of destination
''             -Unit for initial bearing result                                
''    Results: Initial bearing as float                                                               
''+Reads/Uses: Unit codes                                              
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.Radians
''                                        F.FSub
''                                        F.FMul
''                                        F.FAdd
''                                        F.FDiv
''                                        F.Sin
''                                        F.Cos
''                                        F.Atan2
''                                        F.Cmp
''                                        F.Degrees
''       Note: As you travel along a Great-Circle course, the bearing of
''             destination constantly changes.                                                         
'-------------------------------------------------------------------------

IF in == _DEG
  la1 := F.Radians(la1)
  lo1 := F.Radians(lo1)    
  la2 := F.Radians(la2)
  lo2 := F.Radians(lo2)

r1 := F.FSub(lo2,lo1)
r2 := F.FMul(F.Sin(r1),F.Cos(la2))
r3 := F.FMul(F.Cos(la1),F.Sin(la2))
r4 := F.FMul(F.FMul(F.Sin(la1),F.Cos(la2)),F.Cos(r1))
r1 := F.Atan2(r2,F.FSub(r3,r4))

CASE out
  _RAD:
    RESULT := r1
  _DEG:
    r1 := F.Degrees(r1)
    IF (F.FCmp(r1,0.0) < 0)    'Normalize the result to compass bearing
      r1 := F.FAdd(r1,360.0)
    RESULT := r1
'-------------------------------------------------------------------------


PUB Float_GreatC_CrossTr_Dist(in,la1,lo1,la2,lo2,la3,lo3,out)|r1,r2,r3,r4
'-------------------------------------------------------------------------
'---------------------┌───────────────────────────┐-----------------------
'---------------------│ Float_GreatC_CrossTr_Dist │-----------------------
'---------------------└───────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It calculates the distance of a third point (la3,lo3) from
''             a Great-Circle path (la1,lo1)-->(la2,lo2)               
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Position of departure
''             -Position of destination
''             -Position of off-Track object
''             -Distance unit for result
''    Results: Distance from path as a float value                                 
''+Reads/Uses: Unit codes, Earth's mean radius in different units                                         
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.FMul
''                                        F.FSub
''                                        F.Sin
''                                        F.Asin
''             Float_GreatC_Dist, Float_GreatC_Init_Brg
''       Note: Negative value means that the off-Track object is at
''             portside (left) when closest                 
'-------------------------------------------------------------------------

r1 := Float_GreatC_Dist(in,la1,lo1,la3,lo3,_RAD)
r2 := Float_GreatC_Init_Brg(in,la1,lo1,la3,lo3,_RAD)
r3 := Float_GreatC_Init_Brg(in,la1,lo1,la2,lo2,_RAD) 
r4 := F.Asin(F.FMul(F.Sin(r1),F.Sin(F.FSub(r2,r3))))

CASE out
  _RAD:
    RESULT := r4
  _KM:
    RESULT := F.FMul(r4,_R_KM) 'Mean radius of Earth 6_371.01 [km]
  _NM:
    RESULT := F.FMul(r4,_R_NM) 'Mean radius of Earth 3_440.07 [nmi]  
  _MI:
    RESULT := F.FMul(r4,_R_MI) 'Mean radius of Earth 3_958.76 [mi]
'-------------------------------------------------------------------------


PUB Float_GreatC_AlongTr_Dist(in,la1,lo1,la2,lo2,la3,lo3,out)|r1,r2,r3,r4
'-------------------------------------------------------------------------
'---------------------┌───────────────────────────┐-----------------------
'---------------------│ Float_GreatC_AlongTr_Dist │-----------------------
'---------------------└───────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: I calculates the distance from the start point (la1,lo1) to
''             the closest point on the path (la1,lo1)-->(la2,lo2) to the
''             3rd point (la3,lo3)              
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Position of departure
''             -Position of destination
''             -Position of off-Track object
''             -Distance unit for result
''    Results: Along-Track distance on path as a float value                                 
''+Reads/Uses: Unit codes, Earth's mean radius in different units                                         
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.FDiv
''                                        F.FCos
''                                        F.Acos
''             Float_GreatC_Dist, Float_GreatC_CrossTr_Dist                                                                         
'-------------------------------------------------------------------------

r1 := Float_GreatC_Dist(in,la1,lo1,la3,lo3,_RAD)
r2 := Float_GreatC_CrossTr_Dist(in,la1,lo1,la2,lo2,la3,lo3,_RAD)
r3 := F.Acos(F.FDiv(F.Cos(r1),F.Cos(r2)))

CASE out
  _RAD:
    RESULT := r3
  _KM:
    RESULT := F.FMul(r3,_R_KM) 'Mean radius of Earth 6_371.01 [km]
  _NM:
    RESULT := F.FMul(r3,_R_NM) 'Mean radius of Earth 3_440.07 [nmi]  
  _MI:
    RESULT := F.FMul(r3,_R_MI) 'Mean radius of Earth 3_958.76 [mi]     
'-------------------------------------------------------------------------


PUB Float_RhumbL_Dist(in,la1,lo1,la2,lo2,out)|r1,r2,r3,r4,r5,r6
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Float_RhumbL_Dist │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: It calculates the distance of a Rhumb-Line course between
''             locations (la1,lo1) and (la2,lo2)                               
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Position of departure
''             -Position of destination
''             -Unit for distance result                                
''    Results: Course distance as float                                                                
''+Reads/Uses: Unit codes, Earth's mean radius, _PI_4 (PI/4)                                              
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.Radians
''                                        F.FSub
''                                        F.FMul
''                                        F.FAdd
''                                        F.FDiv
''                                        F.Log
''                                        F.Atan2
''                                        F.Cmp
''                                        F.Degrees                                                      
'-------------------------------------------------------------------------

IF in == _DEG
  la1 := F.Radians(la1)
  lo1 := F.Radians(lo1)    
  la2 := F.Radians(la2)
  lo2 := F.Radians(lo2)

r1 := F.Tan(F.FAdd(F.FMul(la2,0.5),_PI_4))  'PI/4 added
r2 := F.Tan(F.FAdd(F.FMul(la1,0.5),_PI_4))
r3 := F.Log(F.FDiv(r1,r2))
        
r4 := F.FSub(la2,la1)
r5 := F.FSub(lo2,lo1)

IF F.FCmp(r4,0.0)<>0
  r6 := F.FDiv(r4,r3)
ELSE
  r6 := F.Cos(la1)

r6:= F.FMul(r6,r6)  

r1 := F.FMul(r4,r4)
r2 := F.FMul(r5,r5)
r3 := F.FMul(r2,r6)
r4 := F.FAdd(r1,r3)

r5 := F.FSqr(r4)  

CASE out
  _RAD:
    RESULT := r5
  _KM:
    RESULT := F.FMul(r5,_R_KM) 'Mean radius of Earth 6_371.01 [km]
  _NM:
    RESULT := F.FMul(r5,_R_NM) 'Mean radius of Earth 3_440.07 [nmi]  
  _MI:
    RESULT := F.FMul(r5,_R_MI) 'Mean radius of Earth 3_958.76 [mi]  
'-------------------------------------------------------------------------
  

PUB Float_RhumbL_Const_Brg(in,la1,lo1,la2,lo2,out)|r1,r2,r3,r4,r5
'-------------------------------------------------------------------------
'------------------------┌────────────────────────┐-----------------------
'------------------------│ Float_RhumbL_Const_Brg │-----------------------
'------------------------└────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: It calculates the constant bearing for a Rhumb-Line course
''             between locations (la1,lo1)-(la2,lo2)                               
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Position of departure
''             -Position of destination
''             -Unit for bearing result                                
''    Results: Constant bearing as float                                                                
''+Reads/Uses: Some unit codes, _PI_4 (PI/4)                                              
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.Radians
''                                        F.FSub
''                                        F.FMul
''                                        F.FAdd
''                                        F.FDiv
''                                        F.Log
''                                        F.Atan2
''                                        F.Cmp
''                                        F.Degrees                                                                          
'-------------------------------------------------------------------------

IF in == _DEG
  la1 := F.Radians(la1)
  lo1 := F.Radians(lo1)    
  la2 := F.Radians(la2)
  lo2 := F.Radians(lo2)

r1 := F.Tan(F.FAdd(F.FMul(la2,0.5),_PI_4))  'PI/4 added
r2 := F.Tan(F.FAdd(F.FMul(la1,0.5),_PI_4))
r3 := F.Log(F.FDiv(r1,r2))
r4 := F.FSub(lo2,lo1)
r5 := F.Atan2(r4,r3) 

CASE out
  _RAD:
    RESULT := r5
  _DEG:
    r1 := F.Degrees(r5)
    IF (F.FCmp(r1,0.0) < 0)      'Normalize the result to compass bearing
      r1 := F.FAdd(r1,360.0)
    RESULT := r1
'-------------------------------------------------------------------------

    
PUB RhumbL_Dead_Recon(in1,la1,lo1,in2,d,in3,b,pla2_,plo2_,out)|r1,r2,r3
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ RhumbL_Dead_Recon │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Given a known location (la1,lo1) and a d distance along a
''             Rhumb-Line course of constant b, this procedure calculates
''             the location (la2,lo2) of the arrival point
'' Parameters: -Unit for Latitude, Longitude inputs
''             -Current position
''             -Unit for distance
''             -Distance of the leg
''             -Unit for course
''             -Course of leg
''             -Pointer to destination Latitude
''             -Pointer to destination Longitude
''             -Unit for destination Lat, Lon                    
''    Results: Arrival pos. handed out via pointers, pla2_, plo2_                                                                 
''+Reads/Uses: Unit codes and conversion factors, Earth's m.radius, Pi/4                                                
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.Radians
''                                        F.FSub
''                                        F.FMul
''                                        F.FAdd
''                                        F.FDiv
''                                        F.Cos
''                                        F.Sin
''                                        F.Tan
''                                        F.Log
''                                        F.Degrees                                                                  
'-------------------------------------------------------------------------

'Convert all dimensions into radians
IF in1 == _DEG
  la1 := F.Radians(la1)
  lo1 := F.Radians(lo1)   
CASE in2                  'Turn d into angular distance in [rad]
  _DEG:
    d := F.Radians(d)
  _KM:
    d := F.FDiv(d,_R_KM)
  _NM:
    d := F.FDiv(d,_R_NM)
  _MI:
    d := F.FDiv(d,_R_MI)
IF in3 == _DEG
  b := F.Radians(b)

r1 := F.FMul(d,F.Cos(b))           'Latitude increment 
      
IF F.FCmp(r1,0.0) == 0             'la1 = la2
  r2 := F.FMul(F.FMul(F.Cos(la1),F.Sin(b)),d)  'De-luxe to calculate
                                               'Sin(b) here as it is +-1
                                               'but it saves me an IF
  r2 := F.FAdd(lo1,r2)             'lo2                                
ELSE
  r1 := F.FAdd(la1,r1)                         'la2
  r2 := F.Tan(F.FAdd(F.FMul(r1,0.5),_PI_4))    'PI/4 added
  r3 := F.Tan(F.FAdd(F.FMul(la1,0.5),_PI_4))
  r3 := F.Log(F.FDiv(r2,r3)) 
  r2 := F.FAdd(lo1,F.FMul(F.Tan(b),r3))        'lo2

'Conver units and pass back value via pointers
CASE out
  _RAD:
    LONG[pla2_] := r1
    LONG[plo2_] := r2
  _DEG:
    LONG[pla2_] := F.Degrees(r1)
    LONG[plo2_] := F.Degrees(r2)
'-------------------------------------------------------------------------


PUB RhumbL_CPA(i1,la,lo,i2,cr,i3,sp,tLa,tLo,tCr,tSp,pd_,o1,pt_,o2)|r1,r2,r3,r4,r5,r6
'-------------------------------------------------------------------------
'--------------------------------┌────────────┐---------------------------
'--------------------------------│ RhumbL_CPA │---------------------------
'--------------------------------└────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: This procedure calculates the Closest Point of Approach
''             Distance (DCPA) and the time interval to its occurrence
''             (TCPA) when ownship position is (la,lo), ownship's course 
''             is crs and ownship's speed is sp. The target vessel is at
''             (tLa,TLo), it's course is tCrs and it's speed is tSp. The
''             procedure approximates the Earth's surface with a
''             tangential plane and that means that the distance of the
''             objects should not be larger than about 100 km throughout
''             the scenario.                               
'' Parameters: -Unit for Latitude, Longitude (or X, Y, See note)
''             -Ownship position
''             -Unit for course 
''             -Ownship course
''             -Unit for speed
''             -Ownship speed
''             -Target position
''             -Target speed
''             -Target course
''             -Pointer to DCPA result
''             -Unit for DCPA
''             -Pointer to TCPA result
''             -Unit for TCPA                                  
''    Results: DCPA, TCPA handed out via pointers, pd_, pt_, respectively                                                                
''+Reads/Uses: Unit codes and conversion factors, Earth's mean radius                                               
''    +Writes: None                                    
''      Calls: Float32Full--------------->F.Radians
''                                        F.FSub
''                                        F.FMul
''                                        F.FAdd
''                                        F.FDiv
''                                        F.Cos
''                                        F.Sin
''                                        F.Sqr 
''       Note: -Data units for target data are assumed to be the same as
''             for Ownship
''             -Instead of Lat,Lon values you can specify X,Y coordinates,
''             as well.
''             -Negative DCPA means that target ship, or anything, is at
''             portside (left) at CPA.
''             -Negative value for TCPA means that we are now moving away
''             from the target and CPA happened somewhere in the past.                                                             
'-------------------------------------------------------------------------

'Convert positions into (r2,r1) relative coordinates into [m]
CASE i1
  _DEG:
    la := F.Radians(la)
    lo := F.Radians(lo)
    tLa := F.Radians(tLa)
    tLo := F.Radians(tLo)
    r2 := F.FSub(tLa,la)
    r2 := F.FMul(F.FMul(r2,_R_KM),1000.0)
    r3 := F.FMul(F.FAdd(F.Cos(la),F.Cos(tLa)),0.5)  'Horizontal scale
    r1 := F.FSub(tLo,lo)
    r1 := F.FMul(F.FMul(F.FMul(r1,_R_KM),1000.0),r3)     
  _RAD:
    r2 := F.FSub(tLa,la)
    r2 := F.FMul(F.FMul(r2,_R_KM),1000.0)
    r3 := F.FMul(F.FAdd(F.Cos(la),F.Cos(tLa)),0.5)  'Horizontal scale
    r1 := F.FSub(tLo,lo)
    r1 := F.FMul(F.FMul(F.FMul(r1,_R_KM),1000.0),r3)     
  _KM:
    la := F.FMul(la,1000.0)
    lo := F.FMul(lo,1000.0)
    tLa := F.FMul(tLa,1000.0)
    tLo := F.FMul(tLo,1000.0)
    r2 := F.FSub(tLa,la)
    r1 := F.FSub(tLo,lo)
  _NM:
    la := F.FMul(la,1852.0)
    lo := F.FMul(lo,1852.0)
    tLa := F.FMul(tLa,1852.0)
    tLo := F.FMul(tLo,1852.0)
    r2 := F.FSub(tLa,la)
    r1 := F.FSub(tLo,lo)
  _MI:
    la := F.FMul(la,1609.34)
    lo := F.FMul(lo,1609.34)
    tLa := F.FMul(tLa,1609.34)
    tLo := F.FMul(tLo,1609.34)
    r2 := F.FSub(tLa,la)
    r1 := F.FSub(tLo,lo)  

'Conver courses into [rad]
IF i2 == _DEG
  cr := F.Radians(cr)
  tCr := F.Radians(tCr)

'Conver speeds into [m/s] 
CASE i3
  _KPH:
    sp := F.FDiv(sp,3.6)
    tSp := F.FDiv(tSp,3.6)
  _KNOT:
    sp := F.FMul(sp,0.514444)
    tSp := F.FMul(tSp,0.514444)  
  _MPH:
    sp := F.FMul(sp,0.44704)
    tSp := F.FMul(tSp,0.44704)

'Relative speed (r3, r4)   
r3 := F.FSub(F.FMul(F.Sin(tCr),tSp),F.FMul(F.Sin(cr),sp))
r4 := F.FSub(F.FMul(F.Cos(tCr),tSp),F.FMul(F.Cos(cr),sp))

r5 := F.FDiv(1.0,F.FSqr(F.FAdd(F.FMul(r3,r3),F.FMul(r4,r4)))) '1/Vr

r6 := F.FMul(F.FSub(F.FMul(r2,r3),F.FMul(r1,r5)),r5)          'DCPA

'Pass back DCPA
CASE o1
  _KM:
    LONG[pd_] := F.FDiv(r6,1000.0)
  _NM:
    LONG[pd_] := F.FDiv(r6,1852.0)
  _MI:
    LONG[pd_] := F.FDiv(r6,1609.344)

'Calculate TCPA
r6 := F.FNeg(F.FMul(F.FMul(F.FAdd(F.FMul(r1,r3),F.FMul(r2,r4)),r5),r5))

'Pass back r6 = TCPA
CASE o2
  _MIN:
    LONG[pt_] := F.FDiv(r6,60.0)
  _HOUR:
    LONG[pt_] := F.FDiv(r6,3600.0)  
'-------------------------------------------------------------------------    
    

PRI S2L(strPtr) | c, s
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ S2L │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Converts a string to long                                 
' Parameters: Pointer to the string                                
'    Results: Long value                                                               
'+Reads/Uses: floaNaN                                               
'    +Writes: None                                    
'      Calls: None
'       Note: No syntax check except for null strings. It assumes a
'             perfect string to describe small signed decimal integers
'-------------------------------------------------------------------------

IF STRSIZE(strPtr)           'Not a null string
  s~
  REPEAT WHILE c := BYTE[strPtr++]
    IF c == "-"
      s := -1
    ElSE      
      RESULT := RESULT * 10 + c - $30
  IF s
    RESULT := -1 * RESULT     
ELSE
  RESULT := floatNaN         'To signal invalid value since -1 can be a
                             'valid result in some proprietary sentence
'-------------------------------------------------------------------------


PRI S2F(strPtr) | i, e, s, b, sg
'-------------------------------------------------------------------------
'-----------------------------------┌─────┐-------------------------------
'-----------------------------------│ S2F │-------------------------------
'-----------------------------------└─────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Converts a string to float                                 
' Parameters: Pointer to the string                                 
'    Results: Float value                                                                
'+Reads/Uses: floatNaN                                               
'    +Writes: None                                    
'      Calls: None
'       Note: -It can handle only small numbers with max. 4 decimal digits
'             and no exponent. This is enough for the fields in NMEA data
'             where the field contains a string for a float value.
'             -No syntax check except for null strings. It assumes a
'             perfect string that represents small signed float value                                                             
'-------------------------------------------------------------------------
'NMEA String to Float routine. 

IF s := STRSIZE(strPtr)        'Not a null string
  i~                           'Value accumulator
  e~                           'Exponent counter
  sg~                          'Sign

  REPEAT s
    CASE b := BYTE[strPtr++]   'Actual character
      "-":
        sg := 1                'To remember negative sign
      ".":
        e := 1                 'Decimal  point detected. Actuate divider's
                               'accumulation
      "0".."9":
        i := 10 * i + b - $30  'Increment sum total
        IF e
          e++                  'Increment divider's exponent

  CASE --e                     'CASE used to avoid repeated float division
    -1, 0: RESULT := F.FFloat(i)
    1:     RESULT := F.FDIV(F.FFloat(i), 10.0)
    2:     RESULT := F.FDIV(F.FFloat(i), 100.0)
    3:     RESULT := F.FDIV(F.FFloat(i), 1000.0)
    4:     RESULT := F.FDIV(F.FFloat(i), 10_000.0)

  'Check for signum
  IF sg  
    RESULT ^= $8000_0000       'Negate it 
    
ELSE
  RESULT := floatNaN           'To signal invalid value
'-------------------------------------------------------------------------


DAT

floatNaN       LONG $7FFF_FFFF       'Not a Number code for invalid data
strNullStr     BYTE 0                'Null string  

'Short explanation of one byte codes. These one byte codes are translated
'to  long values, too. E.g., with "Long_Pos_Mode_Selection" where 1
'stands for "Manual" and 2 stands for "Automatic"

strDataInvalid BYTE "Invalid", 0
strDataValid   BYTE "Valid", 0
strAutonomous  BYTE "Autonomous", 0
strDGPS        BYTE "Differential GPS", 0
strDeadReckon  BYTE "Dead Reckoning", 0
strManual      BYTE "Manual", 0
strSimulator   BYTE "Simulator", 0
strNoFix       BYTE "Fix Invalid", 0
strGPS_SPS     BYTE "GPS SPS, Fix Valid", 0
strDGPS_SPS    BYTE "DGPS SPS, Fix Valid", 0
strGPS_PPS     BYTE "GPS PPS, Fix Valid", 0
strInt_RTK     BYTE "Integer RTK, Fix Valid", 0
strFloat_RTK   BYTE "Float RTK, Fix Valid", 0
strDR_FV       BYTE "Dead Reckoning, Fix Valid", 0
strMan_NF      BYTE "Manual Input, No Fix", 0
strSim_NF      BYTE "Simulation, No Fix", 0
strMan2D3D     BYTE "Manual 2D/3D", 0
strAuto2D3D    BYTE "Automatic 2D/3D", 0
str2D          BYTE "2D", 0
str3D          BYTE "3D", 0
strNotAvail    BYTE "Not Available", 0


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                  