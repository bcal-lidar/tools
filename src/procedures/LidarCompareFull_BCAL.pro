;+
; NAME:
;
;       LidarCompareFull_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to shift LAS files using slope-based matching method. It can shift a single 
;       LAS file based on another base LAS file(s).
;
; PRODUCTS:
;
;       The output is shifted LAS file.  The output files are stored in the specified output directory
;       with the same file name as original file. Displays curves and also outputs in the same directory 
;       a text file with notes on parameter settings.
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
;       ReadLAS_BCAL.pro
;       GetBounds_BCAL.pro
;       GetIndex_BCAL.pro
;       WriteLAS_BCAL.pro
;       RegressPoly.pro
;       TransformData.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2007.
;       Fixed bugs, change interface, etc. April 2010 (Rupesh Shrestha)
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

pro LidarCompareFull_BCAL, event

compile_opt idl2, logical_predicate

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    return
endif

seed = systime(/seconds) mod 1000

    ; Get the base file(s)

baseFiles = dialog_pickfile(title='Select base file(s)', filter='*.las', /multiple_files, /path)
if baseFiles[0] eq '' then return

    ; Get the input files and match parameters

readBase = widget_auto_base(title='Comparison Parameters')

    shiftField = widget_outf(readBase, prompt='Select LAS file to be shifted:', uvalue='shiftName', /auto_manage)

    dummy = widget_menu(readBase, default_array=[0], list=['Use vector mask(s)?'],    uvalue='mask', /auto)
    dummy = widget_menu(readBase, default_array=[1], list=['Iterate automatically?'], uvalue='iter', /auto)
    
    xbase = widget_base(readBase, /row)
    dummy = widget_param(xBase, default=2, dt=2, floor=0, $
                         prompt='Select polynomial warping order in X: ', uvalue='xPoly', /auto_manage)
    
    ybase = widget_base(readBase, /row)
    dummy = widget_param(yBase, default=2, dt=2, floor=0, $
                         prompt='Select polynomial warping order in Y: ', uvalue='yPoly', /auto_manage)
    
    zbase = widget_base(readBase, /row)
    dummy = widget_param(zBase, default=2, dt=2, floor=0, $
                         prompt='Select polynomial warping order in Z: ', uvalue='zPoly', /auto_manage)

    dummy = widget_menu(readBase, default_array=[1], list=['Use cross terms?'], uvalue='cross', /auto)

    comparebase = widget_base(readBase, /row)
    dummy = widget_param(compareBase, ceil=100, default=3, dt=5, floor=1, $
                         prompt='Select comparison scale (m)', uvalue='grid', /auto_manage)

;    dummy = widget_edit(readBase, dt=5, field=2, list=['X shift:','Y shift:','Z shift:'], vals=[-85,200,0], $
    dummy = widget_edit(readBase, dt=5, field=2, list=['X shift:','Y shift:','Z shift:'], vals=[0,0,0], $
                        prompt='Set initial shift values (m)', ysize=3, uvalue='guess', /auto_manage)

    dummy = widget_outf(readBase, /directory, prompt='Select output directory', uvalue='outDir', /auto)
    
result = auto_wid_mng(readBase)
if result.accept eq 0 then return

shiftFile = result.shiftName
doMask    = result.mask
doIter    = result.iter
xPoly     = fix(result.xPoly)
yPoly     = fix(result.yPoly)
zPoly     = fix(result.zPoly)
doCross   = result.cross

grid = result.grid

xShift = result.guess[0]
yShift = result.guess[1]
zShift = result.guess[2]

outputDir = result.outDir

    ; Open a documentation file, initialize documentation arrays

openw, docLun, outputDir + '\notes.txt', /get_lun
printf, docLun, 'Date Processed: ', systime()
printf, docLun, 'Degree of Warping:', strcompress(fix([xPoly,yPoly,zPoly]))
printf, docLun, 'Cross Terms:', doCross
;printf, docLun, 'Target Accuracy:', tAcc
printf, docLun, 'Initial Shift:', strcompress([xShift,yShift,zShift])
printf, docLun, ' '

    ; If requested, get the mask vectors

oMask = Obj_New('IDLanROIGroup')
if doMask then begin

    maskFiles = dialog_pickfile(title='Select mask file(s)', filter='*.evf', /multiple_files, /path)

    if (maskFiles[0] eq '') then begin
        doMask = 0
        return
    endif
       
    for v=0,n_elements(maskFiles)-1 do begin

        maskID = envi_evf_open(maskFiles[v])
        envi_evf_info, maskID, num_recs=nRecs

        for w=0,nRecs-1 do begin

            maskCoords = envi_evf_read_record(maskID, w)
            oMask->Add, Obj_New('IDLanROI', maskCoords)

        endfor

        envi_evf_close, maskID

        printf, docLun, 'Maskfile File:    ' + maskFiles[v]
        
    endfor

endif

    ; Prepare for reading the shift points

ReadLAS_BCAL, shiftFile, sHeader, sData

xMean = mean(sData.east)
yMean = mean(sData.north)
zMean = mean(sData.elev - sData.source)

printf, docLun, 'Shifted File: ' + shiftFile

    ; Perform the initial shift

sData.east  += xShift / sHeader.xScale
sData.north += yShift / sHeader.yScale
sData.elev  += zShift / sHeader.zScale

xMax = sHeader.xMax + xShift
xMin = sHeader.xMin + xShift
yMax = sHeader.yMax + yShift
yMin = sHeader.yMin + yShift
zMax = max(sData.elev - sData.source) * sHeader.zScale + sHeader.zOffset
zMin = min(sData.elev)                * sHeader.zScale + sHeader.zOffset

    ; Get the bounds of the file to be shifted

sBounds = GetBounds_BCAL(sData.east, sData.north, precision=5/sHeader.yScale)
sBounds = transpose([[sData[sBounds].east  * sHeader.xScale + sHeader.xOffset], $
                     [sData[sBounds].north * sHeader.yScale + sHeader.yOffset]])

oShift = Obj_New('IDLanROIGroup')
oShift->Add, Obj_New('IDLanROI', sBounds)

    ; Read the input files and determine their boundaries

nBase  = n_elements(baseFiles)
bIndex = ptrarr(nBase, /allocate_heap)
doBase = bytarr(nBase)

for a=0,nBase-1 do begin

    ReadHeaderLAS_BCAL, baseFiles[a], tempHeader
    
    printf, docLun, 'Base File:    ' + baseFiles[a]

    bBounds = transpose([[tempHeader.xMin, tempHeader.xMin, tempHeader.xMax, tempHeader.xMax, tempHeader.xMin], $
                         [tempHeader.yMin, tempHeader.yMax, tempHeader.yMax, tempHeader.yMin, tempHeader.yMin]])

    if Intersect(bBounds, sBounds) and (min(oMask->ContainsPoints(bBounds)) eq 0) then begin

        xMax >= tempHeader.xMax
        xMin <= tempHeader.xMin
        yMax >= tempHeader.yMax
        yMin <= tempHeader.yMin
;        zMax >= tempHeader.zMax
        zMin <= tempHeader.zMin

        doBase[a] = 1

    endif

endfor

if max(doBase) eq 0 then begin
    dummy = dialog_message('The base and input files do not overlap', /error)
    stop
endif

mDim = ceil((xMax - xMin) / grid)
nDim = ceil((yMax - yMin) / grid)

;window, 11, xs=700, ys=700
;
;    plot, findgen(10), findgen(10), /nodata, /iso, $
;        xrange=[xMin, xMax], xstyle=1, yrange=[yMin, yMax], ystyle=1
;
;    if doMask then begin
;        for o=0,oMask->Count()-1 do begin
;            oTemp = oMask->Get(position=o)
;            oTemp->GetProperty, data=maskCoords
;            plots, maskCoords[0,*], maskCoords[1,*], color=150
;        endfor
;    endif
;
;    plots, sBounds, color=250

for b=0,nBase-1 do begin

    ReadHeaderLAS_BCAL, baseFiles[b], tempHeader

    if doBase[b] then begin

        ReadLAS_BCAL, baseFiles[b], tempHeader, tempData

        baseHist = histogram(mDim * floor((tempData.north * tempHeader.yScale + (tempHeader.yOffset - yMin)) / grid) $
                                  + floor((tempData.east  * tempHeader.xScale + (tempHeader.xOffset - xMin)) / grid) $
                                  + mDim * nDim * (tempData.source gt (50 / tempHeader.zScale)), $
                             reverse_indices=baseIndex, min=0D, max=mDim*nDim-1)

        *bIndex[b] = baseIndex

        tempData  = 0B
        baseHist  = 0B
        baseIndex = 0B

;        plots, [tempHeader.xMin, tempHeader.xMin, tempHeader.xMax, tempHeader.xMax, tempHeader.xMin], $
;               [tempHeader.yMin, tempHeader.yMax, tempHeader.yMax, tempHeader.yMin, tempHeader.yMin], color=255

    endif

endfor

    ; Get the various geographic parameters

xMid = (xMin + xMax) / 2
yMid = (yMin + yMax) / 2
zMid = (zMin + zMax) / 2

xRange = xMax - xMin
yRange = yMax - yMin
zRange = zMax - zMin

nPoints = 1.5e5 < sHeader.nPoints

nIter     = 15
trackIter = -1

    ; Begin processing

repeat begin

    iterCount = 0

repeat begin

    k = long(randomu(seed,nPoints) * (sHeader.nPoints - 1))
    k = k[uniq(k, sort(k))]

        ; Transform the shifted points

    x = sHeader.xOffset - xMin + sHeader.xScale *  sData[k].east
    y = sHeader.yOffset - yMin + sHeader.yScale *  sData[k].north
;    z = sHeader.zOffset - zMin + sHeader.zScale *  sData[k].elev
    z = sHeader.zOffset - zMin + sHeader.zScale * (sData[k].elev - sData[k].source)

    good = where((x ge 0) and (x le xRange) and (y ge 0) and (y le yRange) and $
                 (oMask->ContainsPoints(x+xMin,y+yMin) eq 0) and $
                 (sData[k].source lt (50 / sHeader.zScale)), nGood)

    x = x[good]
    y = y[good]
    z = z[good]

    diffArray  = fltarr(nGood)   - 999
    slopeArray = fltarr(2,nGood) - 999

            ; Convert to the base coordinates and get the points in the base dataset that
            ; correspond to the shift point

    for d=0,nBase-1 do begin

        if doBase[d] then begin

            ReadLAS_BCAL, baseFiles[d], bHeader, /nodata

            local = where((x gt bHeader.xMin - xMin) and (x lt bHeader.xMax - xMin) and $
                          (y gt bHeader.yMin - yMin) and (y lt bHeader.yMax - yMin), nLocal)

            if nLocal then begin

                m = floor(x[local] / grid)
                n = floor(y[local] / grid)

                ReadLAS_BCAL, baseFiles[d], bHeader, bData

                for i=0,nLocal-1 do begin

                    index = GetIndex_BCAL(m[i], n[i], mDim, nDim, *bIndex[d], 1)

                    if n_elements(index) ge 8 then begin

                        near = (bData[index].east  * bHeader.xScale + (bHeader.xOffset - xMin - x[local[i]]))^2 $
                             + (bData[index].north * bHeader.yScale + (bHeader.yOffset - yMin - y[local[i]]))^2

                        index = index[uniq(near, sort(near))]
                        index = index[0:3]

                                ; Find the slope of the local base points

;                        plane = regress(transpose([[bData[index[0:3]].east  * bHeader.xScale + (bHeader.xOffset - xMin - x[local[i]])],$
;                                                   [bData[index[0:3]].north * bHeader.yScale + (bHeader.yOffset - yMin - y[local[i]])]]), $
;                                                  ((bData[index[0:3]].elev  - bData[index[0:3]].source) * bHeader.zScale + (bHeader.zOffset - zMin - z[local[i]])), $
;;                                                   (bData[index[0:3]].elev  * bHeader.zScale + (bHeader.zOffset - zMin - z[local[i]])), $
;                                                   const=tempDiff, status=stat)

                        plane = regress(transpose([[bData[index].east  * bHeader.xScale + (bHeader.xOffset - xMin - x[local[i]])],$
                                                   [bData[index].north * bHeader.yScale + (bHeader.yOffset - yMin - y[local[i]])]]), $
                                                  ((bData[index].elev  - bData[index].source) * bHeader.zScale + (bHeader.zOffset - zMin - z[local[i]])), $
;                                                   (bData[index].elev  * bHeader.zScale + (bHeader.zOffset - zMin - z[local[i]])), $
                                                   const=tempDiff, status=stat)

                        if (stat eq 0) and finite(tempDiff) then begin

                                ; Record the slope and aspect, and the vertical difference between the shifted
                                ; point as the base surface plane

                            diffArray[local[i]]    = -1 * tempDiff   ; diffArray is positive if the shifted point is above the base
                            slopeArray[*,local[i]] = reform(plane)

                        endif

                    endif

                endfor

                bData = 0B

            endif

        endif

    endfor

;    gCoord = where(diffArray ne -999)
    gCoord = where((diffArray gt -50) and (diffArray lt 50))

    x = x[gCoord]
    y = y[gCoord]
    z = z[gCoord]

    diffArray  = diffArray[gCoord]
    slopeArray = slopeArray[*,gCoord]

    diffHist  = histogram(diffArray, min=median(diffArray)-2*stddev(diffArray), $
                                     max=median(diffArray)+2*stddev(diffArray), nbins=300, loc=diffAxis)
    diffGauss = gaussfit(diffAxis, diffHist, diffCoeffs, nterms=3)

    slope = sqrt(total(slopeArray^2,1))

        ; Make arrays of the slope and aspect

;    slopeHist  = histogram(atan(slope) * !radeg, min=0, max=90, bin=0.5)
;    aspectHist = histogram(atan(slopeArray[0,*],slopeArray[1,*]) * !radeg $
;                            + ((slopeArray[0,*] lt 0) * 360), min=0, max=360)

        ; Get the vertical shift from areas that are nearly flat

;    flat  = where((atan(slope) * !radeg) lt 30)
;    steep = where((abs(slopeArray[0,*]) gt 0.05) and (abs(slopeArray[1,*]) gt 0.05))

;    flat  = where(slope le min(slope))
;    flat  = where(slope le 4*median(slope)) 
;    flat  = where(slope le 0.5)
    flat  = where(slope le 2*median(slope)) 
;    steep = where((abs(slopeArray[0,*]) ge 0.1*median(slope)) $
;              and (abs(slopeArray[1,*]) ge 0.1*median(slope)))
  steep = where((abs(slopeArray[0,*]) ge 0.5*median(slope)) $
              and (abs(slopeArray[1,*]) ge 0.5*median(slope)))

    zDiff = diffArray[flat]

        ; slope ->  5 degrees = 0.087
        ;          10 degrees = 0.176
        ;          15 degrees = 0.268
        ;          30 degrees = 0.577

        ; Use the steep areas to get the horizontal shift

    rDiff = -1 * (diffArray[steep] - mean(zDiff)) / slope[steep]
    xDiff = rDiff * slopeArray[0,steep] / slope[steep]
    yDiff = rDiff * slopeArray[1,steep] / slope[steep]

    xHist = histogram(xDiff, min=median(xDiff)-2*stddev(xDiff), max=median(xDiff)+2*stddev(xDiff), nbins=300, loc=xAxis)
    yHist = histogram(yDiff, min=median(yDiff)-2*stddev(yDiff), max=median(yDiff)+2*stddev(yDiff), nbins=300, loc=yAxis)
    zHist = histogram(zDiff, min=median(zDiff)-2*stddev(zDiff), max=median(zDiff)+2*stddev(zDiff), nbins=300, loc=zAxis)

        ; Fit the shift values to a gaussian in each dimension

    xGauss = gaussfit(xAxis, xHist, xCoeffs, nterms=3)
    yGauss = gaussfit(yAxis, yHist, yCoeffs, nterms=3)
    zGauss = gaussfit(zAxis, zHist, zCoeffs, nterms=3)

            ; Document the initial values

    if iterCount eq 0 then begin

            printf, docLun, 'Initial Offset:', string([xCoeffs[1], yCoeffs[1], zCoeffs[1]], format='(f6.3)')
            printf, docLun, 'Initial Width: ', string([xCoeffs[2], yCoeffs[2], zCoeffs[2]], format='(f6.3)')

    endif
        
        
        ; Fit the shift values to an Nth order polynomial in x, y, & z

    xTwist = RegressPoly(xDiff, [[x[steep]],[y[steep]],[z[steep]]], polyOrder=xPoly, cross=doCross, fit=xCoeffs)
    yTwist = RegressPoly(yDiff, [[x[steep]],[y[steep]],[z[steep]]], polyOrder=yPoly, cross=doCross, fit=yCoeffs)
    zTwist = RegressPoly(zDiff, [[x[flat]], [y[flat]], [z[flat]]],  polyOrder=zPoly, cross=doCross, fit=zCoeffs)

        ; Print the value of the shift iteration at the center of the data

    xTest = randomu(seed,2e4) * (max(x) - min(x)) + min(x)
    yTest = randomu(seed,2e4) * (max(y) - min(y)) + min(y)
    zTest = replicate(median(z),2e4)

    gTest = where(oShift->ContainsPoints(xTest+xMin,yTest+yMin))
    xTest = xTest[gTest]
    yTest = yTest[gTest]
    zTest = zTest[gTest]

    xFit = TransformData([[xTest],[yTest],[zTest]], xTwist, polyOrder=xPoly)
    yFit = TransformData([[xTest],[yTest],[zTest]], yTwist, polyOrder=yPoly)
    zFit = TransformData([[xTest],[yTest],[zTest]], zTwist, polyOrder=zPoly)

    printf, docLun, '(', strcompress(iterCount+1, /rem), ') X, Y, & Z fits: ', max(xFit), max(yFit), max(zFit), ' (', $
        xCoeffs[2], yCoeffs[2], zCoeffs[2], diffCoeffs[2], ')'
        
    

        ; Transform the entire dataset

    xTwist *= -1
    yTwist *= -1
    zTwist *= -1

    xTwist[1,0,0] += 1
    yTwist[0,1,0] += 1
    zTwist[0,0,1] += 1

    xTemp = TransformData([[sHeader.xOffset - xMin + sHeader.xScale * sData.east],  $
                           [sHeader.yOffset - yMin + sHeader.yScale * sData.north], $
                           [sHeader.zOffset - zMin + sHeader.zScale * sData.elev]], xTwist, polyOrder=xPoly)

    yTemp = TransformData([[sHeader.xOffset - xMin + sHeader.xScale * sData.east],  $
                           [sHeader.yOffset - yMin + sHeader.yScale * sData.north], $
                           [sHeader.zOffset - zMin + sHeader.zScale * sData.elev]], yTwist, polyOrder=yPoly)

    zTemp = TransformData([[sHeader.xOffset - xMin + sHeader.xScale * sData.east],  $
                           [sHeader.yOffset - yMin + sHeader.yScale * sData.north], $
                           [sHeader.zOffset - zMin + sHeader.zScale * sData.elev]], zTwist, polyOrder=zPoly)

    sData.east  = long((xMin - sHeader.xOffset + xTemp) / sHeader.xScale)
    sData.north = long((yMin - sHeader.yOffset + yTemp) / sHeader.yScale)
    sData.elev  = long((zMin - sHeader.zOffset + zTemp) / sHeader.zScale)

    xTemp = 0B
    yTemp = 0B
    zTemp = 0B

    if trackIter[0] eq -1 then trackIter =              [xCoeffs[2],yCoeffs[2],zCoeffs[2],diffCoeffs[2]] $
                          else trackIter = [[trackIter],[xCoeffs[2],yCoeffs[2],zCoeffs[2],diffCoeffs[2]]]

    iterCount++

endrep until (doIter eq 0) or (iterCount eq nIter) or ((xCoeffs[2] lt 0.1) and (yCoeffs[2] lt 0.1) and (zCoeffs[2] lt 0.1))


printf, docLun, 'Final Offset (X Y Z):', string([xCoeffs[1], yCoeffs[1], zCoeffs[1]])
    printf, docLun, 'Final Gaussian Width (X Y Z): ', string([xCoeffs[2], yCoeffs[2], zCoeffs[2]])
    
         ; Plot the histograms of the shift values
         
    loadct, 39
    device, decompose=0
    
    window, 6, xs=1000, ys=700, title='Shift Info'
    !p.multi = [0,1,4]

        plot,  diffAxis, diffHist, xtitle='Delta z (m)', xstyle=1
        oplot, diffAxis, diffGauss, linestyle=2, color=100

        plot,  zAxis, zHist, xtitle='Z Difference (m)', xstyle=1
        oplot, zAxis, zGauss, linestyle=2, color=100
        plots, [mean(zDiff),mean(zDiff)],     [0,max(zHist)], color=254
        plots, [median(zDiff),median(zDiff)], [0,max(zHist)], color=154

        plots, [1,1]*zCoeffs[1], [0,max(zHist)], color=100
        plots, [1,1]*zCoeffs[1]-3*zCoeffs[2], [0,max(zHist)], linestyle=1, color=100
        plots, [1,1]*zCoeffs[1]+3*zCoeffs[2], [0,max(zHist)], linestyle=1, color=100

        plot,  xAxis, xHist, xtitle='X Difference (m)', xstyle=1
        oplot, xAxis, xGauss, linestyle=2, color=100
        plots, [mean(xDiff),mean(xDiff)],     [0,max(xHist)], color=254
        plots, [median(xDiff),median(xDiff)], [0,max(xHist)], color=154

        plots, [1,1]*xCoeffs[1], [0,max(xHist)], color=100
        plots, [1,1]*xCoeffs[1]-3*xCoeffs[2], [0,max(xHist)], linestyle=1, color=100
        plots, [1,1]*xCoeffs[1]+3*xCoeffs[2], [0,max(xHist)], linestyle=1, color=100

        plot,  yAxis, yHist, xtitle='Y Difference (m)', xstyle=1
        oplot, yAxis, yGauss, linestyle=2, color=100
        plots, [mean(yDiff),mean(yDiff)], [0,max(yHist)], color=254
        plots, [median(yDiff),median(yDiff)], [0,max(yHist)], color=154

        plots, [1,1]*yCoeffs[1], [0,max(yHist)], color=100
        plots, [1,1]*yCoeffs[1]-3*yCoeffs[2], [0,max(yHist)], linestyle=1, color=100
        plots, [1,1]*yCoeffs[1]+3*yCoeffs[2], [0,max(yHist)], linestyle=1, color=100

    !p.multi = 0

        ; Scatterplot the vertical shift versus slope in x and y

    window, 7, xs=1000, ys=700, title='Slope vs z shift
    !p.multi = [0,1,2]

        plot, slopeArray[0,*], diffArray, psym=3, xtitle='x slope', ytitle='delta z (m)', $
            xrange=[-1,1], yrange=[mean(diffArray) - 3*stddev(diffArray), mean(diffArray) + 3*stddev(diffArray)]

        plot, slopeArray[1,*], diffArray, psym=3, xtitle='y slope', ytitle='delta z (m)', $
            xrange=[-1,1], yrange=[mean(diffArray) - 3*stddev(diffArray), mean(diffArray) + 3*stddev(diffArray)]

    !p.multi  = 0

        ; Scatterplot the horizontal and vertical shifts versus x, y, and z

    window, 10, xs=1000, ys=700, title='Shift vs x,y,z'
    !p.multi = [0,3,3]

        plot, x[steep], xDiff, psym=3, ytitle='x diff (m)', xtitle='x coordinate', xstyle=1, ystyle=1, $
            xrange=[min(x),max(x)], yrange=[mean(xDiff) - 3*stddev(xDiff), mean(xDiff) + 3*stddev(xDiff)]

        plot, y[steep], xDiff, psym=3, ytitle='x diff (m)', xtitle='y coordinate', xstyle=1, ystyle=1, $
            xrange=[min(y),max(y)], yrange=[mean(xDiff) - 3*stddev(xDiff), mean(xDiff) + 3*stddev(xDiff)]

        plot, z[steep], xDiff, psym=3, ytitle='x diff (m)', xtitle='z coordinate', xstyle=1, ystyle=1, $
            xrange=[min(z),max(z)], yrange=[mean(xDiff) - 3*stddev(xDiff), mean(xDiff) + 3*stddev(xDiff)]

        plot, x[steep], yDiff, psym=3, ytitle='y diff (m)', xtitle='x coordinate', xstyle=1, ystyle=1, $
            xrange=[min(x),max(x)], yrange=[mean(yDiff) - 3*stddev(yDiff), mean(yDiff) + 3*stddev(yDiff)]

        plot, y[steep], yDiff, psym=3, ytitle='y diff (m)', xtitle='y coordinate', xstyle=1, ystyle=1, $
            xrange=[min(y),max(y)], yrange=[mean(yDiff) - 3*stddev(yDiff), mean(yDiff) + 3*stddev(yDiff)]

        plot, z[steep], yDiff, psym=3, ytitle='y diff (m)', xtitle='z coordinate', xstyle=1, ystyle=1, $
            xrange=[min(z),max(z)], yrange=[mean(yDiff) - 3*stddev(yDiff), mean(yDiff) + 3*stddev(yDiff)]

        plot, x[flat],  zDiff, psym=3, ytitle='z diff (m)', xtitle='x coordinate', xstyle=1, ystyle=1, $
            xrange=[min(x),max(x)], yrange=[mean(zDiff) - 3*stddev(zDiff), mean(zDiff) + 3*stddev(zDiff)]

        plot, y[flat],  zDiff, psym=3, ytitle='z diff (m)', xtitle='y coordinate', xstyle=1, ystyle=1, $
            xrange=[min(y),max(y)], yrange=[mean(zDiff) - 3*stddev(zDiff), mean(zDiff) + 3*stddev(zDiff)]

        plot, z[flat],  zDiff, psym=3, ytitle='z diff (m)', xtitle='z coordinate', xstyle=1, ystyle=1, $
            xrange=[min(z),max(z)], yrange=[mean(zDiff) - 3*stddev(zDiff), mean(zDiff) + 3*stddev(zDiff)]

    !p.multi = 0

    singleIter = dialog_message('Iterate analysis?', /center, /question)

endrep until singleIter eq 'No'


; Write the data to a new file

saveFile = outputDir + '\' + 'ShiftedFile.las'

        ; Write the data to a new file

sData = sData[where(sData.east  ge ((min(x) + xMin - sHeader.xOffset) / sHeader.xScale) and $
                        sData.east  le ((max(x) + xMin - sHeader.xOffset) / sHeader.xScale) and $
                        sData.north ge ((min(y) + yMin - sHeader.yOffset) / sHeader.yScale) and $
                        sData.north le ((max(y) + yMin - sHeader.yOffset) / sHeader.yScale))]

xShift = (mean(sData.east)                - xMean) * sHeader.xScale + sHeader.xOffset
yShift = (mean(sData.north)               - yMean) * sHeader.yScale + sHeader.yOffset
zShift = (mean(sData.elev - sData.source) - zMean) * sHeader.zScale + sHeader.zOffset
    
printf, docLun, 'Mean shifts: ', string([xShift, yShift, zShift])

    
WriteLAS_BCAL, saveFile, sHeader, sData, /check

free_lun, docLun

sData = 0B

obj_destroy, oMask
obj_destroy, oShift
ptr_free, bIndex

loadct, 0, /silent
device, decompose=1


end

