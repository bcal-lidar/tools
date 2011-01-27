;+
;
;Name:  GroundPointsLAS_BCAL.pro
;
;Purpose:  To create an LAS file containing only ground points.
;          Data must be height filetered using the BCAL tools.
;          Only ground points (CLASS=2) will be exported to the new LAS File.
;
;Calling Sequence:  GroundPointsLAS_BCAL
;
;Inputs:  LAS format lidar data height filtered with BCAL tools.
;
;Outputs:  LAS file containing ground points only (CLASS=2)
;
;Keywords:  lidar, ground
;
;Dependencies:  
;   ReadLAS_BCAL.pro
;   WriteLAS_BCAL.pro
;   
;Author and History
;   Sara Ehinger
;   Last Modified on February 16, 2010
;   http://bcal.geology.isu.edu/
;##############################################################################
;-

; Begin main program
pro GroundPointsLAS_BCAL, event

; Set compile options:  DEFINT32, STRICTARR, LOGICAL_PREDICATE
; DEFINT32:  IDL should assume that lexical integer constants default to the 32-bit type
;            rather than the usual default of 16-bit integers. 
; STRICTARR: While compiling this routine, IDL will not allow the use of parentheses to index arrays, 
;            reserving their use only for functions. Square brackets are then the only way to index arrays.
; LOGICAL_PREDICATE:  Treat any non-zero or non-NULL predicate value as "true," 
;            and any zero or NULL predicate value as "false." 
compile_opt idl2, logical_predicate

; Error Handler
Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   Help, /last_message, output=errText
   errMsg = dialog_message(errText, /error, title='Error processing file')
   return
ENDIF
   
; Get the input file name from user
inputFile = envi_pickfile(title='Select LAS file', filter='*.las')
   if (inputFile eq '') then return
   
; Set the output file name
outputDir = FILE_DIRNAME(inputFile)
outputBase = FILE_BASENAME(inputFile, '.las') + '_GroundOnly.las'
outputFile = outputDir + '\' + outputBase

; Set up ENVI status reporting box
statText1 = 'Processing...'
statText2 = 'Input file: ' + FILE_BASENAME(inputFile)
statText3 = 'Ouput file: ' + FILE_BASENAME(outputFile)
statText = [statText1,statText2,statText3]

statBase = widget_auto_base(title='Processing')
ENVI_REPORT_INIT, statText, BASE=statBase, TITLE='Processing'
   
; Read input lidar data to an array of structures
ReadLAS_BCAL, inputFile, header, data, records=records, check=check, projection=projection

;Get number of data points in original LAS file for later reporting
numOrigPts = header.nPoints

; Create an array containing the index values of ground points only
groundA = WHERE(data.Class EQ 2, count)

; Create a new empty lidar point data structure
dataStr2 = InitDataLAS_BCAL(pointFormat=header.POINTFORMAT)

; Begin processing only if one or more ground points are found
; Otherwise show error message and end program
IF count GT 0 THEN BEGIN 

   ;  Create a new array or structures with one structure for each ground point
   dataG = replicate(dataStr2, count)
   
   ; Set the increment used in tile processing for status reporting widget
   envi_report_inc,  statBase, count

   ; Copy each structure corresponding to a gound point in the original lidar data set (data)
   ; to the new structure for the ground point only lidar data set (dataG)
   for a=0,count-1 do begin
      envi_report_stat, statBase, a, count
      tempGIndex = groundA[a]
      dataG[a] = data[tempGIndex]
   endfor 


ENDIF ELSE BEGIN
   msgTxt = FILE_BASENAME(inputFile) + ' has no ground points (CLASSIFICATION=2).  Procedure cancelled.'
   msgBox = DIALOG_MESSAGE(msgTxt, /ERROR)
   envi_report_init, base=StatBase, /finish 
   data = 0B
   Catch, /Cancel
   RETURN
ENDELSE

; Write the header and data to a new file in the output directory

WriteLAS_BCAL, outputFile, header, dataG, records=records, /check

msgTxt1 = FILE_BASENAME(inputFile) + ' processed successfully!'
msgTxt2 = STRTRIM(numOrigPts) + ' points in original LAS file.'
msgTxt3 = STRTRIM(count) + ' points in new ground-only LAS file.'
msgTxt4 = ''
msgTxt5 = 'Output file location and name:'
msgTxt6 = outputFile
msgTxt = [msgTxt1,msgTxt2,msgTxt3,msgTxt4,msgTxt5,msgTxt6]
msgBox = DIALOG_MESSAGE(msgTxt, /INFORMATION)

; Clear up some memory
data      = 0B
dataG     = 0B
header    = 0B

; Complete status reporting widget
envi_report_init, base=StatBase, /finish 

; Clear Error Handler
Catch, /Cancel

END

