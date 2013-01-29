;This file is for preprocessing the data by Tiling and buffering the data as necessary

function Preprocess_Data, fileName
  
  ;Now get the file info
  FileData = FILE_INFO(fileName)
  ;file size in bytes
  
  FileSize = FileData.Size
  maxSize = 200000000
  IF (FileSize GT maxSize) THEN BEGIN  
   
   ;!!!!!!!Testing Code!!!!!!!!
   ;TestDir = DirectoryFromFile(fileName)
   ;TestDir = TestDir + 'Buffered\*'   
   
   ;files = FILE_SEARCH(TestDir)
   ;return, files
   ;!!!!!!!Testing Code End!!!!!!!!!!
   
   
   ;We need to tile the data and buffer it as well
   inputFiles = STRARR(1)
   inputFiles[0] = fileName
   ;get the base directory from the input files
   
   outputDir = DirectoryFromFile(inputFiles[0])  
   
   TiledFiles = TileFile(inputFiles, STRTRIM(outputDir))
   ProcedFiles = BufferFiles(TiledFiles, STRTRIM(outputDir))
   return, ProcedFiles
   
  ENDIF ELSE BEGIN
    ;just set up an array and return the one file in it
    ProcedFiles = STRARR(1)
    ProcedFiles[0] = fileName
    return, ProcedFiles
  ENDELSE  
  
end

function TileFile, inputFiles, outputDir
  compile_opt idl2, logical_predicate
  
  ;Create an invisible group leader
  groupleader = Widget_Base(Map=0)
  Widget_Control, groupleader, /Realize
  destroy_groupleader = 1
  
  nFiles = n_elements(inputFiles)
  for d=0,nFiles-1 do begin

    ReadLAS_BCAL, inputFiles[d], inputHeader, records=records, /nodata

    if d eq 0 then begin

        xMin = inputHeader.xMin
        xMax = inputHeader.xMax
        yMin = inputHeader.yMin
        yMax = inputHeader.yMax

    endif else begin

        xMin <= inputHeader.xMin
        xMax >= inputHeader.xMax
        yMin <= inputHeader.yMin
        yMax >= inputHeader.yMax

    endelse

  endfor

    ; Get the user parameters

  readBase = widget_auto_base(title='Data Tiling', GROUP=groupleader)
    ;readBase = widget_base(title='Data Tiling')

    tileBase = widget_base(readBase, /row)
    dummy    = widget_edit(tileBase, dt=2, floor=1, list=['Number of tile columns:','Number of tile rows:'], $
                           prompt='Tiling dimensions:', vals=[1,1], ysize=2, uvalue='tiles', /auto)

;    dummy = widget_param(readBase, default=20, dt=5, floor=0, prompt='Select buffer distance (m)', uvalue='buffer', /auto)

    subBase  = widget_base(readBase, /row)
    xBase    = widget_base(subBase, /col)
    dummy    = widget_param(xBase, default=xMin, dt=5, prompt='Minimum Easting:',  uvalue='xMin', xs=17, /auto)
    dummy    = widget_param(xBase, default=xMax, dt=5, prompt='Maximum Easting:',  uvalue='xMax', xs=17, /auto)
    yBase    = widget_base(subBase, /col)
    dummy    = widget_param(yBase, default=yMin, dt=5, prompt='Minimum Northing:', uvalue='yMin', xs=17, /auto)
    dummy    = widget_param(yBase, default=yMax, dt=5, prompt='Maximum Northing:', uvalue='yMax', xs=17, /auto)    

  result = auto_wid_mng(readBase)
  if (result.accept eq 0) then  begin
    return, inputFiles
  endif
  
  xNum = result.tiles[0]
  yNum = result.tiles[1]
  
  xMin = result.xMin
  xMax = result.xMax
  yMin = result.yMin
  yMax = result.yMax
  
  xRange = xMax - xMin
  yRange = yMax - yMin
  
 
  ;add the tiled directory tag
  outputDir = OutputDir + 'Tiled'
  ;Create the directory if it does not exist
  FILE_MKDIR, OutputDir
  
  ;get rid of group leader
  WIDGET_CONTROL, groupleader, /DESTROY
  
      ; Determine the size of the individual tiles
  
  xDiv = xRange / xNum
  yDiv = yRange / yNum
  
      ; Create header structure for tile files. Set ID and creation date.
  
  outputHeader = inputHeader
  
  outputHeader.softwareID = byte('LidarTools, IDL ' + !version.release)
  
  date = bin_date(systime(/utc))
  day  = julday(date[1],date[2],date[0]) - julday(1,1,date[0]) + 1
  outputHeader.day  = uint(day)
  outputHeader.year = uint(date[0])
  
  
  
      ; Initialize individual tile files
  
  for g=0,yNum-1 do begin
    for f=0,xNum-1 do begin
        
        fileLun = f + (g * xNum) + 1
    
        outputFile = outputDir + '\Tile_' + strcompress(fileLun,/remove) + '.las'
    
        WriteLAS_BCAL, outputFile, outputHeader, records=records, /nodata, /check
    
    endfor
  endfor
  
  
  
      ; Initialize various parameters
  
  nTiles     = xNum * yNum
  tilePoints = lonarr(nTiles)
  tileExtent = dblarr(nTiles,3,2)
  tileExtent[*,*,0] = 10e8
  
  sampSize = 1d5
  
      ; Process the input files
  
  for a=0,nFiles-1 do begin
  
         ; Update the status window
     ;Create an invisible group leader
     groupleader2 = Widget_Base(Map=0)
     Widget_Control, groupleader2, /Realize
     destroy_groupleader = 1
     
      statBase = widget_auto_base(title='Tiling', GROUP=groupleader2)      
      statText = ['Tiling Progress: ', file_basename(inputFiles[a]), $
                  'File' + strcompress(a+1) + ' of' + strcompress(n_elements(inputFiles))]
      envi_report_init, statText, base=statBase, /interrupt, title='Tiling'
  
          ; The input file will be read in chunks.  Determine how many are needed and the number of
          ; records that will remain in the final one.
  
      ReadLAS_BCAL, inputFiles[a], header, /nodata
  
      nSamp    = ceil(header.nPoints / sampSize)
      leftSize = header.nPoints - sampSize * (nSamp - 1)
  
      dataTemp = InitDataLAS_BCAL(pointFormat=header.pointFormat)
  
      openr, inputLun, inputFiles[a], /get_lun, /swap_if_big_endian
      point_lun, inputLun, header.dataOffset
  
      envi_report_inc,  statBase, nSamp
  
          ; Determine to which tile each point belongs and copy it to the file
  
      for b=0L,nSamp-1 do begin
  
          if b eq (nSamp-1) then data = replicate(dataTemp, leftSize) $
                            else data = replicate(dataTemp, sampSize)
  
          readu, inputLun, data
  
          data = data[where(data.east  ge ((xMin - header.xOffset) / header.xScale) and $
                            data.east  le ((xMax - header.xOffset) / header.xScale) and $
                            data.north ge ((yMin - header.yOffset) / header.yScale) and $
                            data.north le ((yMax - header.yOffset) / header.yScale))]
  
          x = data.east  * header.xScale + header.xOffset
          y = data.north * header.yScale + header.yOffset
          z = data.elev  * header.zScale + header.zOffset
  
          tileCoord = xNum * (0 > floor((y - yMin) / yDiv) < (yNum - 1)) $
                           + (0 > floor((x - xMin) / xDiv) < (xNum - 1))
  
          tileHist = histogram(tileCoord, min=0, max=nTiles-1, reverse_indices=index)
  
          for c=0,nTiles-1 do begin
  
              if tileHist[c] ne 0 then begin
              
                  outputFile = outputDir + '\Tile_' + strcompress(c+1,/remove) + '.las'
  
                          ; Leave the files open to append the data
  
                  openw, clun, outputFile, /swap_if_big_endian, /append, /get_lun
                  writeu, clun, data[index[index[c]:index[c+1]-1]]
  
                  tilePoints[c] += tileHist[c]
  
                  tileExtent[c,0,0] <= min(x[index[index[c]:index[c+1]-1]], max=xMaxTemp)
                  tileExtent[c,0,1] >= xMaxTemp
                  tileExtent[c,1,0] <= min(y[index[index[c]:index[c+1]-1]], max=yMaxTemp)
                  tileExtent[c,1,1] >= yMaxTemp
                  tileExtent[c,2,0] <= min(z[index[index[c]:index[c+1]-1]], max=zMaxTemp)
                  tileExtent[c,2,1] >= zMaxTemp
                  
                  free_lun, clun
  
              endif
  
          endfor
  
          envi_report_stat, statBase, b, nSamp, cancel=cancel
          if cancel then begin
              envi_report_init, base=statBase, /finish
              close, /all
              return, inputFiles
          endif
  
      endfor
  
          ; Destroy the status window
  
      envi_report_init, base=statBase, /finish
      WIDGET_CONTROL, groupleader2, /DESTROY
      free_lun, inputLun
      
  endfor
  
  close, /all
  
      ; Update the headers of each of the output tile files
  TiledFiles = Strarr(xNum*yNum)
  fCount = 0
  for t=0,yNum-1 do begin
    for s=0,xNum-1 do begin
    
        updateLun = s + (t * xNum)
    
            ; Set necessary header parameters
    
        outputHeader.nPoints     = tilePoints[updateLun]
        outputHeader.nReturns[0] = tilePoints[updateLun]
    
            ; Set mins & maxs
    
        outputHeader.xMin = tileExtent[updateLun,0,0]
        outputHeader.xMax = tileExtent[updateLun,0,1]
        outputHeader.yMin = tileExtent[updateLun,1,0]
        outputHeader.yMax = tileExtent[updateLun,1,1]
        outputHeader.zMin = tileExtent[updateLun,2,0]
        outputHeader.zMax = tileExtent[updateLun,2,1]
        
        outputFile = outputDir + '\Tile_' + strcompress(updateLun+1,/remove) + '.las'
    ;    outputFile = outputDir + '\' + strcompress(s+1,/remove) + '_' + strcompress(t+1,/remove) + '.las'
    
            ; Update file headers
    
        openu,     hlun, outputFile, /get_lun
        point_lun, hLun, 0
        writeu,    hLun, outputHeader
        free_lun,  hLun
        
            ; Delete any empty files
    
        if tilePoints[updateLun] eq 0 then file_delete, outputFile
    
        TiledFiles[fCount] = outputFile
        fCount = fCount + 1
    endfor
  endfor
  close, /all
  return, TiledFiles
end

function BufferFiles, files, outputDir

  compile_opt idl2, logical_predicate
  ;Create an invisible group leader
  groupleader = Widget_Base(Map=0)
  Widget_Control, groupleader, /Realize
  destroy_groupleader = 1
  
  nFiles = n_elements(files)

    ; Get the horizontal units

  ReadLAS_BCAL, files[0], header, projection=defProj, /nodata
  
  bPrompt  = 'Select buffer distance (meters): '
  bDefault = 20
  bField   = 1
  
  if n_tags(defProj) then begin
  
      bUnits  = strlowcase(envi_translate_projection_units(defProj.units))
      bPrompt = 'Select buffer distance (' + bUnits + '): '
      if bUnits eq 'degrees' then begin
          bDefault = 0.001D
          bField   = 5
      endif
  
  endif
  
      ; Get the buffer distance and output directory
  
  readBase  = widget_auto_base(title='Set Buffer Parameters', /xbig, GROUP=groupleader)
  
      buffBase = widget_base(readBase, /row)
      dummy    = widget_param(buffBase, default=bDefault, dt=5, field=bField, floor=0, prompt=bPrompt, uvalue='buffer', /auto)
  
      
  result = auto_wid_mng(readBase)
  if result.accept eq 0 then return, files
  
  bDist = replicate(result.buffer,2)
  
  ;add the tiled directory tag
  outputDir = OutputDir + 'Buffered'
  ;Create the directory if it does not exist
  FILE_MKDIR, OutputDir
  
      ; Reorder the files from largest to smallest
  
  fileSize = (file_info(files)).size
  files = files[reverse(sort(fileSize))]
  
      ; Create a structure to hold data from all buffer files
  
  header = InitHeaderLAS_BCAL()
  
  coords  = ptrarr(nFiles, /allocate_heap)   ; absolute coordinates of boundary polygons
  outer   = ptrarr(nFiles, /allocate_heap)   ; absolute coordinates of outer boundary polygons
  inner   = ptrarr(nFiles, /allocate_heap)   ; absolute coordinates of inner boundary polygons
  buffers = ptrarr(nFiles, /allocate_heap)   ; arrays of data points within the buffer zone
  headers = replicate(header, nFiles)        ; file headers
  
      ; Set up status message window
  
  statText  = 'Initializing'
  statBase  = widget_auto_base(title='Buffering Status', GROUP=groupleader)
  statField = widget_text(statBase, /scroll, value=statText, xsize=80, ysize=4)
  widget_control, statBase, /realize
  
      ; For each of the buffer files, find and save points which lie within the buffer zones
  
  for a=0,nFiles-1 do begin
  
          ; Read the buffer file and determine the boundary points
  
      statText = ['Reading ' + files[a] + ' (' + strcompress(a+1,/remove) $
                                        + '/'  + strcompress(nFiles,/remove) + ')', statText]
      widget_control, statField, set_value=statText
  
      ReadLAS_BCAL, files[a], header, data
      headers[a] = header
  
      bounds = GetBounds_BCAL(data.east, data.north)
  
      tempCoords = transpose([[data[bounds].east  * header.xScale + header.xOffset], $
                              [data[bounds].north * header.yScale + header.yOffset]])
  
          ; Save the boundary coordinates, as well as the inner and outer boundary coordinates
  
     *coords[a] = tempCoords
     *inner[a]  = ScalePoly_BCAL(tempCoords, -1*bDist)
     *outer[a]  = ScalePoly_BCAL(tempCoords,    bDist)
  
          ; Create the inner boundary object
  
      innerBound  = Obj_New('IDLanROI', *inner[a])
  
          ; Get the points that are outside the inner boundary
  
      buffer = where(~ innerBound->ContainsPoints(data.east  * header.xScale + header.xOffset, $
                                                  data.north * header.yScale + header.yOffset))
  
          ; Record buffer data points in info structure
  
     *buffers[a] = data[buffer]
  
      data = 0B
  
  endfor
  
  ;create an array holding the buffered filenames
  BufferedFiles = STRARR(nFiles) 
  
  for b=0,nFiles-1 do begin
  
      statText = ['Buffering ' + files[b] + ' (' + strcompress(b+1,/remove) $
                                          + '/'  + strcompress(nFiles,/remove) + ')', statText]
      widget_control, statField, set_value=statText
  
          ; Copy the input file to the output directory.
  
      outputFile = outputDir + '\' + file_basename(files[b])
      BufferedFiles[b] = outputFile ;save the file to an array
      file_copy, files[b], outputFile, /allow_same, /overwrite
  
          ; Read the input file header, and copy it for use with the output file
  
      outputHeader = headers[b]
  
          ; Open the output file for appending
  
      openw, outputLun, outputFile, /append, /get_lun, /swap_if_big_endian
  
          ; Expand the boundary coordinates by amount equal to the buffer and create an
          ; outer boundary object
  
      outerBound = Obj_New('IDLanROI', *outer[b])
  
          ; Check each of the other buffer structures for points within the current file's buffer
  
      for c=0,nFiles-1 do begin
  
              ; Make sure the buffer structure corresponding to the input file is not used
  
          if c ne b then begin
  
                  ; Find the points in the buffer structure of the other files that are within
                  ; the outer boundary polygon of the current file
  
              temp = where(outerBound->ContainsPoints( $
                           (*buffers[c]).east  * headers[c].xScale + headers[c].xOffset, $
                           (*buffers[c]).north * headers[c].yScale + headers[c].yOffset), count)
  
                  ; If data exists, append to the file.
  
              if count then begin
  
                  writeu, outputLun, (*buffers[c])[temp]
  
                      ; Update the various header fields
  
                  outputHeader.nPoints += count
  
                  outputHeader.xMax >= max((*buffers[c])[temp].east)  * headers[c].xScale + headers[c].xOffset
                  outputHeader.xMin <= min((*buffers[c])[temp].east)  * headers[c].xScale + headers[c].xOffset
                  outputHeader.yMax >= max((*buffers[c])[temp].north) * headers[c].yScale + headers[c].yOffset
                  outputHeader.yMin <= min((*buffers[c])[temp].north) * headers[c].yScale + headers[c].yOffset
                  outputHeader.zMax >= max((*buffers[c])[temp].elev)  * headers[c].zScale + headers[c].zOffset
                  outputHeader.zMin <= min((*buffers[c])[temp].elev)  * headers[c].zScale + headers[c].zOffset
  
              endif
  
          endif
  
      endfor
  
      print, ' '
  
          ; Update header fields
  
      outputHeader.softwareID = byte('IDL ' + !version.release)
  
      date = bin_date(systime(/utc))
  
      outputHeader.day  = uint(julday(date[1],date[2],date[0]) - julday(1,1,date[0]) + 1)
      outputHeader.year = uint(date[0])
  
          ; Rewrite the output header and close the file
  
      point_lun, outputLun, 0
      writeu,    outputLun, outputHeader
      free_lun,  outputLun
  
  endfor

    ; Destroy the status window
  widget_control, statBase, /destroy
  return, BufferedFiles
  

end