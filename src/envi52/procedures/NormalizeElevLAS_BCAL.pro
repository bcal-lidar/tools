;+
; NAME:
;
;       NormalizeElevLAS_BCAL
;
; PURPOSE:
;
;       Basically the same as NormalizeElev_ui
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;       WriteLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Implemented by Exelis VIS, April 2016.
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

pro NormalizeElevLAS_BCAL, event

  compile_opt idl2, logical_predicate

  ; Establish an error handler.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file', /center)
    return
endif


doProfile = 0

    ; Get the input file(s).
inputFiles = envi_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files)
if (inputFiles[0] eq '') then return

outputDir = envi_pickfile(title='Select output directory', /directory)
if outputDir eq '' then return
              
    ; Begin processesing each file

minN = 0.05
maxN = 1.8
    
for a=0,n_elements(inputFiles)-1 do begin

        ; Establish the status reporting widget.  This will report the processing status
        ; for each data file.

    statBase = widget_auto_base(title='Assigning')
    statText = ['Normalizing Progress:', file_basename(inputFiles[a]), $
      'File' + strcompress(a+1) + ' of' + strcompress(n_elements(inputFiles))]
    envi_report_init, statText, base=statBase, /interrupt, title='Normalizing elevation...'

        ; Read the input data file.

    ReadLAS_BCAL, inputFiles[a], header, pData, records=records
    
    envi_report_stat, statBase, 33, 100, cancel=cancel
    
    g_index = where(pdata.source le ((minN - header.zOffset) / header.zScale), g_count, complement=t_index, ncomplement=t_count)
      
    if g_count ne 0 then begin
      pdata[g_index].class = 2
      pdata[g_index].source = 0
    endif
    
    if t_count ne 0 then pdata[t_index].class = 3
    
    envi_report_stat, statBase, 66, 100, cancel=cancel
    
    v_index = where(pdata.source gt ((maxN - header.zOffset) / header.zScale), v_count)
    
    if v_count ne 0 then begin
      pdata[v_index].class = 1
      pdata[v_index].source = 2^16 - 1
    endif

    envi_report_stat, statBase, 99, 100, cancel=cancel
    
    outputFile = outputDir + path_sep() + file_basename(inputFiles[a])
    WriteLAS_BCAL, outputFile, header, pData, records=records, /check
    
    envi_report_stat, statBase, 100, 100, cancel=cancel
    envi_report_init, base=statBase, /finish

endfor


end




