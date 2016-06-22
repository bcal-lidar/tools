;+
; NAME:
;
;       FlightlineLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to extract separate LAS files for each flight line from 
;       time information of input LAS file(s).
;
; PRODUCTS:
;
;       The output is one LAS file for each flight lines, containing all the information 
;       on the input LAS file.  The output files are stored in the specified output directory
;       with file names as Line_1, Line_2, and so on.
;
; AUTHOR:
;
;       David Streutker
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://geology.isu.edu/
;
; DEPENDENCIES:
;
;       ReadHeaderLAS_BCAL.pro
;       InitHeaderLAS_BCAL.pro
;       ReadLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2007.
;       Fixed bugs related to cases when 'dIndex' fails to create array, 
;         and added progress bar, April 2010 (Rupesh Shrestha)
;       Fixed bugs related to get_lun when there are more than 100 
;         flightlines, June 2010 (Rupesh Shrestha)
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
    
pro FlightlineLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish an error handler
;
catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file')
    return
endif

    ; Get the input files

inputFiles = envi_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files)
    if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Check to make sure that the input files include time information.  If not, quit.

pFormat = 0
for a=0,nFiles-1 do begin

    ReadHeaderLAS_BCAL, inputFiles[a], header
    
    pFormat >= header.pointFormat
    
endfor

if pFormat eq 0 then begin
    dummy = dialog_message('None of the data files appear to have the neccessary information.  Ending...', /error)
    return
endif

    ; Get the output directory

readBase = widget_auto_base(title='Directory Selection')

outputField = widget_outf(readBase, prompt='Select output flightline directory', /directory, $
                              uvalue='dirName', /auto_manage)

result = auto_wid_mng(readBase)
if (result.accept eq 0) then return

outputDir = result.dirName

  ; Update the status window

statBase = widget_auto_base(title='Extracting flight lines')
statText = ['Extracting flight lines..']
envi_report_init, statText, base=statBase, /interrupt, title='extracting'
envi_report_inc,  statBase, nFiles
    
    ; Read the input data files for time information
    
for b=0,nFiles-1 do begin
    
    ReadLAS_BCAL, inputFiles[b], header, data

        ; Get the min and max time values and make the histogram

    if b eq 0 then begin

        tMin = floor(min(data.time))
        tMax =  ceil(max(data.time))

        tRange = tMax - tMin

        tHist = histogram(data.time, min=tMin)

    endif else begin

        minTemp = tMin
        maxTemp = tMax

        rangeTemp = tRange

        tMin <= floor(min(data.time))
        tMax >=  ceil(max(data.time))

        tRange = tMax - tMin

        histTemp = lonarr(tRange)

        histTemp[(minTemp-tMin):(minTemp-tMin)+rangeTemp-1] = tHist

        tHist = histogram(data.time, min=tMin, input=histTemp)

    endelse
   
    envi_report_stat, statBase, b, nFiles, cancel=cancel
        if cancel then begin
            envi_report_init, base=statBase, /finish
            close, /all
            return
        endif
endfor

    ; Record breaks in the time histogram

tLine = ([0,tHist[0:tRange-2]] eq 0) and (tHist[0:tRange-1] ne 0)

    ; Make break numbers cumulative (thereby converting to flightline numbers)

nLines = total(tLine, /integer)
tLine  = total(tLine, /cumulative, /integer)

    ; Initialize the output header structure

tempHeader = InitHeaderLAS_BCAL()

tempHeader.systemID    = byte('Conversion')
tempHeader.pointFormat = 1
tempHeader.pointLength = 28

tempHeader.xMin = 10e6
tempHeader.yMin = 10e6
tempHeader.zMin = 10e6

    ; Set scaling

tempHeader.xScale = 0.01D
tempHeader.yScale = 0.01D
tempHeader.zScale = 0.01D

    ; Create array of output headers for every flightline

outHeaders = replicate(tempHeader, nLines)

    ; Initialize individual flightline files

for f=1,nLines do begin

    outputFile = outputDir + '\Line_' + strcompress(f,/remove) + '.las'
    
    openw,  f, outputFile
    writeu, f, outHeaders[f-1]
;    close, f

endfor 

    ; Begin processing the input files

for c=0,nFiles-1 do begin
    
    ReadLAS_BCAL, inputFiles[c], header, data
    
    envi_report_stat, statBase, c, nFiles, cancel=cancel
      if cancel then begin
         envi_report_init, base=statBase, /finish
         close, /all
         return
      endif
         
        
    tempHist = histogram(data.time, min=tMin, reverse_indices=tIndex)
       
    for d=0,n_elements(tempHist)-1 do begin

        if tempHist[d] then begin

                ; Get data from input file that corresponds to the flightline

            dIndex = tIndex[tIndex[d]:tIndex[d+1]-1]

                ; Update header files

            fIndex = tLine[d] - 1

            outHeaders[fIndex].nPoints  += tempHist[d]
            
            if n_elements(dIndex) gt 1 then begin
              outHeaders[fIndex].nReturns += histogram((data[dIndex].nReturn mod 8), min=1, max=5)
            endif
            
            outHeaders[fIndex].xMin <= min(data[dIndex].east)  * header.xScale + header.xOffset
            outHeaders[fIndex].yMin <= min(data[dIndex].north) * header.yScale + header.yOffset
            outHeaders[fIndex].zMin <= min(data[dIndex].elev)  * header.zScale + header.zOffset
            outHeaders[fIndex].xMax >= max(data[dIndex].east)  * header.xScale + header.xOffset
            outHeaders[fIndex].yMax >= max(data[dIndex].north) * header.yScale + header.yOffset
            outHeaders[fIndex].zMax >= max(data[dIndex].elev)  * header.zScale + header.zOffset
 
               ; Write the data to the output file
               
            writeu, fIndex+1, data[dIndex]

        endif

    endfor
endfor
close, /all


for s=1, nLines do begin

    outputFile = outputDir + '\Line_' + strcompress(s,/remove) + '.las'

        ; Update file headers

    openu,     s, outputFile
    point_lun, s, 0
    writeu,    s, outHeaders[s-1]
    free_lun,  s
    close,     s

        ; Delete any empty files

    if outHeaders[s-1].nPoints lt 10 then file_delete, outputFile

endfor
envi_report_init, base=statBase, /finish
 
end