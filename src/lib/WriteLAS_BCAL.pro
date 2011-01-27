;+
; NAME:
;
;       WriteLAS_BCAL
;
; PURPOSE:
;
;       This program writes a .las file from the input header, variable length records, and data.
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
;       http://geology.isu.edu/BCAL
;
; CALLING SEQUENCE:
;
;       WriteLAS_BCAL, outputFile, header, data, records=records, check=check, nodata=nodata
;
; RETURN VALUE:
;
;       None.  The procedure creates a .las file using the input header and data structures and optional
;       variable length record structures.
;
;       Set the RECORDS keyword to a named variable that contains a structure or array of structures
;       of the variable length records.
;
;       Set the CHECK keyword to correct any internal inconsistancies in the header before writing the new file.
;
;       Set the NODATA keyword to write only the header and any available variable length records
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, August 2006.
;       Added CHECK keyword, March 2007.
;       Added RECORDS and NODATA keywords, June 2007.
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

pro WriteLAS_BCAL, outputFile, header, data, records=records, check=check, nodata=nodata

compile_opt idl2, logical_predicate

    ; Make sure the header fields are updated

header.signature  = byte('LASF')
header.softwareID = byte('LidarTools, IDL ' + !version.release)

date = bin_date(systime(/utc))
day  = julday(date[1],date[2],date[0]) - julday(1,1,date[0]) + 1
header.day  = uint(day)
header.year = uint(date[0])

    ; If requested, perform consistency check

if keyword_set(check) then begin

    header.dataOffset = 227

    if header.versionMinor eq 0 then header.dataOffset += 2

    if n_tags(records) then begin
        header.dataOffset += total(records.recordLength, /int) + 54L * n_elements(records)
        header.nRecords    = n_elements(records)
    endif else header.nRecords = 0

    if ~ keyword_set(nodata) then begin

        header.pointLength = n_tags(data, /data_length)
        if header.pointLength eq 20 then header.pointFormat = 0 $
                                    else header.pointFormat = 1

        header.nPoints  = n_elements(data)
        header.nReturns = histogram((data.nReturn mod 8), min=1, max=5)
        if total(header.nReturns) ne header.nPoints then header.nReturns[0] += (header.nPoints - total(header.nReturns))

        header.xMax = max(data.east,  min=xMin) * header.xScale + header.xOffset
        header.yMax = max(data.north, min=yMin) * header.yScale + header.yOffset
        header.zMax = max(data.elev,  min=zMin) * header.zScale + header.zOffset
        header.xMin = xMin * header.xScale + header.xOffset
        header.yMin = yMin * header.yScale + header.yOffset
        header.zMin = zMin * header.zScale + header.zOffset

    endif else begin

        if header.pointFormat then header.pointLength = 28 $
                              else header.pointLength = 20

    endelse

endif

    ; Open the output file and write the header

openw,  outputLun, outputFile, /get_lun, /swap_if_big_endian
writeu, outputLun, header

    ; If variable length records are present, write them

if n_tags(records) then begin

    for a=0,n_elements(records)-1 do begin

        for b=0,4 do writeu, outputLun, records[a].(b)

        if (records[a].recordLength) then writeu, outputLun, *records[a].data

    endfor

endif

    ; If necessary, write the point data start signature

if header.versionMinor eq 0 then writeu, outputLun, bytarr(2)

    ; Unless the NODATA flag is set, write the data.

if ~ keyword_set(nodata) then writeu, outputLun, data

    ; Close the file

free_lun, outputLun


end