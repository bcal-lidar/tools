;+
; NAME:
;
;       DecimateLASper_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to decimate lidar files.  The total number of points in
;       the output file is determined by the user.  More than one input files may be selected,
;       but the output is combined into a single file.  Input files are expected in LAS format.
;
; PRODUCTS:
;
;       The output is a single LAS file, whose number of points is determined by the user.
;       When multiple lidar data files are input, the number of points taken from each file is
;       proportional to the size of that file with respect to the other input files.
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
;       GetBounds_BCAL.pro
;       InitHeaderLAS_BCAL.pro
;       ReadLAS_BCAL.pro
;       WriteLAS_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by Rupesh Shrestha, June 2010.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright © 2010 Rupesh Shrestha, Idaho State University.
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

pro DecimateLASper_BCAL, event

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

    ; Select the input files to decimate

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple, /path)
    if (inputFiles[0] eq '') then return

nFiles  = n_elements(inputFiles)
nPoints = lonarr(nFiles)

    ; Get the decimation parameters from the user

readBase = widget_auto_base(title='Select Decimation Parameters')

deciBase    = widget_base(readBase, /row)

deciField   = widget_param(deciBase, /percent, ceil=100, default=10, dt=5, floor=0, $
                              prompt='Select percent of points to keep: ', uvalue='deci', /auto_manage)
                        
outputBase  = widget_base(readBase, /row)
fileBase    = widget_base(outputBase, /column)
outputField = widget_outf(fileBase, prompt='Select output directory', /directory, $
                              uvalue='lasName', /auto_manage)

result = auto_wid_mng(readBase)
if result.accept eq 0 then return

nDeci      = result.deci
outputDir  = result.lasName



    ; Determine the number of points to get from each file

seed  = systime(/seconds) mod 100

    ; Set up status message window

statText  = 'Initializing'
statBase  = widget_auto_base(title='Decimation Status')
statField = widget_text(statBase, /scroll, value=statText, xsize=80, ysize=4)
widget_control, statBase, /realize

    ; Begin processing, file by file

for b=0,nFiles-1 do begin

        ; Update the status window

    statText = ['Decimating ' + inputFiles[b] + ' (' + strcompress(b+1,/remove) $
                                              + '/'  + strcompress(nFiles,/remove) + ')', statText]
    widget_control, statField, set_value=statText

        ; Read the input file

    ReadLAS_BCAL, inputFiles[b], header, data, records=records
    
    nTemp = round(header.nPoints * (nDeci/100)) 

        ; Select the neccessary number of random points from the input file and write
        ; them to the output file.

    index = randomu(seed, nTemp,/double) * header.nPoints
    index = index[uniq(index,sort(index))]
    index = index[0:nTemp-1]
    
    header.nPoints =  nTemp
    
    ; Write the header and data to a new file in the output directory

    outputFile = outputDir + '\' + file_basename(inputFiles[b])
    WriteLAS_BCAL, outputFile, header, data[index], records=records, /check

    data = 0b

endfor

    ; Destroy the status window

widget_control, statBase, /destroy


end