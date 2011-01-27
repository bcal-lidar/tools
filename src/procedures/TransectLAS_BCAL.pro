
;+
; NAME:
;
;       TransectLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to create elevation profiles along one or more transects.
;       The transects are read from a pre-existing, user created EVF file.  The profiles are created
;       directly from the raw LAS point data.  A bare earth profile is optional, but requires that
;       the data has been filtered to calculate vegetation heights through the HeightLAS.pro program.
;
; PRODUCTS:
;
;       The profiles are graphed in one or more windows (one window for each transect) and the data
;       are output to one or more text files (one file for each transect).  The output data include
;       the X, Y, and Z coordinates of each profile point, as well as the distance of each point along
;       the transect and, if requested, the bare earth elevation of each point.
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
;       Written by David Streutker, November 2006.
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

    ; Compile the line intersection function

function Intersect_BCAL, pair1, pair2

        ; Set the tolerance value

    epsilon = 1d-3

    pair1 = double(pair1)
    pair2 = double(pair2)

        ; Assumes coord arrays are [2,2] ([2,n])

    out = -1

        ; Find the solutions for Ax + By = C for each segment

    a1 = pair1[1,1] - pair1[1,0]        ; y2 - y1
    b1 = pair1[0,0] - pair1[0,1]        ; x1 - x2
    c1 = pair1[0,0] * pair1[1,1] $      ; x1*y2 - x2*y1
       - pair1[0,1] * pair1[1,0]

    a2 = pair2[1,1] - pair2[1,0]        ; y2 - y1
    b2 = pair2[0,0] - pair2[0,1]        ; x1 - x2
    c2 = pair2[0,0] * pair2[1,1] $      ; x1*y2 - x2*y1
       - pair2[0,1] * pair2[1,0]

        ; Compute the determinant.  If it is nonzero, then solve for the intersection point

    det = a1 * b2 - b1 * a2

    if det ne 0 then begin

        x = (b2 * c1 - c2 * b1) / det
        y = (a1 * c2 - c1 * a2) / det

            ; Check to see if the intersection point lines between the endpoints.
            ; (Endpoints are included.)

        if (x + epsilon) ge (min(pair1[0,*]) > min(pair2[0,*])) and $
           (x - epsilon) le (max(pair1[0,*]) < max(pair2[0,*])) and $
           (y + epsilon) ge (min(pair1[1,*]) > min(pair2[1,*])) and $
           (y - epsilon) le (max(pair1[1,*]) < max(pair2[1,*])) then out = [x,y]

    endif

return, out

end


    ; Begin main program

pro TransectLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error creating file')
    return
endif

    ; Get the input file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Get the files and parameters from the user

readBase = widget_auto_base(title='Select Transect Files')

    dummy = widget_outf(readBase, prompt='Select EVF File', uvalue='vecName', /auto)

    buffBase = widget_base(readBase, /row)
    dummy = widget_param(buffBase, default=2.0, dt=4, floor=0, prompt='Set Buffer Size: ', uvalue='buffer', /auto)

    dummy = widget_menu(readBase, default_array=[0], list=['Include Bare Earth Transect?'],   uvalue='bare', /auto)

    dummy = widget_outf(readBase, prompt='Select Output File', default='transect.txt', uvalue='outName', /auto)

result = auto_wid_mng(readBase)
if result.accept eq 0 then return

vectorFile = result.vecName
outputName = result.outName

doBare = result.bare[0]

r = result.buffer

    ; Open the vector file and determine the number of transects (records).  Set up various pointer arrays.

vectorID = envi_evf_open(vectorFile)
envi_evf_info, vectorID, num_recs=nRecs, proj=evfProj

if nRecs eq 0 then begin
    dummy = dialog_message('The EVF file contains no vectors.', /error)
    return
endif

nCoords = lonarr(nRecs)
xCoords = ptrarr(nRecs, /allocate_heap)
yCoords = ptrarr(nRecs, /allocate_heap)
lenArr  = ptrarr(nRecs, /allocate_heap)

oBounds = objarr(nRecs)

xData   = ptrarr(nRecs, /allocate_heap)
yData   = ptrarr(nRecs, /allocate_heap)
zData   = ptrarr(nRecs, /allocate_heap)
eData   = ptrarr(nRecs, /allocate_heap)

    ; Begin processing each record of the vector file

for m=0,nRecs-1 do begin

        ; Get the vector coordinates

    tempCoords = envi_evf_read_record(vectorID, m)

    nCoords[m] = (size(tempCoords, /dim))[1]

   *xCoords[m] = reform(tempCoords[0,*])
   *yCoords[m] = reform(tempCoords[1,*])

        ; Calculate the lengths of the individual segments and related products

    dx = (*xCoords[m])[1:nCoords[m]-1] - (*xCoords[m])[0:nCoords[m]-2]
    dy = (*yCoords[m])[1:nCoords[m]-1] - (*yCoords[m])[0:nCoords[m]-2]

   *lenArr[m] = sqrt(dx^2 + dy^2)

    rSinPhi = r * dy / *lenArr[m]
    rCosPhi = r * dx / *lenArr[m]

        ; Create object that will contain the segement boundaries

    oBounds[m] = obj_new('IDLanROIGroup')

        ; For each segement of the transect, calculate and save the bounding box

    for n=0,nCoords[m]-2 do begin

        bounds = [[(*xCoords[m])[n]   - rCosPhi[n] - rSinPhi[n],  $
                   (*yCoords[m])[n]   - rSinPhi[n] + rCosPhi[n]], $

                  [(*xCoords[m])[n]   - rCosPhi[n] + rSinPhi[n],  $
                   (*yCoords[m])[n]   - rSinPhi[n] - rCosPhi[n]], $

                  [(*xCoords[m])[n+1] + rCosPhi[n] + rSinPhi[n],  $
                   (*yCoords[m])[n+1] + rSinPhi[n] - rCosPhi[n]], $

                  [(*xCoords[m])[n+1] + rCosPhi[n] - rSinPhi[n],  $
                   (*yCoords[m])[n+1] + rSinPhi[n] + rCosPhi[n]], $

                  [(*xCoords[m])[n]   - rCosPhi[n] - rSinPhi[n],  $
                   (*yCoords[m])[n]   - rSinPhi[n] + rCosPhi[n]]]

        oBounds[m]->Add, obj_new('IDLanROI', bounds)

    endfor

        ; Initialize the point data arrays

   *xData[m] = -1D
   *yData[m] = -1D
   *zData[m] = -1D
   *eData[m] = -1D

endfor

envi_evf_close, vectorID

    ; Set up status message window

statText  = 'Initializing'
statBase  = widget_auto_base(title='Transect Status')
statField = widget_text(statBase, /scroll, value=statText, xsize=80, ysize=4)
widget_control, statBase, /realize

    ; Begin accessing the data, file by file

for a=0,nFiles-1 do begin

        ; Read the lidar file header and determine if the file data falls
        ; within the area of the vector.  If so, proceed.

    ReadLAS_BCAL, inputFiles[a], header, /nodata

    doRead = 0

    for b=0,nRecs-1 do begin

        if header.xMin le max(*xCoords[b]) and header.xMax ge min(*xCoords[b]) and $
           header.yMin le max(*yCoords[b]) and header.yMax ge min(*yCoords[b]) then doRead = 1

    endfor

    if doRead then begin

        statText = ['Reading ' + inputFiles[a], statText]
        widget_control, statField, set_value=statText

            ; Read the data file.

        ReadLAS_BCAL, inputFiles[a], header, pData, projection=lasProj

            ; Compare the projections of the EVF and LAS files

;        if n_tags(lasProj) then

            ; Find and save the points that lie within the buffer boxes

        for c=0,nRecs-1 do begin

            statText = ['Locating Points: Transect' + strcompress(c+1), statText]
            widget_control, statField, set_value=statText

            oBounds[c]->GetProperty, ROIGroup_xRange=xRange, ROIGroup_yRange=yRange

            xRange = (xRange - header.xOffset) / header.xScale
            yRange = (yRange - header.yOffset) / header.yScale

            inside = where(pData.east ge xRange[0] and pData.north ge yRange[0] and $
                           pData.east le xRange[1] and pData.north le yRange[1], inCount)

            if inCount then begin

                good = where(oBounds[c]->ContainsPoints(pData[inside].east  * header.xScale + header.xOffset, $
                                                        pData[inside].north * header.yScale + header.yOffset), gCount)

                if gCount then begin

                   *xData[c] = [*xData[c], header.xOffset + header.xScale *  pData[inside[good]].east]
                   *yData[c] = [*yData[c], header.yOffset + header.yScale *  pData[inside[good]].north]
                   *zData[c] = [*zData[c], header.zOffset + header.zScale *  pData[inside[good]].elev]
                   *eData[c] = [*eData[c], header.zOffset + header.zScale * (pData[inside[good]].elev $
                                                                           - pData[inside[good]].source)]

                endif

            endif

        endfor

        pData = [0]

    endif

endfor

    ; Destroy the first status window

widget_control, statBase, /destroy

nTri   = lonarr(nRecs)
triArr = ptrarr(nRecs, /allocate_heap)

    ; Process each transect

for h=0,nRecs-1 do begin

        ; Open the status window

    statBase = widget_auto_base(title='Transect Status')
    statText = ['Computing: Transect' + strcompress(h+1)]
    envi_report_init, statText, base=statBase, /interrupt, title='Transect Status'
    envi_report_inc,  statBase, nCoords[h]

        ; Make sure an adequate number of points were found.  If not, give an error

    if n_elements(*zData[h]) lt 3 then dummy = dialog_message('There are not enough points near Transect' $
                                                             + strcompress(h+1) + ' to compute a profile.', /error) $

    else begin

            ; Make sure the data points are unique, and triangulate them

        grid_input, (*xData[h])[1:*], (*yData[h])[1:*], (*zData[h])[1:*], xTemp, yTemp, zTemp, duplicates='min', epsilon=0.005
        grid_input, (*xData[h])[1:*], (*yData[h])[1:*], (*eData[h])[1:*], xTemp, yTemp, eTemp, duplicates='min', epsilon=0.005

        triangulate, xTemp, yTemp, triTemp

       *triArr[h]  = [triTemp,triTemp[0,*]]
        nTri[h]    = (size(triTemp, /dim))[1]

       *xData[h] = xTemp
       *yData[h] = yTemp
       *zData[h] = zTemp
       *eData[h] = eTemp

        transect = make_array(1, 5, /double, value=-1)

            ; Iterate through each segment of the transect

        for i=0,nCoords[h]-2 do begin

                ; Iterate through each segment of each triangle

            for j=0,nTri[h]-1 do begin
            for k=0,2         do begin

                    ; Check for intersection of the transect segment with the triangle segment

                pair1 = transpose([[(*xCoords[h])[i], (*xCoords[h])[i+1]], $
                                   [(*yCoords[h])[i], (*yCoords[h])[i+1]]])

                pair2 = transpose([[(*xData[h])[(*triArr[h])[k,j]], (*xData[h])[(*triArr[h])[k+1,j]]], $
                                   [(*yData[h])[(*triArr[h])[k,j]], (*yData[h])[(*triArr[h])[k+1,j]]]])

                int = Intersect_BCAL(pair1, pair2)

                    ; If there is an intersection, calculate the z-value and bare elevation at that point

                if n_elements(int) ne 1 then begin

                    xDiff = (*xData[h])[(*triArr[h])[k+1,j]] - (*xData[h])[(*triArr[h])[k,j]]
                    yDiff = (*yData[h])[(*triArr[h])[k+1,j]] - (*yData[h])[(*triArr[h])[k,j]]
                    zDiff = (*zData[h])[(*triArr[h])[k+1,j]] - (*zData[h])[(*triArr[h])[k,j]]
                    eDiff = (*eData[h])[(*triArr[h])[k+1,j]] - (*eData[h])[(*triArr[h])[k,j]]

                    xPart = int[0] - (*xData[h])[(*triArr[h])[k,j]]
                    yPart = int[1] - (*yData[h])[(*triArr[h])[k,j]]

                    rDiff = sqrt(xDiff^2 + yDiff^2)
                    rPart = sqrt(xPart^2 + yPart^2)

                    zNew  = (*zData[h])[(*triArr[h])[k,j]] + zDiff * rPart / rDiff
                    eNew  = (*eData[h])[(*triArr[h])[k,j]] + eDiff * rPart / rDiff

                        ; Calculate the distance of the point from the start of the transect

                    rDist = total((*lenArr[h])[0:i]) - (*lenArr[h])[i] + $
                             sqrt((int[0] - (*xCoords[h])[i])^2 + (int[1] - (*yCoords[h])[i])^2)

                        ; Save the intersection location

                    transect = [transect, transpose([int[0], int[1], rDist, zNew, eNew])]

                endif

            endfor
            endfor

            envi_report_stat, statBase, i, nCoords[h], cancel=cancel
            if cancel then begin
                envi_report_init, base=statBase, /finish
                return
            endif

        endfor

            ; Get rid of the first point placeholder

        transect = transect[1:*,*]
        transect = transpose(transect)

            ; Sort by distance along the transect

        sorted   = uniq(transect[2,*], sort(transect[2,*]))
        transect = transect[*,sorted]

            ; Create the filename

        if nRecs eq 1 then outputFile = outputName $
                      else outputFile = file_dirname(outputName) + '\' + file_basename(outputName, '.txt') $
                                      + '_' + strcompress(h+1, /remove) + '.txt'

            ; Plot the transect profile and save the data to a text file

        if doBare then begin

            envi_plot_data, transect[2,*], transpose(transect[3:4,*]), $
                plot_names=['Lidar Transect','Bare Earth Transect'], plot_title='Transect' + strcompress(h+1), $
                xtitle='Distance Along Transect (m)', ytitle='Elevation (m)', title='Transect' + strcompress(h+1)

            openw,    outLun, outputFile, /get_lun
            printf,   outLun, 'X location, Y location, Transect distance, LiDAR elev, Bare earth elev'
            printf,   outLun, transect, format='(5f15.3)'
            free_lun, outLun

        endif else begin

            envi_plot_data, transect[2,*], transpose(transect[3,*]), $
                plot_names=['Lidar Transect'], plot_title='Transect' + strcompress(h+1), $
                xtitle='Distance Along Transect (m)', ytitle='Elevation (m)', title='Transect' + strcompress(h+1)

            openw,    outLun, outputFile, /get_lun
            printf,   outLun, 'X location, Y location, Transect distance, LiDAR elev'
            printf,   outLun, transect[0:3,*], format='(4f15.3)'
            free_lun, outLun

        endelse

    endelse

    envi_report_init, base=statBase, /finish

endfor

    ; Clean up

obj_destroy, oBounds
ptr_free, xCoords, yCoords, lenArr
ptr_free, xData, yData, zData, eData, triArr


end


