;
; NAME:
;   LASToAscii_BCAL
;
; PURPOSE:
;   The purpose of this program is to convert an LAS file to an ASCII text file.
;
; PRODUCTS:
;   Text file(s) with the same name as the input LAS file(s) and the .txt extension.
;   Output file(s) saved to a folder chosen by the user.
;
; AUTHOR:
;   Sara Ehinger
;   Boise Center Aerospace Laboratory
;   Idaho State University
;      322 E Front St  Ste 240
;   Boise  ID  83702
;   http://bcal.geology.isu.edu
;
; DEPENDENCIES:
;     ReadLAS_BCAL.pro
;
; KNOWN ISSUES:
;   X, Y, Z values are padded with zeros to 6 decimal places.
;   These extra zeros use unnecessary storage space in the output text file.
;   Cancel works, but doesn't clear the status reporting box.
;
; MODIFICATION HISTORY:
;   Written by Sara Ehinger, March 2010.
;   Removed the message boxes, August 2010 (Rupesh Shrestha).
;   Data read/write by chunks - more efficient, August 2010 (Rupesh Shrestha)
;   LAS 1.2 support, August 2010 (Rupesh Shrestha)
;###########################################################################
;
; LICENSE
;
; Copyright @ 2010 Sara Ehinger, Idaho State University.
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
;###########################################################################
;-

; Begin main program
PRO LASToAscii_BCAL, event

   COMPILE_OPT idl2, logical_predicate
   
   ; Establish an error handler
   catch , theError
   if theError ne 0 then begin
      catch, /cancel
      help, /last_message, output=errText
      ENVI_REPORT_INIT, base=statBase, /finish
      errMsg = dialog_message(errText, /error, title='Error processing request')
      return
   endif
   
   ; Get the input file(s).
   inputFiles = envi_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files)
   if (inputFiles[0] eq '') then return
   
   ; Set up delimiter list and field list
   delimiterList = ['comma','tab','semicolon','space','colon','vertical bar'] ; Add fixed width?
   fieldsList = ['X Y Z', 'X Y Z Intensity', 'X Y Z R G B', 'All available fields']
   
   ; Get a count of the input files selected for processing
   
   nFiles = N_ELEMENTS(inputFiles)
   
   ; Get the output parameters (delimiter, fields, header row, location) from the user.
   ; Set up GUI
   
   readBase = widget_auto_base(title='Select ASCII Options')
   
   ; Display files selected for conversion
   widgetText = 'LAS file(s) selected for conversion:'
   FOR a=0,nFiles-1 DO BEGIN
      nextLine = '   ' + STRTRIM(a+1, 1) + ') ' + FILE_BASENAME(inputFiles[a])
      widgetText = [widgetText, nextLine]
   ENDFOR
   dummy = WIDGET_TEXT(readBase, VALUE=widgetText, YSIZE=nFiles+1)   ; not sure why the +1 is necessary
   
   ; Create delimiter drop down menu
   delimiterBase = WIDGET_BASE(readBase, /row)
   dummy     = WIDGET_PMENU(delimiterBase, list=delimiterList, default=0, prompt='Select Delimiter: ', $
      uvalue='fDelimiter', /auto)
      
   ; Create fields drop down menu
   fieldsBase  = WIDGET_BASE(readBase, /row)
   dummy     = WIDGET_PMENU(fieldsBase, list=fieldsList,  default=0, prompt='Select Fields:', $
      uvalue='fFields', /auto)
      
   ; Create header row yes/no check box
   headerRowBase  = WIDGET_BASE(readBase, /row)
   dummy      = WIDGET_MENU(headerRowBase, default_array=[1], list=['Include header row?'], $
      uvalue='headerRow',  /auto)
      
   ; Create output directory selection button and input
   maxBase = WIDGET_BASE(readBase, /row)
   dummy   = widget_outf(readBase, /directory, prompt='Select output directory', uvalue='outF', /auto)
   ; Add default directory?
   ; Check for existing files?
   
   result = auto_wid_mng(readBase)   ; automatic event handling of ENVI compound widgets
   ; creates anonymous structure whose tags are defined by the user values (UVALUE)
   ; automatically creates OK and Cancel buttons
   ; If you click OK, then result.accept is set to 1
   ; If you click Cancel, then result.accept is set to 0
   if result.accept eq 0 then return
   
   ; Get variables from widget (user)
   CASE result.fDelimiter OF
      0: d = ','        ; comma
      1: d = STRING(9B) ; tab
      2: d = ';'        ; semicolon
      3: d = ' '        ; space
      4: d = ':'        ; colon
      5: d = '|'        ; vertical bar
   ENDCASE
   fields = result.fFields
   headerRow = result.headerRow
   outputDir = result.outF
   
   ; Set the chunking size

   chunkSize = 1d5
      
   ; Convert each selected input file to text
   FOR a=0,nFiles-1 DO BEGIN
      
      ; Write the data to a new file in the output directory
      ; The file name will be the same as the input file with the ".las" changed to ".txt"
      outputFile = outputDir + '\' + FILE_BASENAME(inputFiles[a], '.las') + '.txt'
      
      ; Establish the status reporting widget to report the processing status for each data file.
      statBase = WIDGET_AUTO_BASE(title='Conversion Status')
      statText = ['File' + STRCOMPRESS(a+1) + ' of' + STRCOMPRESS(N_ELEMENTS(inputFiles)), $
         'Input File: ' + FILE_BASENAME(inputFiles[a]), $
         'Output File: ' + FILE_BASENAME(outputFile), $
         'Reading LAS...']
      ENVI_REPORT_INIT, statText, base=statBase, /interrupt, title='Converting'
      
      ; Read the input data file. 
      ReadLAS_BCAL, inputFiles[a], header, pData, records=records, check=check
      
      nChunks  = ceil(header.nPoints / chunkSize)
      leftSize = header.nPoints - chunkSize * (nChunks - 1)
      
      ENVI_REPORT_INIT, base=statBase, /finish
      statBase = WIDGET_AUTO_BASE(title='Conversion Status')
      statText = ['File' + STRCOMPRESS(a+1) + ' of' + STRCOMPRESS(N_ELEMENTS(inputFiles)), $
         'Input File: ' + FILE_BASENAME(inputFiles[a]), $
         'Output File: ' + FILE_BASENAME(outputFile), $
         'Writing ASCII...']
      ENVI_REPORT_INIT, statText, base=statBase, /interrupt, title='Converting'
      
      ; if all fields was selected and point format EQ 1 then fields=3 (adds GPS time field)
      IF fields EQ 3 AND header.POINTFORMAT EQ 1 THEN fields=4
      IF fields EQ 3 AND header.POINTFORMAT EQ 2 THEN fields=5 ;adds RGB
      IF fields EQ 3 AND header.POINTFORMAT EQ 3 THEN fields=6 ;adds RGB+GPS
      
      ; Open output text file for writing
      OPENW,  logASCII, outputFile, /get_lun, width=1600
      
      ; Write to text file
      CASE fields OF
      
         0: BEGIN ;X Y Z
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'
            IF headerRow EQ 1 THEN BEGIN
               PRINTF,logASCII,fieldnames
            ENDIF
            formatStr = '(F0, A, F0, A, F0)'
            for b=0L, nChunks -1  do begin
               
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
               
               for i=startsize, tempsize  do begin
                 PRINTF, logASCII, (pData[i].east * header.xScale + header.xOffset), d, $
                    (pData[i].north * header.yScale + header.yOffset), d, $
                    (pData[i].elev * header.zScale + header.zOffset), Format=formatStr
               endfor
               
               ; Initiate status report progress counter... before of after printf?  before seems better to me.
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
            ENDFOR
         END
         
         1: BEGIN ;X Y Z INTENSITY
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'+d+'Intensity'
            IF headerRow EQ 1 THEN BEGIN
               PRINTF,logASCII,fieldnames
            ENDIF
            formatStr = '(F0, A, F0, A, F0, A, I0)'
            for b=0L, nChunks -1  do begin
               
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
               
               ; Initiate status report progress counter
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
               for i=startsize, tempsize  do begin
                 PRINTF, logASCII, $
                    (pData[i].east * header.xScale + header.xOffset), d, $
                    (pData[i].north * header.yScale + header.yOffset), d, $
                    (pData[i].elev * header.zScale + header.zOffset), d, $
                    pData[i].inten, $
                    Format=formatStr
               endfor
               
            ENDFOR
         END
         
         2: BEGIN ;X Y Z R G B
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'+d+'R'+d+'G'+d+'B'
            IF headerRow EQ 1 THEN BEGIN
               PRINTF,logASCII,fieldnames
            ENDIF
            formatStr = '(F0, A, F0, A, F0, A, I0, A, I0, A, I0)'
            for b=0L, nChunks -1  do begin
               
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
               
               ; Initiate status report progress counter
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
               for i=startsize, tempsize  do begin
                 PRINTF, logASCII, $
                    (pData[i].east * header.xScale + header.xOffset), d, $
                    (pData[i].north * header.yScale + header.yOffset), d, $
                    (pData[i].elev * header.zScale + header.zOffset), d, $
                    pData[i].red,d, $
                    pData[i].green,d, $
                    pData[i].blue, $
                    Format=formatStr
               endfor
               
            ENDFOR
         END
         
         3:  BEGIN  ;ALL FIELDS POINT FORMAT 0
         
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'+d+'Intensity'+d+$
               'ReturnNum'+d+'NumOfReturns'+d+'ScanDirFlag'+d+'EdgeFlightLine'+d+$
               'Classification'+d+'ScanAngleRank'+d+'UserData'+d+'PointSourceID'
               
            IF headerRow EQ 1 THEN PRINTF,logASCII,fieldnames
            
            formatStr = '(F0, A, F0, A, F0, A, I0, A, I0, A, I0, A, I0, A, I0, A, I0, A, F0, A, I0, A, I0)'
            
            for b=0L, nChunks -1  do begin
               
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
               
               ; Initiate status report progress counter
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
               for i=startsize, tempsize  do begin
               
                 printf, logASCII, $
                    (pData[i].east * header.xScale + header.xOffset), d, $      ; X_Easting:  X * X scale factor + X offset
                    (pData[i].north * header.yScale + header.yOffset), d, $     ; Y_Northing:  Y * Y scale factor + Y offset
                    (pData[i].elev * header.zScale + header.zOffset), d, $      ; Z_Elevation:  Z * Z scale factor + Z offset
                    pData[i].inten, d, $                                        ; Intensity
                    (pData[i].nReturn MOD 8), d , $                             ; Return Number
                    (floor(pData[i].nReturn/8) MOD 8), d , $                    ; Number of Returns (given pulse)
                    (floor(pData[i].nReturn/64) MOD 2), d , $                   ; Scan Direction Flag
                    (floor(pData[i].nReturn/128) MOD 2), d , $                  ; Edge of Flight Line
                    pData[i].class, d,  $                                       ; Classification
                    pData[i].angle-(256*(floor(pData[i].angle/128) MOD 2)),d, $ ; Scan Angle Rank (-90 to +90) - Left side
                    pData[i].user,d,$                                           ; User Data
                    pData[i].source, $                                          ; Point Source ID
                    Format=formatStr
              
              endfor
              
            ENDFOR
         END
         
         4:  BEGIN   ;ALL FIELDS POINT FORMAT 1 (includes GPS_TIME)
         
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'+d+'Intensity'+d+$
               'ReturnNum'+d+'NumOfReturns'+d+'ScanDirFlag'+d+'EdgeFlightLine'+d+$
               'Classification'+d+'ScanAngleRank'+d+'UserData'+d+'PointSourceID'+d+'GPS_TIME'
               
            IF headerRow EQ 1 THEN PRINTF,logASCII,fieldnames
            
            formatStr = '(F0, A, F0, A, F0, A, I0, A, I0, A, I0, A, I0, A, I0, A, I0, A, F0, A, I0, A, I0, A, F0)'
            
           for b=0L, nChunks -1  do begin
           
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
                            
               ; Initiate status report progress counter
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
               for i=startsize, tempsize  do begin
               
                   printf, logASCII, $
                      (pData[i].east * header.xScale + header.xOffset), d, $      ; X_Easting:  X * X scale factor + X offset
                      (pData[i].north * header.yScale + header.yOffset), d, $     ; Y_Northing:  Y * Y scale factor + Y offset
                      (pData[i].elev * header.zScale + header.zOffset), d, $      ; Z_Elevation:  Z * Z scale factor + Z offset
                      pData[i].inten, d, $                                        ; Intensity
                      (pData[i].nReturn MOD 8), d , $                             ; Return Number
                      (floor(pData[i].nReturn/8) MOD 8), d , $                    ; Number of Returns (given pulse)
                      (floor(pData[i].nReturn/64) MOD 2), d , $                   ; Scan Direction Flag
                      (floor(pData[i].nReturn/128) MOD 2), d , $                  ; Edge of Flight Line
                      pData[i].class, d,  $                                       ; Classification
                      pData[i].angle-(256*(floor(pData[i].angle/128) MOD 2)),d, $ ; Scan Angle Rank (-90 to +90) - Left side
                      pData[i].user,d,$                                           ; User Data
                      pData[i].source,d, $                                        ; Point Source ID
                      pData[i].time, $                                            ; GPS Time
                      Format=formatStr
               
               endfor
               
               
            ENDFOR
         END
         
         5:  BEGIN   ;ALL FIELDS POINT FORMAT 2 (includes RGB)
         
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'+d+'Intensity'+d+$
               'ReturnNum'+d+'NumOfReturns'+d+'ScanDirFlag'+d+'EdgeFlightLine'+d+$
               'Classification'+d+'ScanAngleRank'+d+'UserData'+d+'PointSourceID'+d+'Red'+d+'Green'+d+'Blue'
               
            IF headerRow EQ 1 THEN PRINTF,logASCII,fieldnames
            
            formatStr = '(F0, A, F0, A, F0, A, I0, A, I0, A, I0, A, I0, A, I0, A, I0, A, F0, A, I0, A, I0, A, I0, A, I0, A, I0)'
            
           for b=0L, nChunks -1  do begin
           
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
                            
               ; Initiate status report progress counter
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
               for i=startsize, tempsize  do begin
               
                   printf, logASCII, $
                      (pData[i].east * header.xScale + header.xOffset), d, $      ; X_Easting:  X * X scale factor + X offset
                      (pData[i].north * header.yScale + header.yOffset), d, $     ; Y_Northing:  Y * Y scale factor + Y offset
                      (pData[i].elev * header.zScale + header.zOffset), d, $      ; Z_Elevation:  Z * Z scale factor + Z offset
                      pData[i].inten, d, $                                        ; Intensity
                      (pData[i].nReturn MOD 8), d , $                             ; Return Number
                      (floor(pData[i].nReturn/8) MOD 8), d , $                    ; Number of Returns (given pulse)
                      (floor(pData[i].nReturn/64) MOD 2), d , $                   ; Scan Direction Flag
                      (floor(pData[i].nReturn/128) MOD 2), d , $                  ; Edge of Flight Line
                      pData[i].class, d,  $                                       ; Classification
                      pData[i].angle-(256*(floor(pData[i].angle/128) MOD 2)),d, $ ; Scan Angle Rank (-90 to +90) - Left side
                      pData[i].user,d,$                                           ; User Data
                      pData[i].source,d, $                                        ; Point Source ID
                      pData[i].red,d, $                                             ; Red Band
                      pData[i].green,d, $                                            ; Green Band
                      pData[i].blue, $                                            ; Blue Band                     
                      Format=formatStr
               
               endfor
               
               
            ENDFOR
         END
         
         6:  BEGIN   ;ALL FIELDS POINT FORMAT 1 (includes GPS_TIME)
         
            fieldnames = 'X_Easting'+d+'Y_Northing'+d+'Z_Elevation'+d+'Intensity'+d+$
               'ReturnNum'+d+'NumOfReturns'+d+'ScanDirFlag'+d+'EdgeFlightLine'+d+$
               'Classification'+d+'ScanAngleRank'+d+'UserData'+d+'PointSourceID'+d+'GPS_TIME'+d+$
               'Red'+d+'Green'+d+'Blue'
               
            IF headerRow EQ 1 THEN PRINTF,logASCII,fieldnames
            
            formatStr = '(F0, A, F0, A, F0, A, I0, A, I0, A, I0, A, I0, A, I0, A, I0, A, F0, A, I0, A, I0, A, F0, A, I0, A, I0, A, I0)'
            
           for b=0L, nChunks -1  do begin
           
               if b eq 0 then startsize = 0L $
                  else startsize = tempsize+1
        
               if b eq (nChunks-1) then tempSize = startsize + leftSize  - 1  $
                            else tempSize = startsize + chunkSize - 1
                            
               ; Initiate status report progress counter
               ENVI_REPORT_STAT, statBase, i, n_elements(pData), cancel=cancel
               IF cancel THEN BEGIN
                  ENVI_REPORT_INIT, base=statBase, /finish
                  FREE_LUN, logASCII
                  pData      = 0B
                  RETURN
               ENDIF
               
               for i=startsize, tempsize  do begin
               
                   printf, logASCII, $
                      (pData[i].east * header.xScale + header.xOffset), d, $      ; X_Easting:  X * X scale factor + X offset
                      (pData[i].north * header.yScale + header.yOffset), d, $     ; Y_Northing:  Y * Y scale factor + Y offset
                      (pData[i].elev * header.zScale + header.zOffset), d, $      ; Z_Elevation:  Z * Z scale factor + Z offset
                      pData[i].inten, d, $                                        ; Intensity
                      (pData[i].nReturn MOD 8), d , $                             ; Return Number
                      (floor(pData[i].nReturn/8) MOD 8), d , $                    ; Number of Returns (given pulse)
                      (floor(pData[i].nReturn/64) MOD 2), d , $                   ; Scan Direction Flag
                      (floor(pData[i].nReturn/128) MOD 2), d , $                  ; Edge of Flight Line
                      pData[i].class, d,  $                                       ; Classification
                      pData[i].angle-(256*(floor(pData[i].angle/128) MOD 2)),d, $ ; Scan Angle Rank (-90 to +90) - Left side
                      pData[i].user,d,$                                           ; User Data
                      pData[i].source,d, $                                        ; Point Source ID
                      pData[i].time,d, $                                            ; GPS Time
                      pData[i].red,d, $                                             ; Red Band
                      pData[i].green,d, $                                            ; Green Band
                      pData[i].blue, $                                            ; Blue Band    
                      Format=formatStr
               
               endfor
               
               
            ENDFOR
         END
         
      ENDCASE
      
      ; Close Status reporting widget for the current file
      ENVI_REPORT_INIT, base=statBase, /finish
      
      ; Close the output ascii text file
      FREE_LUN, logASCII
      
      ; Clear up some memory
      pData      = 0B
      
   ENDFOR
   
      
END   ; End the LAS2ASCII Procedure