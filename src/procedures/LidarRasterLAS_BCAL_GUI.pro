;+
; NAME:
;
;       LidarRasterLAS_BCAL_GUI
;
; PURPOSE:
;
;       Graphical front-end to LidarRasterLAS_BCAL
;
; AUTHOR:
;
;       Josh Johnston
;       jjohnston@boisestate.edu
;       Boise State University
;       
; KNOWN ISSUES:
;
;       Duplicate definitions of variables with LidarRasterLAS_BCAL
;
; MODIFICATION HISTORY:
;
;       Adapted from LidarRasterLAS_BCAL August 2015
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

pro LidarRasterLAS_BCAL_GUI, event

  compile_opt idl2, logical_predicate

  ; Establish an error handler

  catch, theError
  if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error in LidarRasterLAS_BCAL_GUI')
    return
  endif

  ; Get the input file(s)
  inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
  if (inputFiles[0] eq '') then return

  nFiles = n_elements(inputFiles)
  
  if nFiles eq 1 then doMosaic = [0] else doMosaic = [1]

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

  nReturns = 2 ; jj- Defined in two places, also LidarRasterLAS_BCAL
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

  products = { $
    maxElev    :{title:'Maximum Elevation',                  doIt:0}, $
    minElev    :{title:'Minimum Elevation',                  doIt:0}, $
    meanElev   :{title:'Mean Elevation',                     doIt:0}, $
    fullSlope  :{title:'Slope (degrees)',                    doIt:0}, $
    fullAspect :{title:'Aspect (degrees from N)',            doIt:0}, $
    fullRough  :{title:'Absolute Roughness',                 doIt:0}, $
    locRough   :{title:'Local Roughness',                    doIt:0}, $
    inten      :{title:'Intensity',                          doIt:0}, $
    density    :{title:'Point Density',                      doIt:0}, $
    bareElev   :{title:'Bare Earth Elevation',               doIt:0}, $
    bareSlope  :{title:'Bare Earth Slope (degrees)',         doIt:0}, $
    bareAspect :{title:'Bare Earth Aspect (degrees from N)', doIt:0}, $
    meanVeg    :{title:'Mean Vegetation Height',             doIt:0}, $
    maxVeg     :{title:'Max Vegetation Height',              doIt:0}, $
    vegRough   :{title:'Vegetation Roughness',               doIt:0}, $
    bareDen    :{title:'Ground Point Density',               doIt:0}}


  nProducts    = n_tags(products)
  productTags  = tag_names(products)
  productList  = strarr(nProducts)
  prodIndex    = bytarr(nProducts)
  prodIndex[0] = 1
  for f=0,nProducts-1 do productList[f] = products.(f).title

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
  dummy      = widget_menu(leftBase, default_array=[1], list=['Include outliers?'],           uvalue='outlier', /auto)

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

  productStrings = productTags[where(prodIndex eq 1)]


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

  ; If requested, get the mask vector file(s).  Read them and add to a single container object.
  if doMask then begin
    maskFiles = dialog_pickfile(title='Select mask file(s)', filter='*.evf', /multiple_files, /path)
  endif

  ; Record the user-determined filename or directory for the output product
  if doMosaic then begin

    outputBase = widget_auto_base(title='Raster Output')
    outputName = widget_outfm(outputBase, default='raster', prompt='Enter name of output raster file', uvalue='out', /auto)

    result = auto_wid_mng(outputBase)
    if (result.accept eq 0) then return

    outMemory  = result.out.in_memory
    outputFile = result.out.name

  endif else begin

    ; Set the output directory

    outputFile = dialog_pickfile(title='Select output file', /path)
    if (outputFile eq '') then return

  endelse

  LidarRasterLAS_BCAL, INPUTFILES=inputFiles, OUTPUTFILE=outputFile, MASKFILES=maskFiles, RETNUM=retNum, GRID=grid, NODATA=noData, DOOUTLIER=doOutlier, DOINTERP=doInterp, XMIN=userXMin, XMAX=userXMax, YMIN=userYMin, YMAX=userYMax, PRODUCTSTRINGS=productStrings, PROJ=projInfo.proj

end