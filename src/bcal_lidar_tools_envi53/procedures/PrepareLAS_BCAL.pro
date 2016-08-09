 ;+
; NAME:
;
;       PrepareLAS_BCAL
;
; PURPOSE:
;       
;       The purpose of this program is to assign the vegetation height to selected
;       LAS file(s) from existing bare-earth digital terrain model. The height field 
;       is stored in sourceid field of LAS file(s). This tool is particularly useful
;       when a different height filtering tool is used instead of BCAL's height filtering
;
; PRODUCTS:
;
; AUTHOR:
;       Rupesh Shrestha
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
;       ScalePoly_BCAL.pro
;
; KNOWN ISSUES:
;
;
; MODIFICATION HISTORY:
;
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright @ 2010 Idaho State University.
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


pro PrepareLAS_BCAL, event
compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error creating file')
    return
endif

    ; Get the input LAS file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Get the reference RGB image

envi_select, fid=refID, /file_only, /no_dims, pos=demPos, $
        title='Select bare-earth DEM'
if (refID[0] eq -1) then return

While  (n_elements(demPos) ne 1) do begin

    dummy = dialog_message('Please select only one spectral band', /error)
    envi_select, fid=refID, /file_only, /no_dims, pos=demPos, $
            title='Select bare-earth DEM'
    if (refID[0] eq -1) then return

endwhile

envi_file_query, refID, ns=ns, nl=nl, data_type=dtype
    ; Output LAS file(s)
    
tempDir = dialog_pickfile(title='Select output directory', /directory, /path)
if (tempDir eq '') then return


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
endfor

    ; Destroy the status window

widget_control, statBase, /destroy

end