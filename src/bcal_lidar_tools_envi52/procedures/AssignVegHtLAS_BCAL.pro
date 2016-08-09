;+
; NAME:
;
;       AssignVegHtLAS_BCAL
;
; PURPOSE:
;
;       Basically the same as AssignVegHt_ui
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;       GetIndex_BCAL.pro
;       WriteLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Implemented by Exelis VIS, April 2016.
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


; Begin main program

pro AssignVegHtLAS_BCAL, event

  compile_opt idl2, logical_predicate

  ; Establish an error handler.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file', /center)
    return
endif


doProfile = 0

    ; Get the input file(s).
inputFiles = envi_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files)
if (inputFiles[0] eq '') then return

outputDir = envi_pickfile(title='Select output directory', /directory)
if outputDir eq '' then return
              
baseScale   = 5

    ; Set up interpolation parameters for GRIDDATA

interpFunct  = 0
interpPower  = 0
interpMin    = 15
interpMethod = 'NaturalNeighbor'
interpMax    = 0

    ; Set up intial parameters.

startTime = systime(/seconds)
noHeight  = 2^16 - 1

iterMax = 15

     ; Begin processesing each file

for a=0,n_elements(inputFiles)-1 do begin

        ; Set up the profiler

    if doProfile then begin

        profiler, /reset
        profiler, /system
        profiler

    endif

        ; Establish the status reporting widget.  This will report the processing status
        ; for each data file.

    statBase = widget_auto_base(title='Assigning')
    statText = ['Assigning Progress:', file_basename(inputFiles[a]), $
      'File' + strcompress(a+1) + ' of' + strcompress(n_elements(inputFiles))]
    envi_report_init, statText, base=statBase, /interrupt, title='Assigning...'


        ; Read the input data file.

    ReadLAS_BCAL, inputFiles[a], header, pData, records=records
        
        ; Set all heights to noHeight, classifications to 0 (never classified)

    pData.source = noHeight

        ; Determine the dimensions of the processing grid.

    xDim = ceil((header.xMax - header.xMin) / baseScale) + 1
    yDim = ceil((header.yMax - header.yMin) / baseScale) + 1

    envi_report_inc,  statBase, yDim*iterMax

        ; Create the data index.  The point data are referenced using 'index chunking', which
        ; is determined by the dimensions of the processing grid. Only the data whose return number
        ; has been requested are indexed.

    arrayHist = histogram(floor((header.yOffset - header.yMin + pData.north * header.yScale) / baseScale) * xDim $
                        + floor((header.xOffset - header.xMin + pData.east  * header.xScale) / baseScale), $
                        reverse_indices=arrayIndex, min=0d, max=xDim*yDim)

        ; Set up counter which records the number of iterations for each cell.  If the count number
        ; is greater than the current iteration, that cell requires further filtering.  Empty cells
        ; require no (0) iterations.  All occupied cells are assumed to require initialization (1) and
        ; the first filtering (2).

    cellCount = (arrayHist ge 1) * 2

        ; For each cell of the processing grid, given adequate number of points,
        ; find point of minimum elevation and label it as ground (class = 2) and
        ; set the height (source) to 0. This is the initialization, or iteration 1.

    for b=0L,xDim*yDim-1 do begin

         if arrayHist[b] ge 1 then begin
         
            index = arrayIndex[arrayIndex[b]:arrayIndex[b+1]-1]
            
            tempLow = where(pData[index].class eq 2, tempCount, complement=vegLow)
            
            pData[index].source = 0
            pData[index[veglow]].class = 0

                ; If all the points are classified as ground, no further iterations are
                ; needed, and the cell iteration count is set back to 1.

            if tempCount eq arrayHist[b] then cellCount[b] = 1

        endif

    endfor

    envi_report_stat, statBase, yDim, yDim*iterMax, cancel=cancel

        ; Iterate over the entire array, cell by cell

    nIter = 1

;    repeat begin

        nIter++

            ; Begin filtering the data, one cell at a time for the entire processing grid.

        j = 0L

        for g=0L,yDim-1 do begin
        for f=0L,xDim-1 do begin

                ; Check to see if the grid cell requires filtering.

            if cellCount[j] gt 1 then begin

                    ; Get the points in the cell.  Determine which points are non-ground.

                index = arrayIndex[arrayIndex[j]:arrayIndex[j+1]-1]
                index = index[where(pData[index].class ne 2)]

                    ; Get ground points in surrounding cells.  Iterate using GetIndex_BCAL until at least
                    ; six points are found.

                factor = 1
                repeat begin
                    surround  = GetIndex_BCAL(f,g,xDim,yDim,arrayIndex,factor++)
                    surrIndex = where(pData[surround].class eq 2, surrCount)
                endrep until (surrCount ge interpMin)
                surround = surround[surrIndex]

                    ; Using the surrounding ground points, interpolate the ground surface at the
                    ; locations of the non-ground points.

                triangulate, pData[surround].east, pData[surround].north, triangles
                interpLocal = griddata(pData[surround].east, pData[surround].north, $
                                       pData[surround].elev, triangles=triangles, method=interpMethod, $
                                       function_type=interpFunct, power=interpPower, missing=noHeight, $
                                       max_per_sector=interpMax, $
                                       xout=[pData[index].east], yout=[pData[index].north])

                        ; Determine the vegetation heights of the non-ground points and check
                        ; for negative heights.

                 heights = pData[index].elev - interpLocal
                    
                 pData[index].class  = 3
                 pData[index].source = round(heights)

                 low     = where(heights lt 0, lowCount);, complement=high, ncomplement=highCount)

                        ; Proceed based on whether or not some interpolated points have non-positive values

                 if lowCount then begin
;
;                            ; If some positive heights exist, reclassify points with zero or negative heights
;                            ; as ground points and increase the cell count number, invoking further iteration.
;                            ; If all points in the cell have zero or negative height (signified by
;                            ; highCount equaling zero), record the height and classify as bare ground.
;
                             pData[index[low]].source = noHeight
                             pData[index[low]].class  = 1

                 endif

            endif

            j++

        endfor

        envi_report_stat, statBase, g + yDim*nIter, yDim*iterMax, cancel=cancel
        if cancel then begin
            envi_report_init, base=statBase, /finish
            return
        endif

        endfor

        envi_report_stat, statBase, yDim*iterMax, yDim*iterMax, cancel=cancel

        ; Write the header and data to a new file in the output directory

    outputFile = outputDir + path_sep() + file_basename(inputFiles[a])
    WriteLAS_BCAL, outputFile, header, pData, records=records, /check
    
        ; Clear up some memory

    pData      = 0B
    arrayHist  = 0B
    arrayIndex = 0B
    cellCount  = 0B

    envi_report_init, base=statBase, /finish

        ; Write the profile report

    if doProfile then begin

        profiler, /report, output=profOut

        openw,    proLun, outputDir + file_basename(inputFiles[a], '.las') + '.txt', /get_lun, width=250
        printf,   proLun, transpose(profOut)
        free_lun, proLun

    endif

endfor

end




