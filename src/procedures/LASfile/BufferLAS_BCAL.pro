;+
; NAME:
;
;       BufferLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to buffer an LAS file by a distance determined by the
;       user.  Points are copied from neighboring files to create the buffer.
;
; PRODUCTS:
;
;       The product is an LAS file which contains points from the neighboring files out to a buffer
;       distance determined by the user.  Multiple files can be processed at once.  The result of using
;       this procedure on a set of neighboring files is that the resulting files will all overlap each
;       other by the buffer distance.
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
;       InitHeaderLAS_BCAL.pro
;       ReadLAS_BCAL.pro
;       GetBounds_BCAL.pro
;       ScalePoly_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, June 2006.
;       Added support for embedded projections, June 2007
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

pro BufferLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish error handler.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    return
endif

    ; Get the input file(s)

files = dialog_pickfile(title='Select LAS file(s) to buffer', filter='*.las', /fix, /must_exist, /multiple)
if (files[0] eq '') then return

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

readBase  = widget_auto_base(title='Set Buffer Parameters', /xbig)

    buffBase = widget_base(readBase, /row)
    dummy    = widget_param(buffBase, default=bDefault, dt=5, field=bField, floor=0, prompt=bPrompt, uvalue='buffer', /auto)

    outBase  = widget_base(readBase, /row)
    fileBase = widget_base(outBase, /column)
    dummy    = widget_outf(fileBase, prompt='Select output directory', /directory, uvalue='lasName', /auto_manage)

result = auto_wid_mng(readBase)
if result.accept eq 0 then return

bDist = replicate(result.buffer,2)

outputDir = result.lasName

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
statBase  = widget_auto_base(title='Buffering Status')
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


for b=0,nFiles-1 do begin

    statText = ['Buffering ' + files[b] + ' (' + strcompress(b+1,/remove) $
                                        + '/'  + strcompress(nFiles,/remove) + ')', statText]
    widget_control, statField, set_value=statText

        ; Copy the input file to the output directory.

    outputFile = outputDir + '\' + file_basename(files[b])
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


end

