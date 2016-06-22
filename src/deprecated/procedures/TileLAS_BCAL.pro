;+
; NAME:
;
;       TileLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to separate one or more LAS files into a set of tiles, the
;       number of which are determined by the user.
;
; PRODUCTS:
;
;       The products are a set of LAS files that are separated into tiles.
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
;       WriteLAS_BCAL.pro
;       InitDataLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, April 2006.
;       Added support for "large" files, August 2006.
;       Added support for embedded projection, June 2007
;       Added ability to handle large number of tiles, June 2010 (Rupesh Shrestha).
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

pro TileLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish error handler.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    return
endif

    ; Open input files

inputFiles = dialog_pickfile(title='Select LiDAR file(s)', filter='*.las', /multiple_files)
    if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Get the overall min and max coordinates

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

readBase = widget_auto_base(title='Data Tiling')

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

    outputBase  = widget_base(readBase, /row)
    fileBase    = widget_base(outputBase, /column)
    outputField = widget_outf(fileBase, prompt='Select output directory ', /directory, $
                              uvalue='lasName', /auto)

result = auto_wid_mng(readBase)
if (result.accept eq 0) then return

xNum = result.tiles[0]
yNum = result.tiles[1]

xMin = result.xMin
xMax = result.xMax
yMin = result.yMin
yMax = result.yMax

xRange = xMax - xMin
yRange = yMax - yMin

outputDir = result.lasName

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
tileReturns = lonarr(5, nTiles)
tileExtent = dblarr(nTiles,3,2)
tileExtent[*,*,0] = 10e8

sampSize = 1d5

    ; Process the input files

for a=0,nFiles-1 do begin

       ; Update the status window

    statBase = widget_auto_base(title='Tiling')
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
        
        ; This is necessary if input files have different scale and offsets
        
        data.east  = (x - outputheader.xoffset) / outputheader.xScale
        data.north = (y - outputheader.yoffset) / outputheader.yScale
        data.elev  = (z - outputheader.zoffset) / outputheader.zScale

        for c=0,nTiles-1 do begin

            if tileHist[c] ne 0 then begin
            
                outputFile = outputDir + '\Tile_' + strcompress(c+1,/remove) + '.las'

                        ; Leave the files open to append the data

                openw, clun, outputFile, /swap_if_big_endian, /append, /get_lun
                writeu, clun, data[index[index[c]:index[c+1]-1]]

                tilePoints[c] += tileHist[c]
                
                if n_elements(data[index[index[c]:index[c+1]-1]]) gt 1 then $
                tileReturns[*,c] += histogram((data[index[index[c]:index[c+1]-1]].nReturn mod 8), min=1, max=5)

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
            return
        endif

    endfor

        ; Destroy the status window

    envi_report_init, base=statBase, /finish
    
    free_lun, inputLun
    
endfor

close, /all

    ; Update the headers of each of the output tile files

for t=0,yNum-1 do begin
for s=0,xNum-1 do begin

    updateLun = s + (t * xNum)

        ; Set necessary header parameters

    outputHeader.nPoints     = tilePoints[updateLun]
    outputHeader.nReturns    = tileReturns[*,updateLun]

        ; Set mins & maxs

    outputHeader.xMin = tileExtent[updateLun,0,0]
    outputHeader.xMax = tileExtent[updateLun,0,1]
    outputHeader.yMin = tileExtent[updateLun,1,0]
    outputHeader.yMax = tileExtent[updateLun,1,1]
    outputHeader.zMin = tileExtent[updateLun,2,0]
    outputHeader.zMax = tileExtent[updateLun,2,1]
    
    outputFile = outputDir + '\Tile_' + strcompress(updateLun+1,/remove) + '.las'

        ; Update file headers

    openu,     hlun, outputFile, /get_lun
    point_lun, hLun, 0
    writeu,    hLun, outputHeader
    free_lun,  hLun
    
        ; Delete any empty files

    if tilePoints[updateLun] eq 0 then file_delete, outputFile


endfor
endfor

close, /all
end


;NOTES:
;-uniqueness
