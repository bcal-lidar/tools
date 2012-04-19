;+
; NAME:
;
;       AsciiToLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to convert point data from an text file to an LAS file.
;
; PRODUCTS:
;
;       The output is one LAS file for each input text file, containing all the data included in
;       the text file.  The output files have the same name as the input text files, but with
;       the .las suffix.
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
; DEPENDENCIES:
;
;       InitHeaderLAS_BCAL.pro
;       InitDataLAS_BCAL.pro
;       RecordsToProj_BCAL.pro
;       WriteLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2007.
;       Added support for embedded projections, June 2007.
;       Added projection-dependent scaling, October 2007.
;       Added support for LAS 1.2 format, June 2010 (Rupesh Shrestha).
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright @ 2007 David Streutker, Idaho State University.
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

pro AsciiToLAS_BCAL, event

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

    ; Get the input files

inputFiles = envi_pickfile(title='Select ASCII LiDAR file(s)', /multiple_files)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Set up the list of returns

returnList = 'Return' + strcompress(indgen(5)+1)
returnList = ['In File',ReturnList]
returnInit = strarr(nFiles)
fileName   = strarr(nFiles)

    ; Check filenames for indication of return number

for i=0,n_elements(inputFiles)-1 do begin

    if strmatch(file_basename(inputFiles[i]),'*first*',     /fold_case) then returnInit[i] = 1
    if strmatch(file_basename(inputFiles[i]),'*bald*',      /fold_case) then returnInit[i] = 2
    if strmatch(file_basename(inputFiles[i]),'*extracted*', /fold_case) then returnInit[i] = 2
    if strmatch(file_basename(inputFiles[i]),'*last*',      /fold_case) then returnInit[i] = 2

    fileName[i] = 'file' + strcompress(i)

endfor

    ; Query user for return number associated with each file

returnBase  = widget_auto_base(title='Select Returns')

if nFiles le 5 then begin
  outerBase = widget_base(returnBase, /column)
endif else begin
  outerBase = widget_base(returnBase, /column, /scroll,  Y_SCROLL_SIZE=110)
endelse 

for j=0,nFiles-1 do begin

    indBase = widget_base(outerBase, /row, /align_right)
    dummy   = widget_pmenu(indBase, default=returnInit[j], list=returnList, prompt=file_basename(inputFiles[j]), $
                           uvalue=fileName[j], /auto_manage)

endfor

result = auto_wid_mng(returnBase)
if (result.accept eq 0) then return

fileReturn = bytarr(nFiles)
for k=0,nFiles-1 do fileReturn[k] = result.(k)

    ; Read a sample of the data

dataSamp = strarr(20)
openr, inputLun, inputFiles[0], /get_lun
readf, inputLun, dataSamp
free_lun, inputLun

    ; Extract values from the sample data, determining number of fields in the data

dummy = strsplit(dataSamp[19], ' ,;', /extract, count=nFields)

fieldList = indgen(nFields) + 1
fieldList = 'Field ' + strcompress(fieldList)
fieldList = [fieldList,'  n/a  ']

    ; Get the user parameters

readBase = widget_auto_base(title='Data Selection')

    dummy     = widget_label(readBase, value='Sample Data:')
    dummy     = widget_text(readBase, /scroll, value=dataSamp, ysize=6)

    headBase  = widget_base(readBase, /row)
    dummy     = widget_param(headBase, default=1, dt=2, floor=0, prompt='Enter number of lines in the file header: ', $
                             uvalue='nHeader', /auto)

    paramBase = widget_base(readBase, /row)
    leftBase  = widget_base(paramBase, /column)
    eastBase  = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(eastBase, list=fieldList[0:nFields-1],  default=0, prompt='Select easting field:', $
                             uvalue='fEast', /auto)
    northBase = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(northBase, list=fieldList[0:nFields-1], default=1, prompt='Select northing field:', $
                             uvalue='fNorth', /auto)
    elevBase  = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(elevBase, list=fieldList[0:nFields-1],  default=2, prompt='Select elevation field:', $
                             uvalue='fElev', /auto)
    intenBase = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(intenBase, list=fieldList, default=nFields, prompt='Select intensity field:', $
                             uvalue='fInten', /auto)
    retBase   = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(retBase, list=fieldList,   default=nFields, prompt='Select return number field:', $
                             uvalue='fReturn', /auto)
;    nretBase   = widget_base(leftBase, /row, /align_right)
;    dummy     = widget_pmenu(nretBase, list=fieldList,   default=nFields, prompt='Select number of returns field:', $
;                             uvalue='fnReturn', /auto)                           
    classBase = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(classBase, list=fieldList, default=nFields, prompt='Select classfication field:', $
                             uvalue='fClass', /auto)
    timeBase  = widget_base(leftBase, /row, /align_right)
    dummy     = widget_pmenu(timeBase, list=fieldList,  default=nFields, prompt='Select GPS time field:', $
                             uvalue='fTime', /auto)
                             
    rightBase = widget_base(paramBase, /column)
    angleBase = widget_base(rightBase, /row, /align_right)
    dummy     = widget_pmenu(angleBase, list=fieldList, default=nFields, prompt='Select scan angle field:', $
                             uvalue='fAngle', /auto)
;    sdirBase = widget_base(rightBase, /row, /align_right)
;    dummy     = widget_pmenu(sdirBase, list=fieldList, default=nFields, prompt='Select scan direction field:', $
;                             uvalue='fScanDir', /auto)
;    lineBase  = widget_base(rightBase, /row, /align_right)
;    dummy     = widget_pmenu(lineBase, list=fieldList,  default=nFields, prompt='Select edge of flight line field:', $
;                             uvalue='fLine', /auto)
    userdBase = widget_base(rightBase, /row, /align_right)
    dummy     = widget_pmenu(userdBase, list=fieldList, default=nFields, prompt='Select user data field:', $
                             uvalue='fuserData', /auto)
    ptsrcBase = widget_base(rightBase, /row, /align_right)
    dummy     = widget_pmenu(ptsrcBase, list=fieldList, default=nFields, prompt='Select point source ID field:', $
                             uvalue='fptsrc', /auto)
    redBase = widget_base(rightBase, /row, /align_right)
    dummy     = widget_pmenu(redBase, list=fieldList, default=nFields, prompt='Select red image channel field:', $
                             uvalue='fred', /auto)
    greenBase = widget_base(rightBase, /row, /align_right)
    dummy     = widget_pmenu(greenBase, list=fieldList, default=nFields, prompt='Select green image channel field:', $
                             uvalue='fgreen', /auto)
    blueBase = widget_base(rightBase, /row, /align_right)
    dummy     = widget_pmenu(blueBase, list=fieldList, default=nFields, prompt='Select blue image channel field:', $
                             uvalue='fblue', /auto)
                             
    outBase   = widget_base(readBase, /row)
    fileBase  = widget_base(outBase, /column)
    dummy     = widget_outf(fileBase, prompt='Select the output directory ', /directory, $
                            uvalue='lasName', /auto)

    verBase   = widget_base(readBase, /row)
    dummy     = widget_pmenu(verBase, list=['Version 1.0','Version 1.1','Version 1.2'], default=2, prompt='Select LAS format:', $
                             uvalue='format', /auto)

    dummy     = widget_map(readBase, default_map=[0,0], uvalue='proj', /auto_manage)

result = auto_wid_mng(readBase)
if (result.accept eq 0) then return

nHeader = result.nHeader
fEast   = result.fEast
fNorth  = result.fNorth
fElev   = result.fElev
fInten  = result.fInten
fClass  = result.fClass
fTime   = result.fTime
fReturn = result.fReturn
;fnReturn = result.fnReturn
;fAngle  = result.fAngle
;fScanDir  = result.fScanDir
;fLine   = result.fLine
fuserdata   = result.fuserdata
fptsrc   = result.fptsrc
fred   = result.fred
fgreen   = result.fgreen
fblue   = result.fblue

outputDir    = result.lasName
versionMinor = result.format
proj         = result.proj.proj

if (fTime eq nFields) and (fred eq nFields) then pointFormat = 0 
if (fTime ne nFields) and (fred eq nFields) then pointFormat = 1
if (fTime eq nFields) and (fred ne nFields) then pointFormat = 2
if (fTime ne nFields) and (fred ne nFields) then pointFormat = 3

    ; Convert the projection to variable length records

records = RecordsToProj_BCAL(proj, /reverse)

    ; Set the scale based on the projection

case proj.units of

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

    ; Create header structure, variable records, and data structure

header = InitHeaderLAS_BCAL()
data   = InitDataLAS_BCAL(pointFormat=pointFormat)

header.versionMinor = versionMinor
header.systemID     = byte('Ascii Conversion')
header.pointFormat  = pointFormat

    ; Set scaling and offsets

header.xScale = scale
header.yScale = scale
header.zScale = 1d-5

header.xOffset = 0D
header.yOffset = 0D
header.zOffset = 0D

    ; Set the chunking size

chunkSize = 1d5

    ; Begin processing files

for a=0,nFiles-1 do begin

        ; Determine number of points in the ascii file and the number of chunks

    header.nPoints = file_lines(inputFiles[a]) - nHeader

    nChunks  = ceil(header.nPoints / chunkSize)
    leftSize = header.nPoints - chunkSize * (nChunks - 1)

        ; Initialize the output file

    outputFile = outputDir + '\' + (strsplit(file_basename(inputFiles[a]), '.', /extract))[0] + '.las'

    WriteLAS_BCAL, outputFile, header, records=records, /nodata, /check

        ; Initialize parameters

    header.xMin = 10e6
    header.yMin = 10e6
    header.zMin = 10e6

    header.xMax = -10e6
    header.yMax = -10e6
    header.zMax = -10e6

        ; Update the status window

    statBase = widget_auto_base(title='Converting Ascii Data')
    statText = ['Converting: ', file_basename(inputFiles[a]), $
                'File' + strcompress(a+1) + ' of' + strcompress(n_elements(inputFiles))]
    envi_report_init, statText, base=statBase, /interrupt, title='Converting'
    envi_report_inc,  statBase, nChunks

        ; Open the output file for appending the data

    openw, outputLun, outputFile, /get_lun, /swap_if_big_endian, /append

        ; Open the Ascii file

    openr, inputLun, inputFiles[a], /get_lun
    if nHeader then skip_lun, inputLun, nHeader, /lines

        ; Read the Ascii file line by line

    for b=0L,nChunks-1 do begin

        if b eq (nChunks-1) then tempSize = leftSize  - 1  $
                            else tempSize = chunkSize - 1

        for c=0L,tempSize do begin

            dataTemp = ''
            readf, inputLun, dataTemp
            dataTemp = strsplit(dataTemp, ' ,;', /extract)

            data.east  = dataTemp[fEast]  / header.xScale - header.xOffset
            data.north = dataTemp[fNorth] / header.yScale - header.yOffset
            data.elev  = dataTemp[fElev]  / header.zScale - header.zOffset

            if fInten ne nFields then data.inten = dataTemp[fInten]
            if fTime  ne nFields then data.time  = dataTemp[fTime]
;            if fnReturn ne nFields then data.nReturn = dataTemp[fAngle]
;            if fAngle ne nFields then data.angle = dataTemp[fAngle]
;            if fLine  ne nFields then data.user  = dataTemp[fLine]
            if fClass ne nFields then data.class  = dataTemp[fClass]
            if fuserdata ne nFields then data.user  = dataTemp[fuserdata]
            if fred   ne nFields then data.red  = dataTemp[fred]
            if fgreen ne nFields then data.green  = dataTemp[fgreen]
            if fblue  ne nFields then data.blue  = dataTemp[fblue]
         

            if fReturn ne nFields then begin
                data.nReturn = dataTemp[fReturn]
                if fReturn and fReturn le 5 then header.nReturns[dataTemp[fReturn]-1]++
            endif else begin
                data.nReturn = fileReturn[a]
                if fileReturn[a] and fileReturn[a] le 5 then header.nReturns[fileReturn[a]-1]++
            endelse

            writeu, outputLun, data

            header.xMin <= dataTemp[fEast]
            header.xMax >= dataTemp[fEast]
            header.yMin <= dataTemp[fNorth]
            header.yMax >= dataTemp[fnorth]
            header.zMin <= dataTemp[fElev]
            header.zMax >= dataTemp[fElev]

        endfor

        envi_report_stat, statBase, b, nChunks, cancel=cancel
        if cancel then begin
            envi_report_init, base=statBase, /finish
            close, /all
            return
        endif

    endfor

    envi_report_init, base=statBase, /finish

    free_lun, inputLun

        ; Update the output file header

    point_lun, outputLun, 0
    writeu,    outputLun, header
    free_lun,  outputLun

endfor


end

