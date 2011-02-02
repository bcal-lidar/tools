;+
; NAME:
;
;       ReprojectLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is reproject LAS files
;
; PRODUCTS:
;
;       The output is a new LAS file for each input LAS file.  The output files have the same
;       name as the input files.
;
; AUTHOR:
;
;       David Streutker
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://bcal.geology.isu.edu
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;       WriteLAS_BCAL.pro
;       RecordsToProj_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2007.
;       Added support for embedded projections, June 2007.
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

pro ReprojectLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish error handler.  The most likely problem is that the user will open a data
    ; file that is too large to process.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    return
endif

    ; Get the input file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Establish the default projection

ReadLAS_BCAL, inputFiles[0], header, projection=defProj, /nodata
if n_tags(defProj) eq 0 then defProj = envi_proj_create()

    ; Get the input and output projections and the output directory

readBase = widget_auto_base(title='Select Projections')

    dummy = widget_label(readBase, value='If needed, set input projection:')
    dummy = widget_map(readBase, default_map=[0,0], default_proj=defProj, uvalue='iProj',  /auto_manage)
    dummy = widget_label(readBase, value='Set output projection:')
    dummy = widget_map(readBase, default_map=[0,0], default_proj=defProj, uvalue='oProj', /auto_manage)
    dummy = widget_outf(readBase, /directory, prompt='Select output directory', uvalue='outDir', /auto)

result = auto_wid_mng(readBase)
if result.accept eq 0 then return

iProj = result.iProj.proj
oProj = result.oProj.proj

outputDir = result.outDir

    ; Set the scale based on the new projection

case oProj.units of

    envi_translate_projection_units('Meters')           : scale = 1d-2
    envi_translate_projection_units('Km')               : scale = 1d-5

    envi_translate_projection_units('Feet')             : scale = 1d-2
    envi_translate_projection_units('Yards')            : scale = 1d-2
    envi_translate_projection_units('Miles')            : scale = 1d-6
    envi_translate_projection_units('Nautical Miles')   : scale = 1d-6

    envi_translate_projection_units('Degrees')          : scale = 1d-7
    envi_translate_projection_units('Minutes')          : scale = 1d-6
    envi_translate_projection_units('Seconds')          : scale = 1d-4
    envi_translate_projection_units('Radians')          : scale = 1d-9

endcase

part = 5000D

    ; Process each data file individually

for a=0,nFiles-1 do begin

        ; Initialize the status report

    reportText  = 'Reprojecting file' + strcompress(a+1) + ' of' + strcompress(nFiles)
    reportText += ': ' + file_basename(inputFiles[a])
    envi_report_init, reportText, base=statBase, /interrupt, title='Reprojecting'

        ; Read the input file

    ReadLAS_BCAL, inputFiles[a], header, data, records=records

        ; Set up the iteration

    nParts = ceil(header.nPoints / part)
    envi_report_inc, statBase, nParts

        ; Convert the input data, part by part

    for b=0,nParts-1 do begin

        envi_report_stat, statBase, b+1, nParts, cancel=cancel
        if cancel then begin
            envi_report_init, base=statBase, /finish
            return
        endif

        pStart =  part *  b
        pEnd   = (part * (b + 1) < header.nPoints) - 1

        envi_convert_projection_coordinates, data[pStart:pEnd].east  * header.xScale + header.xOffset, $
                                             data[pStart:pEnd].north * header.yScale + header.yOffset, $
                                             iProj, xCoords, yCoords, oProj

        data[pStart:pEnd].east  = xCoords / scale
        data[pStart:pEnd].north = yCoords / scale

    endfor

        ; Get the min and max values of the new coordinates

    xMin = min(data.east,  max=xMax)
    yMin = min(data.north, max=yMax)

        ; Record the new header parameters

    header.xScale  = scale
    header.yScale  = scale
    header.xOffset = 0
    header.yOffset = 0

    header.xMin = xMin * header.xScale ;+ header.xOffset
    header.xMax = xMax * header.xScale ;+ header.xOffset
    header.yMin = yMin * header.yScale ;+ header.yOffset
    header.yMax = yMax * header.yScale ;+ header.yOffset

        ; Update the array of records

    newRecord = RecordsToProj_BCAL(oProj, /reverse)

    if n_tags(records) then begin

        rIndex = where(records.recordID eq 34735)

        if rIndex eq -1 then records = [records,newRecord] $
                        else records[rIndex] = newRecord

    endif else records = newRecord

        ; Write the new file

    outputFile = outputDir + '\' + file_basename(inputFiles[a])

    WriteLAS_BCAL, outputFile, header, data, records=records, /check

    envi_report_init, base=statBase, /finish

endfor


end