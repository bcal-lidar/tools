;+
; NAME:
;
;       DataInfoBatchLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is store data information of selected LAS file(s). 
;       It produces descriptive statistics of the data, normally not contained 
;       in the LAS header file.
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
;       http://bcal.geology.isu.edu
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;
; KNOWN ISSUES:
;
; 
; MODIFICATION HISTORY:
;
;       Written by Rupesh Shrestha, August 2010.
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

pro DataInfoBatchLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file')
    return
endif

    ; Get the file

lasFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /path, /multiple_files)
if lasFiles[0] eq '' then return
nFiles = N_ELEMENTS(lasFiles)

txtfile = dialog_pickfile(title='Select output file', filter='*.txt', /path, $
          /write, DEFAULT_EXTENSION='txt')
if txtfile eq '' then return

d = ',' ;delimiter

openw, txtLun, txtFile, /get_lun, width=1600

headings = 'FileName'+d+ $
           'MinX'+d+ $
           'MaxX'+d+ $
           'MinY'+d+ $
           'MaxY'+d+ $
           'Area'+d+ $
           'Point_Density'+d+ $
           'No_of_Pts'+d+$
           '1st_Returns'+d+$
           '2nd_Returns'+d+$
           '3rd_Returns'+d+$
           '4th_Returns'+d+$
           '5th_Returns'+d+$
           'Class_0'+d+$
           'Class_1'+d+$
           'Class_2'+d+$
           'Class_3'+d+$
           'Class_4'+d+$
           'Class_5'+d+$
           'Class_6'+d+$
           'Class_7'+d+$
           'Class_8'+d+$
           'Class_9'+d+$
           'Class_10'+d+$
           'Class_11'+d+$
           'Class_12'+d+$
           'Min_elev'+d+$
           'Max_elev'+d+$
           'Mean_elev'+d+$
           'StDev_elev'+d+$
           'Skew_elev'+d+$
           'Kurt_elev'+d+$
           'Min_Intensity'+d+$
           'Max_Intensity'+d+$
           'Mean_Intensity'+d+$
           'StDev_Intensity'+d+$
           'Skew_Intensity'+d+$
           'Kurt_Intensity'+d+$
           'Min_ScanAngle'+d+$
           'Max_ScanAngle'+d+$
           'Mean_ScanAngle'+d+$
           'StDev_ScanAngle'+d+$
           'Skew_ScanAngle'+d+$
           'Kurt_ScanAngle'+d+$
           'Min_VegHeight'+d+$
           'Max_VegHeight'+d+$
           'Mean_VegHeight'+d+$
           'StDev_VegHeight'+d+$
           'Skew_VegHeight'+d+$
           'Kurt_VegHeight'

PRINTF,txtLun,headings

     
; Set up ENVI status reporting box
statText = 'Reading LAS files...'
statBase = widget_auto_base(title='Reading')
ENVI_REPORT_INIT, statText, BASE=statBase, TITLE='Reading'
envi_report_inc,  statBase, nFiles
      
      
for a=0,nFiles-1 do begin
          
          ; Read the file, getting all information except the data
      
      ReadLAS_BCAL, lasFiles[a], header, pdata
          
      ; get area
      bPoints  = GetBounds_BCAL(pdata.east * header.xScale, pdata.north * header.yScale)
      bArea    = poly_area(pdata[bPoints].east  * header.xScale + header.xOffset, $
                               pdata[bPoints].north * header.yScale + header.yOffset)
                               
    
     ; elevation statistics
      minelev= min(pData.elev * header.zScale + header.zOffset, max=maxelev)
      momelev= moment(pData.elev * header.zScale + header.zOffset, sdev=sdevelev)     
      
      ; intensity statistics
      mininten= min(pData.inten, max=maxinten)
      mominten= moment(pData.inten, sdev=sdevinten)
      
      ;scan angle statistics
      
      minangle= min(pData.angle-128B, max=maxangle)
      momangle= moment((pData.angle-128B), sdev=sdevangle)
      
      ;vegetation height statistics
      vegindex=where(pData.class eq 3, vegcount)
      if vegcount then begin 
        minveg= min(pData[vegindex].source * header.zScale, max=maxveg)
        momveg= moment(pData[vegindex].source * header.zScale, sdev=sdevveg)
      endif else begin
        minveg = 0
        maxveg = 0
        sdevveg =0 
        momveg = momelev*0
      endelse
      
      ;color histogram
      cHisto = histogram(pdata.class, min=0, max=12)

     
      PRINTF, txtLun, file_basename(lasFiles[a]), d, $
                      strcompress(header.xMin), d, $
                      strcompress(header.xMax), d, $
                      strcompress(header.yMin), d, $
                      strcompress(header.yMax), d, $
                      strcompress(bArea), d, $
                      strcompress(floor(header.npoints/bArea)), d, $
                      strcompress(header.nPoints), d, $
                      strcompress(header.nReturns[0]), d, $
                      strcompress(header.nReturns[1]), d, $
                      strcompress(header.nReturns[2]), d, $
                      strcompress(header.nReturns[3]), d, $
                      strcompress(header.nReturns[4]), d, $
                      strcompress(cHisto[0]), d, $
                      strcompress(cHisto[1]), d, $
                      strcompress(cHisto[2]), d, $
                      strcompress(cHisto[3]), d, $
                      strcompress(cHisto[4]), d, $
                      strcompress(cHisto[5]), d, $
                      strcompress(cHisto[6]), d, $
                      strcompress(cHisto[7]), d, $
                      strcompress(cHisto[8]), d, $
                      strcompress(cHisto[9]), d, $
                      strcompress(cHisto[10]), d, $
                      strcompress(cHisto[11]), d, $
                      strcompress(cHisto[12]), d, $
                      strcompress(minelev), d, $
                      strcompress(maxelev), d, $
                      strcompress(momelev[0]), d, $
                      strcompress(sdevelev), d, $
                      strcompress(momelev[2]), d, $
                      strcompress(momelev[3]), d, $
                      strcompress(mininten), d, $
                      strcompress(maxinten), d, $
                      strcompress(mominten[0]), d, $
                      strcompress(sdevinten), d, $
                      strcompress(mominten[2]), d, $
                      strcompress(mominten[3]), d, $
                      strcompress(minAngle - 128), d, $
                      strcompress(maxAngle  - 128), d, $
                      strcompress(momAngle[0]  - 128), d, $
                      strcompress(sdevAngle), d, $
                      strcompress(momAngle[2]), d, $
                      strcompress(momAngle[3]), d, $
                      strcompress(minveg), d, $
                      strcompress(maxveg), d, $
                      strcompress(momveg[0]), d, $
                      strcompress(sdevveg), d, $
                      strcompress(momveg[2]), d, $
                      strcompress(momveg[3])
        
        
        envi_report_stat, statBase, a, nFiles, cancel=cancel
        if cancel then begin
            envi_report_init, base=statBase, /finish
            close, /all
            return
        endif

endfor
    
free_lun, txtLun

envi_report_init, base=statBase, /finish

end