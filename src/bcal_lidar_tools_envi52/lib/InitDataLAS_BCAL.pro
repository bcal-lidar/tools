;+
; NAME:
;
;       InitDataLAS_BCAL
;
; PURPOSE:
;
;       This function initializes a structure to read each point data record from a .las
;       lidar file.
;
;       For more information on the .las lidar data format, see http://www.lasformat.org
;
; AUTHOR:
;
;       David Streutker
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://bcal.geology.isu.edu/
;
; CALLING SEQUENCE:
;
;       data = InitDataLAS_BCAL(PointFormat=PointFormat)
;
;       The PointFormat specifies the requested format of the data record.
;
; RETURN VALUE:
;
;       The program returns a single structure corresponding to a single data
;       record of a .las file.
;
; KNOWN ISSUES:
;
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
;       Change from a procedure to a function, July 2007
;       Added support for LAS 1.2 RGB ancillary image data, June 2010 (Rupesh Shrestha).
;       Added support for formats 5 to 10, April 2016 (Exelis VIS).
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2006 David Streutker, Idaho State University.
;
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;
; 3. This notice may not be removed or altered from any source distribution.
;
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################

function InitDataLAS_BCAL, pointFormat=pointFormat

compile_opt idl2, logical_predicate

    ; Define the data structure

data = {formatD0,  $
            east    : 0L,  $     ; X data
            north   : 0L,  $     ; Y data
            elev    : 0L,  $     ; Z data
            inten   : 0US, $     ; Intensity
            nReturn : 0B,  $     ; Return number, number of returns, scan direction, edge
            class   : 0B,  $     ; Classification
            angle   : 0B,  $     ; Scan angle
            user    : 0B,  $     ; User data
            source  : 0US  $     ; Point source ID
}

    ; If format 1 is requested, add the time field
data1 = {formatD1, inherits formatD0, time:0D}    ; GPS time field

if pointFormat eq 1 then data = {formatD1, inherits formatD0, time:0D}    ; GPS time field

; If format 2 is requested, add the RGB channel value fields
data2 = {formatD2, inherits formatD0, $
      red   : 0US, $     ; Red image channel value
      green : 0US, $     ; Blue image channel value
      blue  : 0US  $     ; Green image channel value
}

; If format 3 is requested, add the time field and RGB channel value fields
data3 = {formatD3, inherits formatD0, $
  time : 0D,  $    ; GPS time field
  red  : 0US, $     ; Red image channel value
  green: 0US, $     ; Blue image channel value
  blue : 0US  $     ; Green image channel value
}

; If format 4 is requested, adds Wave Packets to Point Data Record Format 1.
data4 = {formatD4, inherits formatD1, $
   WavePacketDescIndex   : 0B, $     ; Wave Packet Descriptor Index
   WavePacketOffset : 0UL, $     ; Byte offset to waveform data
   WavePacketSize : 0UL, $     ; Waveform packet size in bytes
   WavePacketReturnPt : 0.0, $     ; Return Point Waveform Location
   WavePacketX : 0.0, $     ;X(t)
   WavePacketY : 0.0, $     ;X(t)
   WavePacketZ : 0.0 $     ;X(t)
}
  
; If format 5 is requested, adds Wave Packets to Point Data Record Format 3.
data5 = {formatD5, inherits formatD3, $
   WavePacketDescIndex   : 0B, $     ; Wave Packet Descriptor Index
   WavePacketOffset : 0UL, $     ; Byte offset to waveform data
   WavePacketSize : 0UL, $     ; Waveform packet size in bytes
   WavePacketReturnPt : 0.0, $     ; Return Point Waveform Location
   WavePacketX : 0.0, $     ;X(t)
   WavePacketY : 0.0, $     ;X(t)
   WavePacketZ : 0.0 $     ;X(t)
 }

data6 = {formatD6,  $
   east    : 0L,  $     ; X data
   north   : 0L,  $     ; Y data
   elev    : 0L,  $     ; Z data
   inten   : 0US, $     ; Intensity
   nReturn : 0B,  $     ; Return number, number of returns
   classScanEdge : 0B,  $     ; classification flags, scanner channel, scan direction, edge
   class   : 0B,  $     ; Classification
   angle   : 0S,  $     ; Scan angle
   user    : 0B,  $     ; User data
   source  : 0US,  $     ; Point source ID
   time : 0D  $    ; GPS time field
 }

data7 = {formatD7, inherits formatD6, $
   red   : 0US, $     ; Red image channel value
   green : 0US, $     ; Blue image channel value
   blue  : 0US  $     ; Green image channel value
} 

data8 = {formatD8, inherits formatD7, $
  nir  : 0US  $     ; NIR channel value
}

data9 = {formatD9, inherits formatD6, $
  WavePacketDescIndex   : 0B, $     ; Wave Packet Descriptor Index
  WavePacketOffset : 0UL, $     ; Byte offset to waveform data
  WavePacketSize : 0UL, $     ; Waveform packet size in bytes
  WavePacketReturnPt : 0.0, $     ; Return Point Waveform Location
  WavePacketX : 0.0, $     ;X(t)
  WavePacketY : 0.0, $     ;X(t)
  WavePacketZ : 0.0 $     ;X(t)
}

data10 = {formatD10, inherits formatD8, $
  WavePacketDescIndex   : 0B, $     ; Wave Packet Descriptor Index
  WavePacketOffset : 0UL, $     ; Byte offset to waveform data
  WavePacketSize : 0UL, $     ; Waveform packet size in bytes
  WavePacketReturnPt : 0.0, $     ; Return Point Waveform Location
  WavePacketX : 0.0, $     ;X(t)
  WavePacketY : 0.0, $     ;X(t)
  WavePacketZ : 0.0 $     ;X(t)
}

case pointFormat of
  2: return, data2
  3: return, data3
  4: return, data4
  5: return, data5
  6: return, data6
  7: return, data7
  8: return, data8
  9: return, data9
  10: return, data10
  else: return, data
endcase

end