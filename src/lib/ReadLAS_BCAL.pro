;+
; NAME:
;
;       ReadLAS_BCAL
;
; PURPOSE:
;
;       This program reads the header and point data from a .las file.
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
;       ReadLAS_BCAL, inputFile, header, data, records=records, check=check, projection=projection, nodata=nodata, assoclun=assoclun
;
; RETURN VALUE:
;
;       The program returns a structure containing the header information and an array of
;       structures containing the point data from the specified .las file.
;
;       Set the RECORDS keyword to a named variable that will contain a structure or array of structures
;       of the variable length records.  If no records exist, a value of -1 is returned.
;
;       Set the CHECK keyword to correct any internal inconsistancies in the header.
;
;       Set the PROJECTION keyword to return an ENVI projection structure from projection information
;       embedded in the file.  If no information exists, a value of -1 is returned.
;
;       Set the NODATA keyword to prohibit reading the point data and return only the header.
;
;       Set the ASSOCLUN keyword to a named variable to use associated input/output to read the data in the
;       file.  The variable will be returned set the associated LUN value.
;
; DEPENDENCIES:
;
;       InitHeaderLAS_BCAL
;       InitRecordLAS_BCAL
;       InitDataLAS_BCAL
;       RecordsToProj_BCAL
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
;       Changed CLOSE command to FREE_LUN, April 2006
;       Added RECORDS keyword, August 2006
;       Added CHECK keyword, September 2006
;       Added NODATA, PROJECTION, and ASSOCLUN keywords, June 2007
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

pro ReadLAS_bcal, inputFile, header, data, records=records, check=check, projection=projection, $
             noData=noData, assocLun=assocLun

compile_opt idl2, logical_predicate

    ; Create the header structure

header = InitHeaderLAS_BCAL()

    ; Get info about the file.  Then open the file and read the header

fInfo = file_info(inputFile)

openr, inputLun, inputFile, /get_lun, /swap_if_big_endian
readu, inputLun, header

    ; If the header indicates that the file contains variable length records, read them

if header.nRecords then begin

        ; Define and read variable length records

    records = replicate(InitRecordLAS_BCAL(), header.nRecords)

    for a=0,header.nRecords-1 do begin

        tempRecord = InitRecordLAS_BCAL(/noData)
        readu, inputLun, tempRecord

        if tempRecord.recordLength then begin

            dataTemp = bytarr(tempRecord.recordLength)
            readu, inputLun, dataTemp

            records[a] = create_struct(tempRecord, 'data', ptr_new(dataTemp))

        endif else records[a] = create_struct(tempRecord, 'data', ptr_new())

    endfor

endif else records = -1

    ; Check for projection information in the variable length records

if n_tags(records) then projection = RecordsToProj_BCAL(records) $
                   else projection = -1

    ; Read point data start signature if the file is in the LAS 1.0 format

if header.versionMinor eq 0 then begin
    pointStart = bytarr(2)
    readu, inputLun, pointStart
endif

    ; Make sure that the data offset value is correct.

if header.dataOffset ne (fInfo.size - header.nPoints * header.pointLength) then begin

    print, 'header.dataOffset value is incorrect.  Fixing...'
    header.dataOffset = fInfo.size - header.nPoints * header.pointLength

endif

if ~ keyword_set(noData) then begin

        ; Define a point data structure

    dataStr = InitDataLAS_BCAL(pointFormat=header.pointFormat)

    if keyword_set(assocLun) then begin

        data = assoc(inputLun, dataStr, header.dataOffset, /packed)

        assocLun = inputLun

    endif else begin

            ; Create an array of data structures to contain all of the point data

        data = replicate(dataStr, header.nPoints)

            ; Read the point data

        point_lun, inputLun, header.dataOffset
        readu,     inputLun, data
        free_lun,  inputLun

            ; If requested, perform consistancy check

        if keyword_set(check) then begin

            if n_tags(records) then header.nRecords = n_elements(records) $
                               else header.nRecords = 0

            header.pointLength = n_tags(data, /data_length)

            header.nReturns = histogram((data.nReturn mod 8), min=1, max=5)
            if total(header.nReturns) ne header.nPoints then header.nReturns[0] += (header.nPoints - total(header.nReturns))

            header.xMax = max(data.east,  min=xMin) * header.xScale + header.xOffset
            header.yMax = max(data.north, min=yMin) * header.yScale + header.yOffset
            header.zMax = max(data.elev,  min=zMin) * header.zScale + header.zOffset
            header.xMin = xMin * header.xScale + header.xOffset
            header.yMin = yMin * header.yScale + header.yOffset
            header.zMin = zMin * header.zScale + header.zOffset

        endif

    endelse

endif else free_lun, inputLun


end