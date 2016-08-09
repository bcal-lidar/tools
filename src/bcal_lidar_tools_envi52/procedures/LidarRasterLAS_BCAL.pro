;+
; NAME:
;
;       LidarRasterLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to create raster products from the
;       point data in a LiDAR .las file.  It is meant to be run through ENVI.
;       The resolution, projection, and NoData value of the raster products
;       are set by the user, and the data can be subset geographically or by
;       return number.  The user can also choose to interpolate data gaps.
;       Some of the products assume that the data has been filtered to calculate
;       vegetation heights through the HeightLAS.pro program.
;
; PRODUCTS:
;
;       Maximum Elevation       - The maximum elevation point within each pixel
;       Minimum Elevation       - The minimum elevation point within each pixel
;       Mean Elevation          - The mean of all elevation points within each pixel
;       Slope                   - The average slope of all points within each pixel
;       Aspect                  - The aspect of the average slope of all points within each pixel
;       Absolute Roughness      - The roughness (standard deviation) of all elevation points within each pixel
;       Local Roughness         - The roughness (standard deviation) of all elevation points within each pixel
;                                 after the local slope has been removed (de-trended)
;       Intensity               - The mean intensity of all points within each pixel
;       Point Density           - The density of points (per square meter) within the pixel
;       Bare Earth Elevation    - The minimum bare earth elevation (data elevation minus vegetation height)
;                                 point within each pixel
;       Bare Earth Slope        - The average slope of all bare earth elevation points within each pixel
;       Bare Earth Aspect       - The aspect of the average slope of all bare earth elevation points within each pixel
;       Mean Vegetation Height  - The mean of all height points within each pixel
;       Max Vegetation Height   - The maximum of all height points within each pixel
;       Vegetation Roughness    - The roughness (standard deviation) of all height points within each pixel
;       Ground Point Density    - The density of ground points (per square meter) within the pixel
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
;       GetBounds_BCAL.pro
;       GetIndex_BCAL.pro
;       ScalePoly_BCAL.pro
;
; KNOWN ISSUES:
;
;       Currently uses nearest neighbor-type interpolation, which may not be optimal.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
;       Corrected bug in slope interpolation, April 2006
;       Added mosaicking, July 2006
;       Fixed mosaicking bug, November 2006
;       Added outlier removal, November 2006
;       Added embedded projection support, June 2007
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

pro LidarRasterLAS_BCAL, event

; x & y are geographic coords
; i & j are tile raster coords
; m & n are image raster coords

compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error creating file')
    return
endif

;start = systime(/seconds)

    ; Get the input file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; For each file, read the header and establish minimum and
    ; maximum extents.  Also record the center point of each file.

for a=0,nFiles-1 do begin

    ReadLAS_BCAL, inputFiles[a], header, projection=defProj, /nodata

    if a eq 0 then begin

        xMin = header.xMin
        xMax = header.xMax
        yMin = header.yMin
        yMax = header.yMax

    endif else begin

        xMin <= header.xMin
        xMax >= header.xMax
        yMin <= header.yMin
        yMax >= header.yMax

    endelse

endfor

    ; Establish default parameters

subsetVals = [xMin,xMax,yMin,yMax]
subsetList = ['Min East','Max East','Min North','Max North']

nReturns = 2

returnList = indgen(nReturns) + 1
returnList = ' Return ' + strcompress(returnList)
returnList = [returnList,'All Returns']

cDefault = 5
cField   = 2
if n_tags(defProj) then begin

    units   = strlowcase(envi_translate_projection_units(defProj.units))
    cPrompt = 'Enter raster spacing (' + units + '): '
    if units eq 'degrees' then begin
        cDefault = 0.0001D
        cField   = 6
    endif

endif else begin

    defProj = envi_proj_create()
    cPrompt = 'Enter raster spacing (meters): '

endelse

    ; Create list of available data products

products = {maxElev    :{title:'Maximum Elevation',                  points:1, index:-1, doIt:0}, $
            minElev    :{title:'Minimum Elevation',                  points:1, index:-1, doIt:0}, $
            meanElev   :{title:'Mean Elevation',                     points:1, index:-1, doIt:0}, $
            fullSlope  :{title:'Slope (degrees)',                    points:3, index:-1, doIt:0}, $
            fullAspect :{title:'Aspect (degrees from N)',            points:3, index:-1, doIt:0}, $
            fullRough  :{title:'Absolute Roughness',                 points:2, index:-1, doIt:0}, $
            locRough   :{title:'Local Roughness',                    points:3, index:-1, doIt:0}, $
            inten      :{title:'Intensity',                          points:1, index:-1, doIt:0}, $
            density    :{title:'Point Density',                      points:1, index:-1, doIt:0}, $
            bareElev   :{title:'Bare Earth Elevation',               points:1, index:-1, doIt:0}, $
            bareSlope  :{title:'Bare Earth Slope (degrees)',         points:3, index:-1, doIt:0}, $
            bareAspect :{title:'Bare Earth Aspect (degrees from N)', points:3, index:-1, doIt:0}, $
            meanVeg    :{title:'Mean Vegetation Height',             points:1, index:-1, doIt:0}, $
            maxVeg     :{title:'Max Vegetation Height',              points:1, index:-1, doIt:0}, $
            vegRough   :{title:'Vegetation Roughness',               points:2, index:-1, doIt:0}, $
            bareDen    :{title:'Ground Point Density',               points:1, index:-1, doIt:0}}

nBare        = 9
nProducts    = n_tags(products)
productList  = strarr(nProducts)
prodIndex    = bytarr(nProducts)
prodIndex[0] = 1
for f=0,nProducts-1 do productList[f] = products.(f).title

if nFiles eq 1 then doMosaic = [0] else doMosaic = [1]

    ; Create the widget that will record the user parameters

gridBase = widget_auto_base(title='Raster Parameters')

    topBase    = widget_base(gridBase, /row)
    leftBase   = widget_base(topBase, /column)

    returnBase = widget_base(leftBase, /row)
    dummy      = widget_pmenu(returnBase, list=returnList, default=nReturns, prompt='Select return number:     ', $
                              uvalue='returns', /auto_manage)

    cellBase   = widget_base(leftBase, /row)
    dummy      = widget_param(cellBase, dt=5, default=cDefault, field=cField, prompt=cPrompt, uvalue='grid', /auto)

    nullBase   = widget_base(leftBase, /row)
    dummy      = widget_param(nullBase, default=-1, prompt='Enter value for No Data: ', uvalue='noData', /auto)

    dummy      = widget_menu(leftBase, default_array=[1], list=['Interpolate empty pixels?'],   uvalue='inside',  /auto)
    dummy      = widget_menu(leftBase, default_array=[0], list=['Use vector mask(s)?'],         uvalue='mask',    /auto)
    dummy      = widget_menu(leftBase, default_array=doMosaic, list=['Mosaic multiple files?'], uvalue='mosaic',  /auto)
    dummy      = widget_menu(leftBase, default_array=[1], list=['Ignore outliers?'],           uvalue='outlier', /auto)

    subBase    = widget_base(leftBase, /row)
    xBase      = widget_base(subBase, /column)
    dummy      = widget_param(xBase, default=xMin, dt=5, field=cField, prompt='Minimum East:',  uvalue='xMin', xs=17, /auto)
    dummy      = widget_param(xBase, default=xMax, dt=5, field=cField, prompt='Maximum East:',  uvalue='xMax', xs=17, /auto)
    yBase      = widget_base(subBase, /column)
    dummy      = widget_param(yBase, default=yMin, dt=5, field=cField, prompt='Minimum North:', uvalue='yMin', xs=17, /auto)
    dummy      = widget_param(yBase, default=yMax, dt=5, field=cField, prompt='Maximum North:', uvalue='yMax', xs=17, /auto)

    dummy      = widget_map(leftBase, default_map=[0,0], default_proj=defProj, uvalue='proj', /auto_manage)

    rightBase  = widget_base(topBase)
    dummy      = widget_multi(rightBase, list=productList, prompt='Select products:', /no_range, ysize=400, $
                              default=prodIndex, uvalue='products', /auto)

result = auto_wid_mng(gridBase)
if (result.accept eq 0) then return

retNum    = result.returns + 1
grid      = result.grid
noData    = float(result.noData)
projInfo  = result.proj
doInterp  = result.inside[0]
prodIndex = result.products
doMask    = result.mask[0]
doMosaic  = result.mosaic[0]
doOutlier = result.outlier[0]

if nFiles eq 1 then doMosaic = 1

if noData eq -999 then seeThru = float(-998) $
                  else seeThru = float(-999)

if doMosaic eq 0 then seeThru = noData

    ; Set the min and max values to the user specifications, and determine the dimensions of the
    ; output raster.  Make sure the ranges are an integer number of pixels.

xMin = result.xMin
yMin = result.yMin

mDim = ceil((result.xMax - xMin) / grid)
nDim = ceil((result.yMax - yMin) / grid)

xMax = xMin + mDim * grid
yMax = yMin + nDim * grid

    ; Create the list of product names

bNames = productList[where(prodIndex eq 1)]
nBands = total(prodIndex)

    ; Create containers that will hold boundary objects of areas already completed and of
    ; masked regions

oBounds = Obj_New('IDLanROIGroup')
oMasks  = Obj_New('IDLanROIGroup')

    ; If requested, get the mask vector file(s).  Read them and add to a single container object.

if doMask then begin

    maskFiles = dialog_pickfile(title='Select mask file(s)', filter='*.evf', /multiple_files, /path)
    if (maskFiles[0] eq '') then begin
        doMask = 0
        return
    endif

    nMask = n_elements(maskFiles)

    for v=0,nMask-1 do begin

        maskID = envi_evf_open(maskFiles[v])
        envi_evf_info, maskID, num_recs=nRecs

        for w=0,nRecs-1 do begin

            maskCoords = envi_evf_read_record(maskID, w)
            oMasks->Add, Obj_New('IDLanROI', maskCoords)

        endfor

        envi_evf_close, maskID

    endfor

endif

    ; Record the user-determined filename or directory for the output product

if doMosaic then begin

    outputBase = widget_auto_base(title='Raster Output')
    outputName = widget_outfm(outputBase, default='raster', prompt='Enter name of output raster file', uvalue='out', /auto)

    result = auto_wid_mng(outputBase)
    if (result.accept eq 0) then return

    outMemory  = result.out.in_memory
    outputFile = result.out.name

        ; Set the temporary directory

    tempDir = getenv('IDL_TMPDIR')

endif else begin

        ; Set the output directory

    tempDir = dialog_pickfile(title='Select output directory', /directory, /path)
    if (tempDir eq '') then return

endelse

    ; Determine how many individual lidar points are needed (per pixel)
    ; for the various products.

needOne   = 0
needTwo   = 0
needThree = 0

bNumber = 0

for g=0,nProducts-1 do begin
    if prodIndex[g] eq 1 then begin

        products.(g).doIt  = 1
        products.(g).index = bNumber++

        if products.(g).points eq 1 then needOne   = 1
        if products.(g).points eq 2 then needTwo   = 1
        if products.(g).points eq 3 then needThree = 1

    endif
endfor

if products.fullSlope.doIt or products.fullAspect.doIt or products.locRough.doIt then needFull = 1 else needFull = 0
if products.bareSlope.doIt or products.bareAspect.doIt                           then needBare = 1 else needBare = 0

    ; Begin processing the data, file by file

for b=0,nFiles-1 do begin

        ; Read the lidar file header and determine if the file data falls
        ; within the user-specified area.  If so, proceed.

    ReadLAS_BCAL, inputFiles[b], header, /nodata

    if header.xMin le xMax and header.xMax ge xMin and $
       header.yMin le yMax and header.yMax ge yMin then begin

            ; Establish the status reporting widget.  This will report the processing status
            ; for each data file.

        statBase = widget_auto_base(title='Rasterization')
        statText = ['Rasterization Progress: ', file_basename(inputFiles[b]), $
                    'File' + strcompress(b+1) + ' of' + strcompress(n_elements(inputFiles))]
        envi_report_init, statText, base=statBase, /interrupt, title='Rasterization'

            ; Read the data file.

        ReadLAS_BCAL, inputFiles[b], header, pData

            ; Determine the data file's extents and dimensions with respect to those
            ; of the output raster.  This ensures that the pixels of the data tile line up
            ; with those of the final output raster.

        xMinTile = header.xMin - ((header.xMin - xMin) mod grid)
        yMinTile = header.yMin - ((header.yMin - yMin) mod grid)

        iDim = ceil((header.xMax - xMinTile) / grid)
        jDim = ceil((header.yMax - yMinTile) / grid)

        xMaxTile = iDim * grid + xMinTile
        yMaxTile = jDim * grid + yMinTile

            ; Determine the shift between the file coordinates and the output raster coordinates.
            ; Output coordinates are based on the UPPER-left corner.  The shifts may be negative if
            ; a subset is required.

        mShift = (xMinTile - xMin) / grid
        nShift = (yMax - yMaxTile) / grid

            ; Determine the boundary of the data file.

        boundIndex  = GetBounds_BCAL(pData.east, pData.north, precision=(2 * grid / header.xScale))

        boundCoords = transpose([[pData[boundIndex].east  * header.xScale + header.xOffset], $
                                 [pData[boundIndex].north * header.yScale + header.yOffset]])
        outerBound  = Obj_New('IDLanROI', boundCoords)

            ; If other regions have already been completed, determine if overlap exists.

        overlap = 0

        if doMosaic and (oBounds->Count() ge 1) then begin

            for n=0,oBounds->Count()-1 do begin

                tempBound = oBounds->Get(position=n)
                tempBound->GetProperty, roi_xrange=xRange, roi_yrange=yRange

                    ; Check to determine if previously done areas lie within the tile

                if xRange[0] lt xMaxTile and xRange[1] gt xMinTile and $
                   yRange[0] lt yMaxTile and yRange[1] gt yMinTile then begin

                        ; If overlap occurs, determine the minimum distance between data tile
                        ; bounds and the boundary of previously done tiles

                    xDiff = abs(xRange[0] - xMaxTile) < abs(xMinTile - xRange[1])
                    yDiff = abs(yRange[0] - yMaxTile) < abs(yMinTile - yRange[1])

                    overlap >= ((xDiff < yDiff) / 2)

                endif

            endfor

        endif

        boundCoords = ScalePoly_BCAL(boundCoords, -1D*[overlap,overlap])
        innerBound  = Obj_New('IDLanROI', boundCoords)

            ; Get file statistics

        tMed = median(pData.elev)
        tStd = stddev(pData.elev)

            ; Create data array

        dataArray = temporary(fltarr(iDim,jDim,nBands)) + seeThru

            ; Create the data index.  The point data are referenced using 'index chunking', which
            ; is determined by the dimensions of the output raster. Only the data whose return number
            ; has been requested are indexed.  If one or more requested products depend on vegetation
            ; heights, only those data with calculated heights are indexed.

        arrayHist = histogram(iDim * floor((header.yOffset - yMinTile + pData.north * header.yScale) / grid) $
                            +        floor((header.xOffset - xMinTile + pData.east  * header.xScale) / grid) $
                            + iDim * jDim * ((retNum le nReturns) and ((pData.nReturn mod 8) ne retNum)) $
                            + iDim * jDim * ((max(prodIndex[nBare:nProducts-1])) and (pData.source eq (2^16 - 1))) $
;                            + iDim * jDim * ((max(prodIndex[nBare:nProducts-1])) and (pData.source gt (50./header.zScale))) $
                            + iDim * jDim * doOutlier * ((pData.elev gt (tMed + 5*tStd)) or $
                                                         (pData.elev lt (tMed - 5*tStd))), $
                            reverse_indices=arrayIndex, min=0d, max=iDim*jDim-1)

            ; Create vectors determining the pixel centers

        xCenter = (dindgen(iDim) + 0.5) * grid + xMinTile
        yCenter = (dindgen(jDim) + 0.5) * grid + yMinTile

        envi_report_inc,  statBase, jDim

        for j=0,jDim-1 do begin

            yArray = dblarr(iDim) + yCenter[j]

            k = jDim - 1 - j

                ; Determine whether the pixels in this row require processing.  If interpolation
                ; is requested, initialize all pixels to 1.  If not, initialize all occupied
                ; pixels to 1.

            if doInterp then doPixel = bytarr(iDim) + 1 $
                        else doPixel = byte(arrayHist[j*iDim:(j+1)*iDim-1] < 1)

                ; Set to 0 pixels that are outside the outer boundary.

            doPixel *= (outerBound->ContainsPoints(xCenter,yArray) < 1)

                ; Set to 0 pixels that are inside the mask.

            if doMask then begin

                for m=0,oMasks->Count()-1 do begin

                    tempMask = oMasks->Get(position=m)
                    tempMask->GetProperty, roi_xrange=xRange, roi_yrange=yRange

                        ; Check to determine if any pixels are masked within the tile

                    if xRange[0] le xMaxTile and xRange[1] ge xMinTile and $
                       yRange[0] le yMaxTile and yRange[1] ge yMinTile then $

                        doPixel *= (1 - (tempMask->ContainsPoints(xCenter,yArray) < 1))

                endfor

            endif

                ; Set to 0 pixels that are outside the inner boundary AND inside the previously
                ; completed area.

            if b ge 1 then begin

                for n=0,oBounds->Count()-1 do begin

                    tempBound = oBounds->Get(position=n)
                    tempBound->GetProperty, roi_xrange=xRange, roi_yrange=yRange

                        ; Check to determine if previously done areas lie within the tile

                    if xRange[0] le xMaxTile and xRange[1] ge xMinTile and $
                       yRange[0] le yMaxTile and yRange[1] ge yMinTile then $

                        doPixel *= (1 - (1 - (innerBound->ContainsPoints(xCenter,yArray) < 1)) $
                                            * (tempBound->ContainsPoints(xCenter,yArray) < 1) )

                endfor

            endif

        for i=0,iDim-1 do begin

            if doPixel[i] then begin

                    ; Initialize various parameters

                factor = 0

                    ; Get the indices of the data points that lie within the pixel.

                index = GetIndex_BCAL(i,j,iDim,jDim,arrayIndex,factor)

                    ; If products are requested which only require a single data point per
                    ; pixel, begin.

                if needOne then begin

                        ; If interpolation is requested and no data points lie within the pixel,
                        ; use GetIndex_BCAL to find surrounding data points.  (GetIndex_BCAL is iterative.)

                    while (index[0] eq -1L) do index = GetIndex_BCAL(i,j,iDim,jDim,arrayIndex,++factor)

                        ; If at least one data point is found, determine the pixel values for the
                        ; various products.

                        if products.maxElev.doIt then $
                         dataArray[i,k,products.maxElev.index]  = max(pData[index].elev)    * header.zScale + header.zOffset
                        if products.minElev.doIt then $
                         dataArray[i,k,products.minElev.index]  = min(pData[index].elev)    * header.zScale + header.zOffset
                        if products.meanElev.doIt then $
                         dataArray[i,k,products.meanElev.index] = mean(pData[index].elev)   * header.zScale + header.zOffset
                        if products.inten.doIt then $
                         dataArray[i,k,products.inten.index]    = max(pData[index].inten)
                        if products.density.doIt then $
                         dataArray[i,k,products.density.index]  = n_elements(index) / grid^2
                        if products.meanVeg.doIt then $
                         dataArray[i,k,products.meanVeg.index]  = mean(pData[index].source) * header.zScale
                        if products.maxVeg.doIt then $
                         dataArray[i,k,products.maxVeg.index]   = max(pData[index].source)  * header.zScale
                        if products.bareElev.doIt then $
                         dataArray[i,k,products.bareElev.index] = mean(pData[index].elev - pData[index].source) $
;                         dataArray[i,k,products.bareElev.index] = min(pData[index].elev - pData[index].source) $
                                                                                            * header.zScale + header.zOffset
                        if products.bareDen.doIt then begin
                            dummy = where(pData[index].source eq 0, groundCount)
                            dataArray[i,k,products.bareDen.index] = groundCount / grid^2
                        endif

                endif

                    ; If products are requested which require at least two data points per
                    ; pixel, begin.

                if needTwo then begin

                        ; If interpolation is necessary and not enough data points lie within the pixel,
                        ; use GetIndex_BCAL to find additional surrounding data points.  (GetIndex_BCAL is iterative.)

                    while (doInterp and (n_elements(index) lt 2)) do index = GetIndex_BCAL(i,j,iDim,jDim,arrayIndex,++factor)

                        ; If at least two data points are found, determine the pixel values for the
                        ; roughness products.

                    if (n_elements(index) ge 2) then begin

                        if products.fullRough.doIt then $
                         dataArray[i,k,products.fullRough.index] = stddev(pData[index].elev)   * header.zScale
                        if products.vegRough.doIt then $
                         dataArray[i,k,products.vegRough.index]  = stddev(pData[index].source) * header.zScale

                    endif

                endif

                    ; If products are requested which require at least three data points per
                    ; pixel, begin.

                if needThree then begin

                        ; If interpolation is necessary and not enough data points lie within the pixel,
                        ; use GetIndex_BCAL to find additional surrounding data points.  (GetIndex_BCAL is iterative.)

                    while (doInterp and (n_elements(index) lt 6)) do index = GetIndex_BCAL(i,j,iDim,jDim,arrayIndex,++factor)

                        ; If at least three data points are found and a bare earth product is needed, begin.

                    if (n_elements(index) ge 6 and needBare) then begin

                            ; Compute the slope using the bare earth data points

                        bareSlope = regress(transpose([[pData[index].east  * header.xScale], $
                                                       [pData[index].north * header.yScale]]), $
                                                       (pData[index].elev - pData[index].source) * header.zScale, $
                                                       status=bareStat)

                            ; If interpolation is required and the slope calculation has not converged,
                            ; use GetIndex_BCAL to find additional points and recalculate. Iterate until the
                            ; slope calculation converges.

                        while (doInterp and ((bareStat gt 0) or (min(finite(bareSlope)) eq 0))) do begin

                            index = GetIndex_BCAL(i,j,iDim,jDim,arrayIndex,factor++)

                            bareSlope = regress(transpose([[pData[index].east  * header.xScale], $
                                                           [pData[index].north * header.yScale]]), $
                                                           (pData[index].elev - pData[index].source) * header.zScale, $
                                                           status=bareStat)

                        endwhile

                            ; If the slope calculation coverged, record the slope and aspect.

                        if ((bareStat eq 0) and (min(finite(bareSlope)) eq 1)) then begin

                            if products.bareSlope.doIt then $
                             dataArray[i,k,products.bareSlope.index]  = atan(sqrt(total(bareSlope^2))) * !radeg
                            if products.bareAspect.doIt then $
                             dataArray[i,k,products.bareAspect.index] = atan(bareSlope[0,0],bareSlope[0,1]) * !radeg $
                                                                      + ((bareSlope[0,0] lt 0) * 360)

                        endif

                    endif

                        ; If at least three data points are found and a full elevation product is needed, begin.

                    if (n_elements(index) ge 6 and needFull) then begin

                            ; Compute the slope using the elevation data points

                        fullSlope = regress(transpose([[pData[index].east  * header.xScale], $
                                                       [pData[index].north * header.yScale]]), $
                                                        pData[index].elev  * header.zScale, $
                                                        const=fullConst, status=fullStat)

                            ; If interpolation is required and the slope calculation has not converged,
                            ; use GetIndex_BCAL to find additional points and recalculate. Iterate until the
                            ; slope calculation converges.

                        while (doInterp and ((fullStat gt 0) or (min(finite(fullSlope)) eq 0))) do begin

                            index = GetIndex_BCAL(i,j,iDim,jDim,arrayIndex,factor++)

                            fullSlope = regress(transpose([[pData[index].east  * header.xScale], $
                                                           [pData[index].north * header.yScale]]), $
                                                            pData[index].elev  * header.zScale, $
                                                            const=fullConst, status=fullStat)

                        endwhile

                            ; If the slope calculation coverged, record the slope, aspect, and local
                            ; roughness values.

                        if ((fullStat eq 0) and (min(finite(fullSlope)) eq 1)) then begin

                            if products.fullSlope.doIt then $
                             dataArray[i,k,products.fullSlope.index]  = atan(sqrt(total(fullSlope^2))) * !radeg
                            if products.fullAspect.doIt then $
                             dataArray[i,k,products.fullAspect.index] = atan(fullSlope[0,0],fullSlope[0,1]) * !radeg $
                                                                      + ((fullSlope[0,0] lt 0) * 360)

                            if products.locRough.doIt then begin

                                elevDev = pData[index].elev  * header.zScale - (fullConst $
                                        + pData[index].east  * header.xScale * fullSlope[0] $
                                        + pData[index].north * header.yScale * fullSlope[1])

                                dataArray[i,k,products.locRough.index] = stddev(elevDev)

                            endif

                        endif

                    endif

                endif

            endif

        endfor

            ; Update the progress bar.

        envi_report_stat, statBase, j, jDim, cancel=cancel
        if cancel then begin
            envi_report_init, base=statBase, /finish
            Obj_Destroy, oBounds
            Obj_Destroy, oMasks
            return
        endif

        endfor

            ; Cleanup after rasters are finished.

        Obj_Destroy, innerBound
        oBounds->Add, outerBound

        pData = [0]

            ; Create the map projection

        mapInfo = envi_map_info_create(proj=projInfo.proj, ps=[grid,grid], mc=[0,0,xMinTile,yMaxTile])

            ; Record the raster products to an ENVI file in the temporary directory

        tempName = tempDir + file_basename(inputFiles[b], '.las')

        envi_write_envi_file, dataArray, $
            bnames=bNames, nb=nBands, nl=jDim, ns=iDim, map_info=mapInfo, /no_copy, /no_open, $
            byte_order=0, out_name=tempName, def_bands=[0], interleave=0, data_type=4

        if n_elements(tempFiles) eq 0 then begin
            tempFiles = tempName
            dims = [-1, (0 > (0 - mShift)), (iDim < (mDim - mShift))-1, $
                        (0 > (0 - nShift)), (jDim < (nDim - nShift))-1]
            xLoc = mShift > 0
            yLoc = nShift > 0
        endif else begin
            tempFiles = [tempFiles,tempName]
            dims = [[dims],[-1, (0 > (0 - mShift)), (iDim < (mDim - mShift))-1, $
                                (0 > (0 - nShift)), (jDim < (nDim - nShift))-1]]
            xLoc = [xLoc,(mShift > 0)]
            yLoc = [yLoc,(nShift > 0)]
        endelse

        envi_report_init, base=statBase, /finish

    endif

endfor

    ; If mosaicking was requested, begin

if doMosaic then begin

        ; Open the temporary files

    nTemp = n_elements(tempFiles)
    for g=0,nTemp-1 do begin

        envi_open_file, tempFiles[g], r_fid=tempFid, /no_realize, /invisible
        if g eq 0 then fid = tempFid else fid = [fid,tempFid]

    endfor

        ; Mosaic the temporary tiles together and save to the output file

    pos = rebin(lindgen(nBands),nBands,nTemp)

    mapInfo = envi_map_info_create(proj=projInfo.proj, ps=[grid,grid], mc=[0,0,xMin,yMax])

    envi_doit, 'mosaic_doit', background=noData, dims=dims, fid=fid, /georef, in_memory=outMemory, map_info=mapInfo, $
        out_bname=bNames, out_dt=4, out_name=outputFile, pixel_size=[1,1], pos=pos, see_through_val=fltarr(nTemp)+seeThru, $
        use_see_through=intarr(nTemp)+1, x0=xLoc, y0=yLoc, xsize=mDim, ysize=nDim

        ; Close and erase the temporary files

    for h=0,nTemp-1 do envi_file_mng, id=fid[h], /remove, /delete

endif

Obj_Destroy, oMasks
Obj_Destroy, oBounds

tempFiles = [0]

;print, systime(/seconds) - start


end

;kill routine
