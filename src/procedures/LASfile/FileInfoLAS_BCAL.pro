;+
; NAME:
;
;       FileInfoLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to display information about a selected LAS file.
;
; PRODUCTS:
;
;       Information about an LAS file is reported in a text window.  This report includes
;       all the header information, as well as any embedded projection information and
;       variable record headers.
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
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       April 2010 - Fixed bug that caused program to crash in certain
;                   condition (Rupesh Shrestha)
;       June 2007 - Written by David Streutker.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2007 David Streutker, Idaho State University.
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

    ; Begin main program

pro FileInfoLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file')
    return
endif

    ; Get the file

file = dialog_pickfile(title='Select LAS file', filter='*.las', /path)
if file eq '' then return

report = 'File: ' + file
report = [report,'']

    ; Read the file, getting all information except the data

ReadLAS_BCAL, file, header, /nodata, records=records, projection=projection

    ; Add the header info

if header.year then begin
    caldat, (header.day + julday(1,1,header.year) - 1), month, day, year
    date = strcompress(strjoin([month,day,year],'/'),/remove)
endif else date = 'N/A'

report = [report,'Header:']
report = [report,' Signature:                  '   + string(header.signature)]
report = [report,' Reserved:                   '   + strcompress(header.reserved,/r)]
report = [report,' File Source:                '   + strcompress(header.fileSource,/r)]
report = [report,' Project ID - GUID data 1:   '   + strcompress(header.guid1,/r)]
report = [report,' Project ID - GUID data 2:   '   + strcompress(header.guid2,/r)]
report = [report,' Project ID - GUID data 3:   '   + strcompress(header.guid3,/r)]
report = [report,' Project ID - GUID data 4:  '    + strjoin(strcompress(fix(header.guid4)))]
report = [report,' Version:                    '   + strcompress(fix(header.versionMajor),/r) + '.' $
                                                   + strcompress(fix(header.versionMinor),/r)]
report = [report,' System ID:                  '   + string(header.systemID)]
report = [report,' Software ID:                '   + string(header.softwareID)]
report = [report,' Creation Date:              '   + date]
report = [report,' Header Size:                '   + strcompress(header.headerSize,/r)]
report = [report,' Data Offset:                '   + strcompress(header.dataOffset,/r)]
report = [report,' Number of Variable Records: '   + strcompress(header.nRecords,/r)]
report = [report,' Point Format:               '   + strcompress(fix(header.pointFormat),/r)]
report = [report,' Point Length:               '   + strcompress(header.pointLength,/r)]
report = [report,' Number of Points:           '   + strcompress(header.nPoints,/r)]
report = [report,' Number of Returns:         '    + strjoin(strcompress(header.nReturns))]
report = [report,' Scaling in X:               '   + strcompress(header.xScale,/r)]
report = [report,' Scaling in Y:               '   + strcompress(header.yScale,/r)]
report = [report,' Scaling in Z:               '   + strcompress(header.zScale,/r)]
report = [report,' Offset in X:                '   + strcompress(header.xOffset,/r)]
report = [report,' Offset in Y:                '   + strcompress(header.yOffset,/r)]
report = [report,' Offset in Z:                '   + strcompress(header.zOffset,/r)]
report = [report,' Min and Max in X:           '   + strcompress(header.xMin,/r) + ',' + strcompress(header.xMax)]
report = [report,' Min and Max in Y:           '   + strcompress(header.yMin,/r) + ',' + strcompress(header.yMax)]
report = [report,' Min and Max in Z:           '   + strcompress(header.zMin,/r) + ',' + strcompress(header.zMax)]
report = [report,'']

    ; If it exists, add the projection info

report = [report,'Projection:']

if n_tags(projection) ne 0 then begin

    report = [report,' Name:  ' + projection.name]
    if projection.type eq 2 then report = [report,' Zone:  ' + strcompress(round(projection.params[0]),/r)]
    report = [report,' Datum: ' + projection.datum]
    report = [report,' Units: ' + envi_translate_projection_units(projection.units)]

endif else report = [report,' Undefined']

report = [report,'']

    ; If they exist, add the records

report = [report,'Variable Length Records:']

if header.nRecords then begin

    for a=0,header.nRecords-1 do begin

        report = [report,  strcompress(a+1,/r) + ') User ID:       ' + string(records[a].userID)]
        report = [report,'   Record ID:     '   + strcompress(records[a].recordID,/r)]
        report = [report,'   Record Length: '   + strcompress(records[a].recordLength,/r)]
        report = [report,'   Description:   '   + string(records[a].description)]

    endfor

    report = [report,'']

endif else report = [report,' None']

    ; Display to a report window

envi_info_wid, report, title='Info: ' + file_basename(file), xs=max(strlen(report))+5, ys=40


end