;+
; NAME:
;
;       ExportLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to export LAS file(s) by different available LAS fields. This
;       program supercedes GroundPointsLAS_BCAL.pro, which has been deprecated.
;
; PRODUCTS:
;
;       The output is LAS file(s) with only selected returns.
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
;       ReadLAS_BCAL.pro
;       WriteLAS_BCAL.pro
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

pro ExportLAS_BCAL, event

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

inputFiles = envi_pickfile(title='Select LAS file(s) to export', filter='*.las', /multiple_files)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

for a=0,nFiles-1 do begin
    
    ReadLAS_BCAL, inputFiles[a], header, /nodata
    
    if a eq 0 then begin
      zMin = header.zMin
      zMax = header.zMax
    endif else begin 
      zMin <= header.zMin
      zMax >= header.zMax
    endelse

endfor

    ; Get export parameters based on type requested

widget_control, event.id, get_uvalue=exportType

topBase = widget_auto_base(title='Export lidar data')

dummy   = widget_outf(topBase, /directory, prompt='Select output directory', uvalue='outF', /auto)
 
case exportType of
      
          'exportReturn': begin
      
               returnList = ['First Returns','Second Returns',$
                                'Third Returns','Fourth Returns','Fifth Returns']
                                
               dummy      = widget_multi(topBase, list=returnList, prompt='Select returns to export:', ysize=130, $
                              uvalue='exportN', /no_range, /auto)
                              
               result = auto_wid_mng(topBase)
               if result.accept eq 0 then return
                  
               exportIndex = result.exportN

          end
          
         'exportReturnNo': begin
      
               returnList = ['1st of One Return','1st of Two Returns', '2nd of Two Returns', $
                                '1st of Three Returns','2nd of Three Returns','3rd of Three Returns', $
                                '1st of Four Returns','2nd of Four Returns','3rd of Four Returns', '4th of Four Returns', $ 
                                '1st of Five Returns','2nd of Five Returns','3rd of Five Returns', '4th of Five Returns', '5th of Five Returns']
               dummy      = widget_multi(topBase, list=returnList, prompt='Select returns to export:', ysize=150, $
                              uvalue='exportN', /auto)
                              
               result = auto_wid_mng(topBase)
               if result.accept eq 0 then return
                  
               exportIndex = result.exportN

          end
      
          'exportClass': begin
          
               classList = ['Never classified (0)','Unclassified (1)','Ground (2)', $
                              'Low vegetation (3)','Medium vegetation (4)', 'High vegetation (5)', $
                              'Building (6)', 'Low point (Noise) (7)', 'Model Key Points (8)', $
                              'Water (9)', 'Reserved (10)', 'Reserved (11)', 'Overlap Points (12)']
               dummy      = widget_multi(topBase, list=classList, prompt='Select classes to export:', ysize=150, $
                              uvalue='exportN', /auto)
               
               result = auto_wid_mng(topBase)
               if result.accept eq 0 then return
                  
               exportIndex = result.exportN
                  
          end
          
          'exportElev': begin
          
              minBase   = widget_base(topBase, /row)
              dummy     = widget_param(minBase, prompt='Minimum Elevation: ', default = zMin, $
                              ceil=zMax, floor=zMin, uvalue='minN', /auto)
    
              maxBase   = widget_base(topBase, /row)
              dummy     = widget_param(maxBase, prompt='Maximum Elevation: ', default = zMax ,$
                              ceil=zMax, floor=zMin, uvalue='maxN', /auto)
              
              result = auto_wid_mng(topBase)
              if result.accept eq 0 then return
                  
              minN = result.minN
              maxN = result.maxN
      
          end
          
          
          'exportInten': begin
      
              minBase   = widget_base(topBase, /row)
              dummy     = widget_param(minBase, prompt='Minimum Intensity: ', default = 0, $
                              ceil=254, floor=0, uvalue='minN', /auto)
    
              maxBase   = widget_base(topBase, /row)
              dummy     = widget_param(maxBase, prompt='Maximum Intensity: ', default = 255, $
                              ceil=255, floor=1, uvalue='maxN', /auto)
              
              result = auto_wid_mng(topBase)
              if result.accept eq 0 then return
                  
              minN = result.minN
              maxN = result.maxN
      
          end
          
          'exportScan': begin
      
              minBase   = widget_base(topBase, /row)
              dummy     = widget_param(minBase, prompt='Minimum Scan Angle: ', default =-10, $
                              ceil=+90, floor=-90, uvalue='minN', /auto)
    
              maxBase   = widget_base(topBase, /row)
              dummy     = widget_param(maxBase, prompt='Maximum Scan Angle: ', default = +10, $
                              ceil=+90, floor=-90, uvalue='maxN', /auto)
              
              result = auto_wid_mng(topBase)
              if result.accept eq 0 then return
                  
              minN = result.minN
              maxN = result.maxN
      
          end
      
endcase

outputDir  = result.outF

; Set up ENVI status reporting box
statText1 = 'Exporting...'
statText2 = 'LAS file: ' + FILE_BASENAME(inputFiles)
statText = [statText1,statText2]
statBase = widget_auto_base(title='Exporting')
ENVI_REPORT_INIT, statText, BASE=statBase, TITLE='Exporting'
envi_report_inc,  statBase, nFiles

for a=0,nFiles-1 do begin

          ; Read input lidar data to an array of structures
          
      ReadLAS_BCAL, inputFiles[a], header, data, records=records, check=check, projection=projection
     
      p = 0
      
      case exportType of
      
          'exportReturn': begin
                
                returnIndex =[1, 2, 3, 4, 5]
                returnNames = returnIndex[where(exportIndex eq 1, nOut)]  
                
                for i = 0, nOut-1 do begin
                
                    dindex = where((data.nReturn mod 8) eq returnNames[i], count)
                    
                    if count ne 0 then begin
                    
                        if i eq 0 then begin
                        
                            odata = data[dindex]
                        
                        endif else begin
                            
                            odata = [odata, data[dindex]]
                            
                        endelse
                      
                      endif                                          
                    
                    p = p + count

                endfor 
      
          end
          
          'exportReturnNo': begin
                
                returnNoIndex =[1, 1, 2, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 4, 5]
                returnIndex =[1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5]
                returnNos = returnIndex[where(exportIndex eq 1, nOut)]  
                returnNames = returnNoIndex[where(exportIndex eq 1, nOut)]  
                
                for i = 0, nOut-1 do begin
                                   
                    dindex = where((floor(data.nReturn/8) mod 8) eq returnNos[i] and $ 
                                    (data.nReturn mod 8) eq returnNames[i], count)

                    if count ne 0 then begin
                        
                        if i eq 0 then begin
    
                            odata = data[dindex]
                        
                        endif else begin
                            
                            odata = [odata, data[dindex]]
                            
                        endelse
                   endif
                                                                
                    p = p + count

                endfor 
          
          end
      
          'exportClass': begin
                
                classIndex =[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
                classNames = classIndex[where(exportIndex eq 1, nOut)]  
                
                for i = 0, nOut-1 do begin
                    
                    dindex = where(data.class eq classNames[i], count)
                    
                    if count ne 0 then begin
                    
                        if i eq 0 then begin

                            odata = data[dindex]
                        
                        endif else begin
    
                            odata = [odata, data[dindex]]
                            
                        endelse
                        
                    endif
                    
                    p = p + count

                endfor
               
          end
          
          'exportElev': begin
          
               dindex = where(data.elev ge ((minN - header.zOffset) / header.zScale) and $
                              data.elev le ((maxN - header.zOffset) / header.zScale), count)
               
               if count ne 0 then odata = data[dindex]
               
               p = count

          end
          
          'exportInten': begin
          
               dindex = where(data.inten ge minN and $
                              data.inten le maxN, count)
               
               if count ne 0 then odata = data[dindex]
               
               p = count
      
          end
          
          'exportScan': begin
               
               dindex = where(((data.angle-128B)-128) ge minN and $
                              ((data.angle-128B)-128) le maxN, count)
               
               if count ne 0 then odata = data[dindex]
               
               p = count
               
      
          end
      
      endcase
                      
      if p gt 0 then begin 

          ; Write the header and data to a new file in the output directory
          
            outputFile = outputDir + '\' + file_basename(inputFiles[a])
            
            WriteLAS_BCAL, outputFile, header, odata, records=records, /check
      
      endif else begin
             
             msgTxt = FILE_BASENAME(inputFiles[a]) + ' has no selected points.'
             
             msgBox = DIALOG_MESSAGE(msgTxt, /ERROR)
             Catch, /Cancel
             
      endelse
      
      envi_report_inc,  statBase, a  


endfor

;; Complete status reporting widget
envi_report_init, base=StatBase, /finish 


end