;+
; NAME:
;
;       ReclassifyLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to reclassify a LAS file 
;
; PRODUCTS:
;
;       The output is LAS file(s) with assigned reclassification
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
   
   ; Begin main program

pro ReclassifyLAS_BCAL, event

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

list = ['Class 0 :','Class 1 :','Class 2 :','Class 3 :','Class 4 :','Class 5 :','Class 6 :',  $
        'Class 7 :','Class 8 :','Class 9 :','Class 10 :','Class 11 :','Class 12 :']

classIndex = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    ; Get the user parameters

readBase = widget_auto_base(title='Reclassify LAS files')

    tileBase = widget_base(readBase, /row)
    dummy    = widget_edit(tileBase, dt=2, floor=1, list=list, $
                           prompt='Reclassification:', vals=classIndex, ysize=13, uvalue='newIndex', /auto)

    outputBase  = widget_base(readBase, /row)
    fileBase    = widget_base(outputBase, /column)
    outputField = widget_outf(fileBase, prompt='Select output directory ', /directory, $
                              uvalue='lasName', /auto)

result = auto_wid_mng(readBase)
if (result.accept eq 0) then return

newIndex = result.newIndex

outputDir = result.lasName

cIndex = where(classIndex ne newIndex, nOut)

if nOut ne 0 then begin 

    classNames = classIndex[cIndex]  
    
    ; Set up ENVI status reporting box
    statText1 = 'Reclassifying...'
    statText2 = 'LAS file: ' + FILE_BASENAME(inputFiles)
    statText = [statText1,statText2]
    statBase = widget_auto_base(title='Reclassification')
    ENVI_REPORT_INIT, statText, BASE=statBase, TITLE='Reclassifying'
    envi_report_inc,  statBase, nFiles
    
    for a=0,nFiles-1 do begin
    
              ; Read input lidar data to an array of structures
              
          ReadLAS_BCAL, inputFiles[a], header, data, records=records, check=check, projection=projection
          
          for i = 0, nOut-1 do begin
                        
              dindex = where(data.class eq classNames[i], count)
                        
              if count ne 0 then begin
                        
                   data[dindex].class = newIndex[cIndex[i]]
                            
              endif
                        
          endfor
          
          outputFile = outputDir + '\' + file_basename(inputFiles[a])
                
          WriteLAS_BCAL, outputFile, header, data, records=records, /check
    
          envi_report_inc,  statBase, a  
    
    
    endfor
    
endif else msgBox = DIALOG_MESSAGE('No new classification was assigned', /ERROR)

;; Complete status reporting widget
envi_report_init, base=StatBase, /finish 
end