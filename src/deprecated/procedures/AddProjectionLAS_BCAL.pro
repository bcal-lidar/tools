;+
; NAME:
;
;       AddProjectionLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is add projection information to LAS files
;
; PRODUCTS:
;
;       The output is a new LAS file for each input LAS file.  The output files have the same
;       name as the input files.
;
; AUTHOR:
;
;       David Streutker
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
;       RecordsToProj_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, June 2007.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright @ 2007 David Streutker, Idaho State University.
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

pro AddProjectionLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish error handler.  The most likely problem is that the user will open a data
    ; file that is too large to process.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    return
endif

    ; Get the input file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Get the output projection and the output directory

readBase = widget_auto_base(title='Select Projection')

    dummy = widget_label(readBase, value='Set output projection:')
    dummy = widget_map(readBase, default_map=[0,0], default_proj=envi_proj_create(), uvalue='proj', /auto)
    dummy = widget_outf(readBase, /directory, prompt='Select output directory', uvalue='outDir', /auto)

result = auto_wid_mng(readBase)
if result.accept eq 0 then return

proj = result.proj.proj

outputDir = result.outDir

    ; Set up status message window

statText  = 'Initializing'
statBase  = widget_auto_base(title='Adding Projections')
statField = widget_text(statBase, /scroll, value=statText, xsize=80, ysize=4)
widget_control, statBase, /realize

    ; Process each data file individually

for a=0,nFiles-1 do begin

        ; Update the status window

    statText = ['Adding projection to ' + inputFiles[a], statText]
    widget_control, statField, set_value=statText

        ; Read the input file

    ReadLAS_BCAL, inputFiles[a], header, data, records=records

        ; Update the array of records

    newRecord = RecordsToProj_BCAL(proj, /reverse)

    if n_tags(records) then begin

        rIndex = where(records.recordID eq 34735, rCount)

        if rCount then begin

            mText = 'The file ' + file_basename(inputFiles[a]) + ' appears to already contain projection ' $
                  + 'information.  Do you want to rewrite it the projection?'
            query = dialog_message(mText, /center, /question, /default_no)

            if query eq 'Yes' then records[rIndex] = newRecord

        endif else records = [records,newRecord]

    endif else records = newRecord

        ; Write the new file

    outputFile = outputDir + '\' + file_basename(inputFiles[a])

    WriteLAS_BCAL, outputFile, header, data, records=records, /check

endfor

    ; Destroy the status window

widget_control, statBase, /destroy


end