; Sara Ehinger
; March 31, 2010
; Export Selected Returns Only
; First, Second, Third, Fouth, Fifth, Last
; DEPENDENCIES:
;
;       INITDATALAS_BCAL.pro

PRO ReturnsLAS_BCAL, event

  compile_opt idl2, logical_predicate
  
  Catch, theError
  IF theError NE 0 THEN BEGIN
    Catch, /Cancel
    Help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file')
    return
  ENDIF
  
  inputFile = envi_pickfile(title='Select LAS file', filter='*.las')
  if (inputFile eq '') then return
  
  ; ugh, need a god damn widget
  ; for return number and output file name
  ; for now hard code
  ; Drop down:
  ; Last Returns, 0
  ; First Returns, 1
  ; Second Returns, 2
  ; Third Returns, 3
  ; Fouth Returns, 4
  ; Fifth Returns, 5
  ; sReturn = result
  ; try first with old school idl widgets
  ; never mind, just use fancy envi auto widgets
  
  ReadLAS_BCAL, inputFile, header, data, records=records, projection=projection
  numOrigPts = header.nPoints
  numReturns = header.nReturns
  
  topBase = widget_auto_base(title='Export lidar data by return number')
  
  labelText = 'Selected File: ' + file_basename(inputFile)
  labelBase = widget_slabel(topBase, prompt=labelText, /frame)
  
  returnList = ['Last Returns','First Returns','Second Returns','Third Returns','Fourth Returns','Fifth Returns']
  returnBase = widget_pmenu(topBase, prompt='Select Returns', list=returnList, uvalue='outr', /auto)
  
  defOutF = file_dirname(inputFile) + '\' + file_basename(inputFile, '.las') + '_selected' + '.las'
  outBase = widget_outf(topBase, default=defOutF, uvalue='outf', /auto)
  
  result = auto_wid_mng(topBase)
  if result.accept eq 0 then return
  
  
  sReturn = result.outr
  outputFile = result.outf
  
  
  
  CASE sReturn OF
    0: exportA = WHERE(floor(data.nReturn/8) mod 8 - data.nReturn mod 8 EQ sReturn, count)
    ELSE: exportA = WHERE(data.nReturn mod 8 EQ sReturn, count)
  ENDCASE
  ; warning if count = 0!
  
  IF count GT 0 THEN BEGIN
    dataStr2 = InitDataLAS_BCAL(pointFormat=header.POINTFORMAT)
    data2 = replicate(dataStr2, count)
    for a=0,count-1 do begin
      tempIndex = exportA[a]
      data2[a] = data[tempIndex]
    endfor
  ENDIF ELSE BEGIN
    msgText = 'There were no returns that matched your selection.  Export cancelled.'
    msgBox = dialog_message(msgText)
    ; Add a return to widget?
    RETURN
  ENDELSE
  
  WriteLAS_BCAL, outputFile, header, data2, records=records, /check
  
  msgText = strcompress([sReturn, numOrigPts, count])
  msgBox = dialog_message(msgText, /information)
  
  data      = 0B
  data2     = 0B
  header    = 0B
  
END              ; ReturnsLAS.pro


