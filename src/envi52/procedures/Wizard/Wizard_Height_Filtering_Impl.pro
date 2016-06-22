;This is the implementation for height filtering functions
; This includes the options for preparing data as well

function HeightFilter, files, baseDir
  compile_opt idl2, logical_predicate
  doProfile = 0

    ; Get the input file(s).

  inputFiles = files
  
      ; Assumes two returns are available (first and last).
  
  nReturns = 2
  
  returnList = indgen(nReturns) + 1
  returnList = ' Return ' + strcompress(returnList)
  returnList = [returnList,'All Returns']
  
      ; Create list of interpolation methods
  
  interpList = ['Cubic Spline',                      $  ; very slow, doesn't work?
                'Inverse Distance - 1st Order',      $  ; slow
                'Inverse Distance - 2nd Order',      $  ;
                'Inverse Distance - 3rd Order',      $  ;
                'Inverse Multiquadric',              $
  ;              'Kriging',                          $  ; very slow, needs work on parameters
                'Linear',                            $  ; fast
                'Natural Neighbor',                  $
                'Nearest Neighbor',                  $  ; slow, not great
                'Polynomial Regression - 2nd Order', $  ;
                'Polynomial Regression - 3rd Order', $  ;
                'Thin Plate Spline']                    ; very slow
  
      ; Create the widget that will record the user parameters and the output directory. (The
      ; names of the output files will be the same as the input files.)
  
  topBase = widget_auto_base(title='Filter Parameters')
  
      retBase = widget_base(topBase, /row)
      dummy   = widget_pmenu(retBase, list=returnList, default=nReturns, prompt='Select return number to use', $
                             uvalue='returnF', /auto)
  
      spaBase = widget_base(topBase, /row)
      dummy   = widget_param(spaBase, default=5, prompt='Enter canopy spacing: ', uvalue='cellF', /auto)
      
      thresBase = widget_base(topBase, /row)
      dummy   = widget_param(thresBase, default=0, prompt='Enter threshold value: ', uvalue='thresF', /auto)
      
      intBase = widget_base(topBase, /row)
      dummy   = widget_pmenu(intBase, list=interpList, default=6, prompt='Select interpolation method', $
                             uvalue='interpF', /auto)
  
      maxBase = widget_base(topBase, /row)
      dummy   = widget_param(maxBase, default=50, prompt='Enter maximum allowed height: ', uvalue='maxF', /auto)
      
      iterBase = widget_base(topBase, /row)
      dummy   = widget_param(iterBase, default=15, prompt='Maximum iteration: ', uvalue='maxI', /auto)
  
      ;dummy   = widget_outf(topBase, /directory, prompt='Select output directory', uvalue='outF', /auto)
  
  result = auto_wid_mng(topBase)
  if (result.accept eq 0) then return, files
  
  retNum     = result.returnF + 1
  baseScale  = result.cellF
  thresValue = result.thresF
  interpType = interpList[result.interpF]
  userMax    = result.maxF
  ;outputDir  = result.outF
  outputDir = baseDir + 'HeightFiltered'
  iterMax    = result.maxI
  
  ;create the directory
  FILE_MKDIR, outputDir
  
  
  
      ; Set up interpolation parameters for GRIDDATA
  
  interpFunct  = 0
  interpPower  = 0
  interpMin    = 15
  interpMax    = 10
  
  case interpType of
  
      interpList[0]  : begin
                       interpMethod = 'RadialBasisFunction'
                       interpFunct  = 3
                       interpMin    = 8
                       interpMax    = 5
                       end
      interpList[1]  : begin
                       interpMethod = 'InverseDistance'
                       interpPower  = 1
                       interpMin    = 12
                       interpMax    = 8
                       end
      interpList[2]  : begin
                       interpMethod = 'InverseDistance'
                       interpPower  = 2
                       interpMin    = 10
                       interpMax    = 5
                       end
      interpList[3]  : begin
                       interpMethod = 'InverseDistance'
                       interpPower  = 3
                       interpMin    = 15
                       interpMax    = 10
                       end
      interpList[4]  : begin
                       interpMethod = 'RadialBasisFunction'
                       interpFunct  = 0
                       end
      interpList[5]  : begin
                       interpMethod = 'Linear'
                       interpMin    = 8
                       interpMax    = 0
                       end
      interpList[6]  : begin
                       interpMethod = 'NaturalNeighbor'
                       interpMax    = 0
                       end
      interpList[7]  : begin
                       interpMethod = 'NearestNeighbor'
                       interpMax    = 0
                       end
      interpList[8]  : begin
                       interpMethod = 'PolynomialRegression'
                       interpPower  = 2
                       interpMin    = 15
                       interpMax    = 10
                       end
      interpList[9]  : begin
                       interpMethod = 'PolynomialRegression'
                       interpPower  = 3
                       interpMin    = 30
                       interpMax    = 15
                       end
      interpList[10] : begin
                       interpMethod = 'RadialBasisFunction'
                       interpFunct  = 4
                       interpMin    = 35
                       interpMax    = 25
                       end
  
  endcase
  
      ; Set up intial parameters.
  
  startTime = systime(/seconds)
  noHeight  = 2^16 - 1
  
      ; Set the maximum number of iterations for each cell.  Set up recording parameters.
  
  ;iterMax = 15
  
      ; Open processing log file
  
  openw,  logLun, outputDir + '\ProcessingNotes.txt', /get_lun, width=250
  printf, logLun, 'Interpolation Method : ', interpType
  printf, logLun, 'Grid Spacing (m) : ', baseScale
  printf, logLun, 'Threshold (m): ', thresvalue 
  printf, logLun, 'Maximum iteration: ', itermax
  printf, logLun, ' '
  
      ; Begin processesing each file
      ;create an array to store the file locations for the newly created files
  returnFiles = STRARR(N_ELEMENTS(inputFiles))
  
  for a=0,n_elements(inputFiles)-1 do begin
  
          ; Set up the profiler
  
      if doProfile then begin
  
          profiler, /reset
          profiler, /system
          profiler
  
      endif
  
  ;    infCount = 0L
  ;    badCount = 0L
  
          ; Establish the status reporting widget.  This will report the processing status
          ; for each data file.
  
      statBase = widget_auto_base(title='Filtering')
      statText = ['Filter Progress:', file_basename(inputFiles[a]), $
                  'File' + strcompress(a+1) + ' of' + strcompress(n_elements(inputFiles))]
      envi_report_init, statText, base=statBase, /interrupt, title='Filtering'
  
          ; Read the input data file.
  
      ReadLAS_BCAL, inputFiles[a], header, pData, records=records
      
          ; Record file parameters in processing notes
  
      printf, logLun, inputFiles[a]
      printf, logLun, 'Total points : ', header.nPoints
      
      GetUniqLAS_BCAL, header, pData
  
          ; Determine maximum and minimum allowable heights in data units and the minimum allowable difference.
  
      minDiff   = 0.5     / header.zScale
      maxHeight = userMax / header.zScale
      
          ; threshold
      tValue = thresValue / header.zScale
      
          ; Set all heights to noHeight, classifications to 0 (never classified)
  
      pData.source = noHeight
      pData.class  = 0
  
          ; Look for points that are statistically low outliers.  Label them as unclassified
  
      minHeight = median(pData.elev) - 8 * stddev(pData.elev)
      tooLow    = where(pData.elev lt minHeight)
  
      if tooLow[0] ne -1 then pData[tooLow].class = 1
  
          ; Determine the dimensions of the processing grid.
  
      xDim = ceil((header.xMax - header.xMin) / baseScale) + 1
      yDim = ceil((header.yMax - header.yMin) / baseScale) + 1
  
      envi_report_inc,  statBase, yDim*iterMax
  
          ; Create the data index.  The point data are referenced using 'index chunking', which
          ; is determined by the dimensions of the processing grid. Only the data whose return number
          ; has been requested are indexed.
  
      arrayHist = histogram(floor((header.yOffset - header.yMin + pData.north * header.yScale) / baseScale) * xDim $
                          + floor((header.xOffset - header.xMin + pData.east  * header.xScale) / baseScale) $
                          + xDim * yDim * ((retNum le nReturns) and ((pData.nReturn mod 8) ne retNum)) $
                          + xDim * yDim * (pData.class eq 1),  $
                          reverse_indices=arrayIndex, min=0d, max=xDim*yDim)
  
      printf, logLun, 'Points processed : ', total(arrayHist, /integer)
  
          ; Set up counter which records the number of iterations for each cell.  If the count number
          ; is greater than the current iteration, that cell requires further filtering.  Empty cells
          ; require no (0) iterations.  All occupied cells are assumed to require initialization (1) and
          ; the first filtering (2).
  
      cellCount = (arrayHist ge 1) * 2
  
          ; For each cell of the processing grid, given adequate number of points,
          ; find point of minimum elevation and label it as ground (class = 2) and
          ; set the height (source) to 0. This is the initialization, or iteration 1.
  
      for b=0L,xDim*yDim-1 do begin
  
          if arrayHist[b] ge 5 then begin
  
              index = arrayIndex[arrayIndex[b]:arrayIndex[b+1]-1]
  
              tempLow = where(pData[index].elev eq min(pData[index].elev), tempCount)
  
              pData[index[tempLow]].source = 0
              pData[index[tempLow]].class  = 2
  
                  ; If all the points are classified as ground, no further iterations are
                  ; needed, and the cell iteration count is set back to 1.
  
              if tempCount eq arrayHist[b] then cellCount[b] = 1
  
          endif
  
      endfor
  
      envi_report_stat, statBase, yDim, yDim*iterMax, cancel=cancel
  
          ; Iterate over the entire array, cell by cell
  
      nIter = 1
  
      repeat begin
  
          nIter++
  
              ; Begin filtering the data, one cell at a time for the entire processing grid.
  
          j = 0L
  
          for g=0L,yDim-1 do begin
          for f=0L,xDim-1 do begin
  
                  ; Check to see if the grid cell requires filtering.
  
              if cellCount[j] eq nIter then begin
  
                      ; Get the points in the cell.  Determine which points are non-ground.
  
                  index = arrayIndex[arrayIndex[j]:arrayIndex[j+1]-1]
  ;                index = GetIndex_BCAL(f,g,xDim,yDim,arrayIndex,0)
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
  
                      ; Check for "holes" by comparing the interpolated surface to the ground points.  If they
                      ; exist, increase the cell count number, invoking further iteration.  If not, continue.
  
                  if min(interpLocal) lt (min(pData[surround].elev) - minDiff) then cellCount[j]++ $
                                                                               else begin
  
                          ; Determine the vegetation heights of the non-ground points and check
                          ; for negative heights.
  
                      heights = pData[index].elev - interpLocal
  
                      low     = where(heights le (tValue/nIter), lowCount, ncomplement=highCount)
  
                          ; Proceed based on whether or not some interpolated points have non-positive values
  
                      if lowCount then begin
  
                              ; If some positive heights exist, reclassify points with zero or negative heights
                              ; as ground points and increase the cell count number, invoking further iteration.
                              ; If all points in the cell have zero or negative height (signified by
                              ; highCount equaling zero), record the height and classify as bare ground.
  
                          if highCount then begin
                              pData[index[low]].source = 0
                              pData[index[low]].class  = 2
                              cellCount[j]++
                          endif else begin
                              pData[index].source = 0
                              pData[index].class  = 2
                          endelse
  
                      endif else begin
  
                              ; If all heights are positive (signified by lowCount equaling zero), record the
                              ; heights and classify.
  
                          pData[index].source = round(heights)
                          pData[index].class  = 3
  
                              ; Check for heights above the maximum.
                              ; If they exist, increase the cell count number, invoking further iteration.
  
                          if max(heights) gt maxHeight then cellCount[j]++
  
                      endelse
  
                  endelse
  
              endif
  
              j++
  
          endfor
  
          envi_report_stat, statBase, g + yDim*nIter, yDim*iterMax, cancel=cancel
          if cancel then begin
              envi_report_init, base=statBase, /finish
              return, files
          endif
  
          endfor
  
      endrep until ((nIter eq iterMax) or (max(cellCount) eq nIter))
  
      envi_report_stat, statBase, yDim*iterMax, yDim*iterMax, cancel=cancel
  
          ; Begin checking for bad points or unprocessed cells.
  
          ; Check for infinite values, flag as unclassified
  
      inf = where(finite(pData.source) eq 0, infCount)
      if infCount then begin
          pData[inf].source = noHeight
          pData[inf].class  = 1
      endif
  
          ; Check for values that are too large, flag as unclassified
  
      bad = where(abs(pData.source) gt maxHeight, badCount)
      if badCount then begin
          pData[bad].source = noHeight
          pData[bad].class  = 1
      endif
  
          ; Count the total number of points in all the cells that didn't finish processing
  
      unf = where(cellCount gt iterMax)
      if (unf[0] ne -1) then unfnCount = total(arrayHist[unf],/integer) $
                        else unfnCount = 0
  
          ; Record processing notes
  
      dummy = where(pData.class eq 0, unprCount)
      dummy = where(pData.class eq 1, unclCount)
      dummy = where(pData.class eq 2, grndCount)
      dummy = where(pData.class eq 3, vegeCount)
  
      printf, logLun, 'Total unprocessed points : ',  unprCount
      printf, logLun, 'Total unclassified points : ', unclCount
      printf, logLun, 'Total unfinished points : ',   unfnCount
      printf, logLun, 'Total ground points : ',       grndCount
      printf, logLun, 'Total vegetation points : ',   vegeCount
      printf, logLun, 'Iteration count (cells) : '
      printf, logLun, histogram(cellCount, max=iterMax+1)
      printf, logLun, 'Infinite count (total) : ', infCount
      printf, logLun, 'Bad count (total) : ', badCount, ' (', float(badCount) / header.nPoints, ')'
      printf, logLun, 'Processing time : ', systime(/seconds) - startTime
      printf, logLun, ' '
  
          ; Write the header and data to a new file in the output directory
      
      outputFile = outputDir + '\' + file_basename(inputFiles[a])
      WriteLAS_BCAL, outputFile, header, pData, records=records, /check
  
      returnFiles[a] = outputFile
          ; Clear up some memory
  
      pData      = 0B
      arrayHist  = 0B
      arrayIndex = 0B
      cellCount  = 0B
  
  
      envi_report_init, base=statBase, /finish
  
          ; Write the profile report
  
      if doProfile then begin
  
          profiler, /report, output=profOut
  
          openw,    proLun, outputDir + '\' + file_basename(inputFiles[a], '.las') + '.txt', /get_lun, width=250
          printf,   proLun, transpose(profOut)
          free_lun, proLun
  
      endif
  
  endfor
  
      ; Close the processing log.
  
  free_lun, logLun
  return, returnFiles
end

function PrepareData, files, baseDir
  
  inputFiles = files 
  
  
  nFiles = n_elements(inputFiles)
  
      ; Get the reference RGB image
  
  envi_select, fid=refID, /file_only, /no_dims, pos=demPos, $
          title='Select bare-earth DEM'
  if (refID[0] eq -1) then return, files
  
  While  (n_elements(demPos) ne 1) do begin
  
      dummy = dialog_message('Please select only one spectral band', /error)
      envi_select, fid=refID, /file_only, /no_dims, pos=demPos, $
              title='Select bare-earth DEM'
      if (refID[0] eq -1) then return, files
  
  endwhile
  
  envi_file_query, refID, ns=ns, nl=nl, data_type=dtype
      ; Output LAS file(s)
      
  ;tempDir = dialog_pickfile(title='Select output directory', /directory, /path)
  ;if (tempDir eq '') then return
  
  tempDir = baseDir + '\HeightFiltered'
  FILE_MKDIR, tempDir
  
  returnFiles = STRARR(nFiles)
  
  noHeight  = 2^16 - 1
  
      ; Set up status message window
  
  statText  = 'Preparing'
  statBase  = widget_auto_base(title='Preparing LAS file')
  statField = widget_text(statBase, /scroll, value=statText, xsize=80, ysize=4)
  widget_control, statBase, /realize
  
  
  for a=0,nFiles-1 do begin
  
             ; Update the status window
  
      statText = ['Preparing ' + inputFiles[a] + ' (' + strcompress(a+1,/remove) $
                                              + '/'  + strcompress(nFiles,/remove) + ')', statText]
      widget_control, statField, set_value=statText
      
      
  
      ReadLAS_BCAL, inputFiles[a], header, pData, projection=defProj
      
      envi_convert_file_coordinates, refID, xImage, yImage, $
                pdata.east  * header.xScale + header.xOffset, $
                pdata.north * header.yScale + header.yOffset
                
      imgRoi = envi_create_roi(ns=ns, nl=nl, /no_update)
      envi_define_roi, imgRoi, /no_update, /point, xpts=xImage, ypts=yImage
  
      pData.source = pData.elev - (envi_get_roi_data(imgRoi, fid=refID, pos=demPos[0])/ header.zScale)
      
      bare = where(pData.class eq 2, bareCount)
      if bareCount then pData[bare].source = 0
      
      maxHeight = 100 / header.zScale
      bad = where(abs(pData.source) gt maxHeight, badCount)
      if badCount then pData[bad].source = 0
      
      neg = where(pData.source lt 0, negCount) 
      if negCount then pData[neg].source = 0
      
      outputFile = tempDir + '\' + file_basename(inputFiles[a])
      WriteLAS_BCAL, outputFile, header, pData, /check
      returnFiles[a] = outputFile
  endfor
  
      ; Destroy the status window
  
  widget_control, statBase, /destroy
  return, returnFiles
end