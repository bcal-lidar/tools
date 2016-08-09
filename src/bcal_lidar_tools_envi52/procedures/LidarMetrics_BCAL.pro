
PRO LidarMetrics_BCAL, event

compile_opt idl2, logical_predicate
  
Catch, theError
IF theError NE 0 THEN BEGIN
    Catch, /Cancel
    Help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file')
    return
ENDIF
  
    ; read LAS files
    
inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /multiple_files, /path)
if (inputFiles[0] eq '') then return

nFiles = n_elements(inputFiles)

    ; Read the first data file for header info
  
ReadLAS_BCAL, inputFiles[0], header, /nodata

treturns = header.nreturns


    ; read EVF files

evfFiles = dialog_pickfile(title='Select EVF file(s)', filter='*.evf', /path)
if (evfFiles[0] eq '') then return

oEvf = Obj_New('IDLanROIGroup')

for b=0, n_elements(evfFiles)-1 do begin

        evfID     = envi_evf_open(evfFiles[b])
        envi_evf_info, evfID, num_recs=nrecs
        
        for c = 0, nrecs-1 do begin
                evfCoords = envi_evf_read_record(evfID, c)
                oEvf->Add, Obj_New('IDLanROI', evfCoords)
        endfor

        envi_evf_close, evfID
endfor

    ; Create list of metrics

metrics = {minElev :{title:'Minimum', index:-1, doIt:0}, $
           maxElev :{title:'Maximum', index:-1, doIt:0}, $
           rangeElev :{title:'Range', index:-1, doIt:0}, $
           meanElev :{title:'Arithmetic mean', index:-1, doIt:0}, $
           stdevElev :{title:'Standard deviation',index:-1, doIt:0}, $
           varElev :{title:'Variance', index:-1, doIt:0}, $
           skewElev :{title:'Skewness', index:-1, doIt:0}, $
           kurElev :{title:'Kurtosis', index:-1, doIt:0}, $
           cvElev :{title:'Coefficient of variation', index:-1, doIt:0}}

nmetrics   = n_tags(metrics)
metricsList  = strarr(nmetrics)
metricsIndex    = bytarr(nmetrics)
metricsIndex[0] = 1
for f=0, nmetrics-1 do metricsList[f] = metrics.(f).title

    ; initialize the user interface
    
nReturns = n_elements(tReturns)

returnList = indgen(nReturns) + 1
returnList = ' Return ' + strcompress(returnList)
returnList = ['All Returns', returnList]

gridBase = widget_auto_base(title='Lidar Metrics')
topBase    = widget_base(gridBase, /row)
leftBase   = widget_base(topBase, /column)
 
returnBase = widget_base(leftBase, /row)
dummy      = widget_pmenu(returnBase, list=returnList, default=nReturns, prompt='Select return number: ', $
                              uvalue='returns', /auto_manage)  
dummy   = widget_outf(leftBase, default='output.csv', prompt='Enter name of output file ', $
                              uvalue='outFile', /auto)
                              
rightBase = widget_base(topBase)
dummy      = widget_multi(rightBase, list=metricsList, prompt='Select metrics:', /no_range, ysize=250, $
                              default=metricsIndex, uvalue='metrics', /auto)
                              
result = auto_wid_mng(gridBase)

if (result.accept eq 0) then return
retNum    = result.returns + 1
metricsIndex = result.metrics
CsvFile = result.outFile 

    ; Create the list of metrics names

bNames = metricsList[where(metricsIndex eq 1)]
nBands = total(metricsIndex)   

    ; Open output csv file for writing
  
openw,  CSVmetrics, CsvFile, /get_lun, width=1600


for a=0, nFiles-1 do begin
    
    ; Read the data file.
  
  ReadLAS_BCAL, inputFiles[a], header, projection=defProj, pData
  
  iDim = ceil((header.xMax - xMinTile) / 0.5)
  jDim = ceil((header.yMax - yMinTile) / 0.5)
  
  arrayHist = histogram(floor((header.yOffset - header.yMin + pData.north * header.yScale) / baseScale) * xDim $
                        + floor((header.xOffset - header.xMin + pData.east  * header.xScale) / baseScale) $
                        + xDim * yDim * ((retNum le nReturns) and ((pData.nReturn mod 8) ne retNum)) $
                        + xDim * yDim * (pData.class eq 1),  $
                        reverse_indices=arrayIndex, min=0d, max=xDim*yDim)
  
endfor


for o=0, oEvf->Count()-1 do begin
            oTemp = oEvf->Get(position=o)
            oTemp->GetProperty, data=evfCoords
            printf, CSVmetrics, evfCoords[0,*], evfCoords[1,*]
endfor 
    
    
free_lun, CSVmetrics
close, CSVmetrics

;widget_control, gridBase, /destroy
obj_destroy, oEvf

END




