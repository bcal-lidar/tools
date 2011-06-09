;+
; NAME:
;
;       AssignColorLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to assign RGB values to LAS file from an
;       overlapping orthophoto or a multispectral images. LAS files should be in 1.2  
;       format and the multispectral image should be in same projection system as the 
;       LAS file.
;
; PRODUCTS:
;
;       The output LAS file will contain RGB values from the overlapping orthophoto or 
;       multispectral images. 
;
; AUTHOR:
;
;       Rupesh Shrestha
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://bcal.geology.isu.edu/
;
; DEPENDENCIES:
;
;       xcolors_BCAL.pro
;       ReadLAS_BCAL.pro
;       InitDataLAS_BCAL.pro
;       WriteLAS_BCAL.pro
;
; KNOWN ISSUES:
;
; 
; MODIFICATION HISTORY:
;
;       Written by Rupesh Shrestha, July 2010.
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


pro AssignColorLAS_BCAL, event
compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error creating file')
    return
endif

widget_control, event.id, get_uvalue=RGBType

    ; Get the input LAS file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

if RGBType eq 'RGBLasOrtho' then begin

      ; Get the reference RGB image
      
      envi_select, fid=refID, /file_only, /no_spec, /no_dims, title='Select Reference RGB Image'
      if (refID[0] eq -1) then return
      
      rgb_get_bands, dims=dims, /no_dims, fid=refID, pos=rgbArr, TITLE='Specify RGB Bands'
      if (refiD[0] eq -1) then return 
      
      envi_file_query, refID, ns=ns, nl=nl, data_type=dtype

endif else xcolors_BCAL, /Block, ColorInfo=colorInfoData, Title="Shading Colors", index=34


    ; Get the output directory

outputDir = dialog_pickfile(title='Select output directory', /directory, /path)
if (outputDir eq '') then return


for a=0,nFiles-1 do begin

    ReadLAS_BCAL, inputFiles[a], header, pData, records=records
    
    header.versionMinor = 2
    if header.pointFormat eq 1 then header.pointFormat = 3
    if header.pointFormat eq 0 then header.pointFormat = 2
   
    dataTemp = InitDataLAS_BCAL(pointFormat=header.pointFormat)
    data = replicate(temporary(dataTemp), header.nPoints)
    
    if RGBType eq 'RGBLasOrtho' then begin
    
        envi_convert_file_coordinates, refID, xImage, yImage, $
            pdata.east  * header.xScale + header.xOffset, $
            pdata.north * header.yScale + header.yOffset
            
        imgRoi = envi_create_roi(ns=ns, nl=nl, /no_update)
        
        envi_define_roi, imgRoi, /no_update, /point, xpts=xImage, ypts=yImage
        
        data.red = envi_get_roi_data(imgRoi, fid=refID, pos=rgbArr[0])
        data.green = envi_get_roi_data(imgRoi, fid=refID, pos=rgbArr[1])
        data.blue = envi_get_roi_data(imgRoi, fid=refID, pos=rgbArr[2])
        
    endif else begin
        
        if RGBType eq 'RGBLasVegHt' then vert_colors=bytscl(pData.source, /nan)
        
        if RGBType eq 'RGBLasElev' then  vert_colors=bytscl(pData.elev, /nan)
        
        data.red = colorInfoData.r[vert_colors]
        data.green = colorInfoData.g[vert_colors]
        data.blue = colorInfoData.b[vert_colors]
    
    endelse

    data.angle = pData.angle
    data.class = pData.class
    data.east = pData.east
    data.elev = pData.elev
    data.inten = pData.inten
    data.north = pData.north
    data.nreturn = pData.nreturn
    data.source = pData.source
    data.time = pData.time
    data.user = pData.user
        
           ; Write the new file

    outputFile = outputDir + '\' + file_basename(inputFiles[a])
   
    WriteLAS_BCAL, outputFile, header, data, records=records, /check
    
           ; Clear up some memory

    data      = 0B
    pData     = 0B
    xImage    = 0B
    yImage    = 0B

endfor

end