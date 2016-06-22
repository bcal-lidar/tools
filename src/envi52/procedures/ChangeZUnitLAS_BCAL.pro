;+
; NAME:
;
;       ChangeZUnitLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is reproject LAS files
;
; PRODUCTS:
;
;       The output is a new LAS file for each input LAS file.  The output files have the same
;       name as the input files.
;
; AUTHOR:
;
;       Exelis VIS
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;       WriteLAS_BCAL.pro
;       RecordsToProj_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by Exelis VIS, April, 2016.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2007 David Streutker, Idaho State University.
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

pro ChangeZUnitLAS_BCAL, event

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

  ; Establish the default projection

  ReadLAS_BCAL, inputFiles[0], header, projection=defProj, records=records, /nodata, $
    versionMajor=versionMajor, versionMinor=versionMinor
  
  isFeet = 0
  ipos = strpos(string(header.systemID), 'Z unit: Feet')
  if ipos ne -1 then isFeet = 1

  inputUnit = 0
  if isFeet then inputUnit = 2
  
  ; Get the input and output Z units and the output directory

  readBase = widget_auto_base(title='Change Z Unit')

  str = 'Input Z unit is ' + envi_translate_projection_units(inputUnit) + '. Change to:'
  dummy = widget_label(readBase, value=str)
  dummy = widget_pmenu(readBase, list=['Meters','Feet'], default=0, uvalue='oUnit',  /auto_manage, xsize=12)
  dummy = widget_outf(readBase, /directory, prompt='Select output directory', uvalue='outDir', /auto)

  result = auto_wid_mng(readBase)
  if result.accept eq 0 then return

  outputUnit = result.oUnit
  if outputUnit eq 1 then outputUnit += 1  ; +1 here because envi_translate_projection_units('Feet') = 2
  outputDir = result.outDir

    ; Set the scale based on the new z unit

  scale = 1.0
  
  case inputUnit of
  
      envi_translate_projection_units('Meters'): begin
        if outputUnit eq envi_translate_projection_units('Feet') then scale = 3.2808399
      end
      envi_translate_projection_units('Feet'): begin
        if outputUnit eq envi_translate_projection_units('Meters') then scale = 0.3048
      end
  
  endcase
  
  part = 5000D

  ; Process each data file individually

  for a=0,nFiles-1 do begin

    ; Initialize the status report

    reportText  = 'Changing z unit for file' + strcompress(a+1) + ' of' + strcompress(nFiles)
    reportText += ': ' + file_basename(inputFiles[a])
    envi_report_init, reportText, base=statBase, /interrupt, title='Changing Z Unit'

    ; Read the input file

    ReadLAS_BCAL, inputFiles[a], header, data, records=records

      ; Set up the iteration
  
    nParts = ceil(header.nPoints / part)
    envi_report_inc, statBase, nParts
  
    if scale ne 1 then begin

      if outputUnit eq envi_translate_projection_units('Feet') then $
        header.systemID = byte('Z unit: Feet') $
      else header.systemID = byte('TRANSFORMATION')
      
      ; Convert the input data, part by part
  
      for b=0,nParts-1 do begin
  
        envi_report_stat, statBase, b+1, nParts, cancel=cancel
        if cancel then begin
          envi_report_init, base=statBase, /finish
          return
        endif
  
        pStart =  part *  b
        pEnd = (part * (b + 1) < header.nPoints) - 1
  
        newZ = (data[pStart:pEnd].elev  * header.zScale + header.zOffset) * scale
  
        data[pStart:pEnd].elev = newZ / header.zScale
  
      endfor
  
      ; Get the min and max values of the new z values
  
      zMin = min(data.elev, max=zMax)
  
      ; Record the new header parameters
  
      header.zOffset = 0
  
      header.zMin = zMin * header.zScale ;+ header.zOffset
      header.zMax = zMax * header.zScale ;+ header.zOffset
  
      if (defProj ne !NULL) then begin
        
        ; Update the array of records
        
        newRecord = RecordsToProj_BCAL(defProj, versionMajor=versionMajor, versionMinor=versionMinor, /reverse)
    
        if n_tags(records) then begin
    
          for ni = 0, n_elements(newRecord)-1 do begin
            
            rIndex = where(records.recordID eq (newRecord[ni]).recordID)
      
            if rIndex eq -1 then begin
              records = [records,newRecord[ni]]
              (header.nRecords)++
            endif else records[rIndex] = newRecord[ni]
    
          endfor
          
        endif else begin
          records = newRecord
          header.nRecords = n_elements(newRecord)
        endelse
      
      endif

    endif
    
    ; Write the new file

    outputFile = outputDir + path_sep() + file_basename(inputFiles[a])

    WriteLAS_BCAL, outputFile, header, data, records=records, /check

    envi_report_init, base=statBase, /finish

  endfor


end