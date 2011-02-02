;+
; NAME:
;
;       SubsetLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to subset the point data from a LiDAR .las file.
;       It is meant to be run through ENVI.  The data are subset by either using coordinates
;       input by the user or using a reference image/ROI via ENVI's subset procedure.
;       Multiple files can be selected, but will be output into a single, combined .las file.
;
; PRODUCTS:
;
;       The output is a new .las file which contains the points within the region specified by
;       the user.
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
;       InitHeaderLAS_BCAL.pro
;       WriteLAS_BCAL.pro
;
; KNOWN ISSUES:
;
;       If multiple .las files are loaded that have different data pointFormats,
;       this will probably break.
;
;       Cannot cancel once processing has begun.
;
;       No EVF support.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
;       Updated to allow for directional scale & offset, February 2007
;       Updated to handle large output files, March 2007
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

pro SubsetLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish an error handler.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error creating file')
    return
endif

    ; Get the file(s) to be subset.

inputFiles = envi_pickfile(title='Select LAS file(s) to subset', filter='*.las', /multiple_files)
if (inputFiles[0] eq '') then return

if n_elements(inputFiles) eq 1 then defName = file_basename(inputFiles[0]) else defName = 'output.las'

    ; Initialize ROI flag

doRoi = 0

    ; Get subset parameters based on type requested

widget_control, event.id, get_uvalue=subsetType

case subsetType of

    'subsetROI': begin

            ; Get the reference image file

        envi_select, fid=refID, /file_only, /no_spec, /no_dims, title='Select Reference Image'
        if (refID[0] eq -1) then return

            ; Get the subset parameters

        subBase = widget_auto_base(title='Select Subset')
        dummy   = widget_subset(subBase, fid=refID, /roi, xs=40, uvalue='sub', /auto)
        dummy   = widget_outf(subBase, default=defName, prompt='Enter name of output LAS file ', $
                              uvalue='out', /auto)

        result  = auto_wid_mng(subBase)
        if (result.accept eq 0) then return

        refDims    = result.sub
        outputFile = result.out

            ; Get the spatial parameters of the selected image file

        envi_file_query, refID, ns=xDim, nl=yDim
        refInfo = envi_get_map_info(fid=refID)
        xRes = refInfo.ps[0]
        yRes = refInfo.ps[1]

        fileMin = refInfo.mc[2:3]

            ; Check to see if an ROI was selected

        if refDims[0] ne -1 then begin

                ; Get ROI addresses

            roiIndex = envi_get_roi(refDims[0])

                ; Find min/max file coordinates from addresses

            subMax = max(array_indices([xDim,yDim], roiIndex, /dimensions), min=subMin, dimension=2)

                ; Set ROI flag

            doRoi = 1

        endif else begin

                ; Get min/max file coordinates from dimensions returned

            subMax = [refDims[2],refDims[4]]
            subMin = [refDims[1],refDims[3]]

        endelse

            ; Convert min/max file coordinates to map coordinates.  Note that the file coordinates
            ; are referenced from the UPPER left corner

        envi_convert_file_coordinates, refID, subMin[0], subMax[1], xMin, yMin, /to_map
        envi_convert_file_coordinates, refID, subMax[0], subMin[1], xMax, yMax, /to_map

    end

    'subsetCoords': begin

            ; For each file, read the header and establish minimum and
            ; maximum extents

        for a=0,n_elements(inputFiles)-1 do begin

            ReadLAS_BCAL, inputFiles[a], header, /nodata

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

            ; Create the widget that will record the user parameters.

        subBase = widget_auto_base(title='Set Subset Parameters')
        rowBase = widget_base(subBase, /row)
        xBase   = widget_base(rowBase, /col)
        dummy   = widget_param(xBase, default=xMin, dt=5, prompt='Minimum Easting:',  uvalue='xMin', xs=17, /auto)
        dummy   = widget_param(xBase, default=xMax, dt=5, prompt='Maximum Easting:',  uvalue='xMax', xs=17, /auto)
        yBase   = widget_base(rowBase, /col)
        dummy   = widget_param(yBase, default=yMin, dt=5, prompt='Minimum Northing:', uvalue='yMin', xs=17, /auto)
        dummy   = widget_param(yBase, default=yMax, dt=5, prompt='Maximum Northing:', uvalue='yMax', xs=17, /auto)

        dummy   = widget_outf(subBase, default=defName, prompt='Enter name of output LAS file ', $
                              uvalue='out', /auto)

        result  = auto_wid_mng(subBase)
        if (result.accept eq 0) then return

        xMin = result.xMin
        xMax = result.xMax
        yMin = result.yMin
        yMax = result.yMax

        outputFile = result.out

    end

endcase

    ; Check to make sure the coordinates make sense.

if xMax le xMin then begin
    dummy = dialog_message('The maximum easting is less than or equal to the minimum easting.', /center, /error)
    return
endif
if yMax le yMin then begin
    dummy = dialog_message('The maximum northing is less than or equal to the northing easting.', /center, /error)
    return
endif

    ; Initialize a header for the output file

outHeader = InitHeaderLAS_BCAL()

outHeader.systemID = byte('Subset')

    ; Set parameters based on the first input file

ReadLAS_BCAL, inputFiles[0], header, records=records, /nodata

outHeader.pointFormat  = header.pointFormat
outHeader.versionMinor = header.versionMinor

outHeader.xScale = header.xScale
outHeader.yScale = header.yScale
outHeader.zScale = header.zScale

outHeader.xOffset = header.xOffset
outHeader.yOffset = header.yOffset
outHeader.zOffset = header.zOffset

outHeader.xMin =  1e7
outHeader.yMin =  1e7
outHeader.zMin =  1e7
outHeader.xMax = -1e7
outHeader.yMax = -1e7
outHeader.zMax = -1e7

    ; Write the header and variable records to the output file.  (The header will be updated at the end.)
    ; Leave the file open to append the data.

WriteLAS_BCAL, outputFile, outHeader, records=records, /nodata, /check

openw, outputLun, outputFile, /get_lun, /swap_if_big_endian, /append

    ; Set up status widget

statText  = 'Initializing'
statBase  = widget_auto_base(title='Subset Status')
statField = widget_text(statBase, /scroll, value=statText, xsize=50, ysize=4)
widget_control, statBase, /realize

    ; Begin subsetting, file by file

for b=0,n_elements(inputFiles)-1 do begin

        ; Read the header, and check if the data in the file falls within the specified area.
        ; If so, continue.

    ReadLAS_BCAL, inputFiles[b], header, /nodata

    if header.xMin le xMax and header.xMax ge xMin and $
       header.yMin le yMax and header.yMax ge yMin then begin

            ; Read the data file.

        statText = ['Reading ' + file_basename(inputFiles[b]),statText]
        widget_control, statField, set_value=statText
        ReadLAS_BCAL, inputFiles[b], header, data, /check

            ; Find the data within the file that fall within the specified area.  If such data
            ; exists, continue.

        statText = ['Subsetting ' + file_basename(inputFiles[b]),statText]
        widget_control, statField, set_value=statText
        subset = where(((data.east  * header.xScale + header.xOffset) ge xMin) and $
                       ((data.east  * header.xScale + header.xOffset) le xMax) and $
                       ((data.north * header.yScale + header.yOffset) ge yMin) and $
                       ((data.north * header.yScale + header.yOffset) le yMax))

        if subset[0] ne -1 then begin

                ; If an ROI is used, then further subsetting is required

            if doRoi then begin

                    ; Create the data index.  The point data are referenced using 'index chunking', which
                    ; is determined by the extent and dimensions of the reference image.  These indices
                    ; will match the format of those returned by envi_get_roi()

                arrayHist = histogram(floor((fileMin[1] - header.yOffset - data[subset].north * header.yScale) / yRes) * xDim $
                                    + floor((header.xOffset - fileMin[0] + data[subset].east  * header.xScale) / xRes),  $
                                    reverse_indices=arrayIndex, min=0d, max=xDim*yDim)

                    ; Create vector for flagging subset indices

                subsetFlag = bytarr(n_elements(subset))

                    ; Iterate through the ROI index, getting corresponding data points.  The points that
                    ; are found in the ROI are flagged via the subsetFlag array

                for c=0,n_elements(roiIndex)-1 do begin

                    if (arrayIndex[roiIndex[c]] ne arrayIndex[roiIndex[c]+1]) then $
                        subsetFlag[arrayIndex[arrayIndex[roiIndex[c]]:arrayIndex[roiIndex[c]+1]-1]] = 1

                endfor

                    ; Keep only subset indices that are flagged, if any exist

                if (max(subsetFlag)) then subset = subset[where(subsetFlag)] else subset = -1

            endif

                ; If points exist within the subset, then continue

            if subset[0] ne -1 then begin

                    ; If the input data and the output data have different scaling or offset
                    ; parameters, adjust the input data accordingly.

;                subsetData = data[subset]

                if ((header.xScale ne outHeader.xScale) or (header.xOffset ne outHeader.xOffset)) then begin

                        data[subset].east *= (header.xScale  / outHeader.xScale)
                        data[subset].east += (header.xOffset - outHeader.xOffset)

                endif

                if ((header.yScale ne outHeader.yScale) or (header.yOffset ne outHeader.yOffset)) then begin

                        data[subset].north *= (header.yScale  / outHeader.yScale)
                        data[subset].north += (header.yOffset - outHeader.yOffset)

                endif

                if ((header.zScale ne outHeader.zScale) or (header.zOffset ne outHeader.zOffset)) then begin

                        data[subset].elev *= (header.zScale  / outHeader.zScale)
                        data[subset].elev += (header.zOffset - outHeader.zOffset)

                        data[subset].source *= (header.zScale / outHeader.zScale)

                endif

                    ; Record the data and update the header

                statText = ['Saving to ' + file_basename(outputFile),statText]
                widget_control, statField, set_value=statText

                writeu, outputLun, data[subset]

                outHeader.nPoints  += n_elements(subset)
                outHeader.nReturns += histogram((data[subset].nReturn mod 8) > 1, min=1, max=5)

                outHeader.xMin <= min(data[subset].east,  max=xMaxTemp) * header.xScale + header.xOffset
                outHeader.yMin <= min(data[subset].north, max=yMaxTemp) * header.yScale + header.yOffset
                outHeader.zMin <= min(data[subset].elev,  max=zMaxTemp) * header.zScale + header.zOffset

                outHeader.xMax >= xMaxTemp * header.xScale + header.xOffset
                outHeader.yMax >= yMaxTemp * header.yScale + header.yOffset
                outHeader.zMax >= zMaxTemp * header.zScale + header.zOffset

            endif

        endif

        data = [0]

    endif

endfor

    ; Check to make sure a non-zero number of points exist in the output file.  If so, update the header
    ; in the file.  If not, give a warning and erase the file.

if outHeader.nPoints then begin

    point_lun, outputLun, 0
    writeu,    outputLun, outHeader
    close,     outputLun

endif else begin

    check = dialog_message('The selected files do not contain any points within the specified area.', /center, /error)

    close, outputLun

    file_delete, outputFile, /quiet

endelse

widget_control, statBase, /destroy


end

