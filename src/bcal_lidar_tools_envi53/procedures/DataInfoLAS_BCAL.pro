;+
; NAME:
;
;       DataInfoLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is display data information of a selected
;       LAS file. It produces descriptive statistics of the data, normally not contained 
;       in the LAS header file.
;
; PRODUCTS:
;
;
; AUTHOR:
;
;       Rupesh Shrestha
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://bcal.geology.isu.edu
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;
; KNOWN ISSUES:
;
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
; Copyright @ 2010 Rupesh Shrestha, Idaho State University.
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

pro DataInfoLAS_dropdown, event

compile_opt idl2, logical_predicate

    ; Establish an error handler

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing file')
    return
endif

widget_control, event.top, get_uvalue=pstate
widget_control, event.id, get_value=dropList
index = event.index
fieldSelect = dropList[index]

Case fieldSelect of
    'Elevation': begin
    hist = Histogram(((*pstate).pdata).elev * ((*pstate).header).zScale + ((*pstate).header).zOffset, nbins=300, loc=xaxis)
    
    plot,  xaxis, hist, xtitle='Elevation', ytitle='Total lidar points', xstyle=1
    
    end

    'Returns': begin
    hist = Histogram(((*pstate).pdata).nReturn mod 8, min=0, $
          max=4, binsize=1, loc=xaxis)
    
    plot,  xaxis, hist, xtitle='Returns', ytitle='Total lidar points', xstyle=1
    
    end

    'Classification': begin
    hist = Histogram(((*pstate).pdata).class, min=min(((*pstate).pdata).class), $
          max=max(((*pstate).pdata).class), binsize=1, loc=xaxis)
    
    plot,  xaxis, hist, xtitle='Classification', ytitle='Total lidar points', xstyle=1
    
    end

    'Intensity': begin
    
    hist = Histogram(((*pstate).pdata).inten, min=0, $
          max=255, nbins=256,loc=xaxis)
    
    plot,  xaxis, hist, xtitle='Intensity', ytitle='Total lidar points', xstyle=1
    
    end

    'Scan Angle': begin
    hist = Histogram((((*pstate).pdata).angle -128B)-128, min=min(((*pstate).pdata).angle-128B)-128, $
          max=max(((*pstate).pdata).angle-128B)-128, binsize=1, loc=xaxis)
    
    plot,  xaxis, hist, xtitle='Scan angle', ytitle='Total lidar points', xstyle=1
    end

    'Veg. Height': begin
    vegindex=where(((*pstate).pdata).class eq 3, vegcount)
      if vegcount then begin
      hist = Histogram(((*pstate).pdata)[vegindex].source * ((*pstate).header).zScale, $
            binsize=0.1,loc=xaxis)
      
      plot,  xaxis, hist, xtitle='Veg. Height', ytitle='Total lidar points', xstyle=1
      endif
    end

    'Time': begin
    hist = Histogram((((*pstate).pdata).time), nbins=300, loc=xaxis)
    
    plot,  xaxis, hist, xtitle='Time', ytitle='Total lidar points', xstyle=1
    end

endcase

end

PRO DataInfoLAS_BCAL_exit, event

   widget_control, event.TOP, /DESTROY
   
END

pro DataInfoLAS_BCAL_cleanup, infoBase

   compile_opt idl2, logical_predicate
   
   widget_control, infoBase, get_uvalue=pstate
   
   ptr_free, pstate
   
END


pro DataInfoLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish an error handler

;catch, theError
;if theError ne 0 then begin
;    catch, /cancel
;    help, /last_message, output=errText
;    errMsg = dialog_message(errText, /error, title='Error processing file')
;    return
;endif

    ; Get the file

file = dialog_pickfile(title='Select LAS file', filter='*.las', /path)
if file eq '' then return

; Set up ENVI status reporting box
statText = 'Reading LAS file: ' + FILE_BASENAME(file)
statBase = widget_auto_base(title='Reading')
ENVI_REPORT_INIT, statText, BASE=statBase, TITLE='Reading'
envi_report_inc,  statBase, 10

    ; Read the file, getting all information except the data

ReadLAS_BCAL, file, header, pdata
  
; get area
bPoints  = GetBounds_BCAL(pdata.east * header.xScale, pdata.north * header.yScale)
bArea    = poly_area(pdata[bPoints].east  * header.xScale + header.xOffset, $
                         pdata[bPoints].north * header.yScale + header.yOffset) 
  
; elevation statistics
minelev= min(pData.elev * header.zScale + header.zOffset, max=maxelev)
momelev= moment(pData.elev * header.zScale + header.zOffset, sdev=sdevelev)
delev = {felev0, Minimum:minelev, $
         Maximum:maxelev, $
         Mean:momelev[0], $
         StDev:sdevelev, $
         Skewness:momelev[2], $
         Kurtosis:momelev[3]}
  

; intensity statistics
mininten= min(pData.inten, max=maxinten)
mominten= moment(pData.inten, sdev=sdevinten)
dinten = {felev0, Minimum:mininten, $
         Maximum:maxinten, $
         Mean:mominten[0], $
         StDev:sdevinten, $
         Skewness:mominten[2], $
         Kurtosis:mominten[3]}

;scan angle statistics

minangle= min(pData.angle-128B, max=maxangle)
momangle= moment((pData.angle-128B), sdev=sdevangle)
dangle = {felev0, Minimum:minangle - 128, $
         Maximum:maxangle - 128, $
         Mean:momangle[0] - 128, $
         StDev:sdevangle, $
         Skewness:momangle[2], $
         Kurtosis:momangle[3]}

data = [delev, dinten, dangle]

;vegetation height statistics
vegindex=where(pData.class eq 3, vegcount)
if vegcount then begin 
  minveg= min(pData[vegindex].source * header.zScale, max=maxveg)
  momveg= moment(pData[vegindex].source * header.zScale, sdev=sdevveg)
  dveg = {felev0, Minimum:minveg, $
           Maximum:maxveg, $
           Mean:momveg[0], $
           StDev:sdevveg, $
           Skewness:momveg[2], $
           Kurtosis:momveg[3]}
           
  data = [delev, dinten, dangle, dveg]
endif    
     
envi_report_inc,  statBase, 1   
        
pDensity = floor(header.npoints/bArea)

;Class histogram
strClass = ''
strClassName = ''
for c=0, 12 do begin
  dummy = where(pdata.class eq c, classCount)
  if classcount then strClassName = strClassName + 'Class ' +strcompress(c)+'  -- '  
  if classcount then strClass = strClass + strcompress(classCount)+'  -- '
endfor

; count flight lines
   
if (header.pointFormat eq 1) or (header.pointFormat eq 3) then begin
     minTime = min(pdata.time, max=maxTime)
     
     tMin = floor(minTime)
     tMax =  ceil(maxTime)
     tRange = tMax - tMin
     tHist = histogram(pdata.time, min=tMin)
     tLine = ([0,tHist[0:tRange-2]] eq 0) and (tHist[0:tRange-1] ne 0)
     nLines = total(tLine, /integer) 
    
     datainfo = ['File name: ' + file, $
            'Total area: ' + strtrim(bArea,2), $
            'Average point density: ' + strtrim(pDensity), $
            'Number of flight lines: ' + strtrim(nLines,2), $
            'Start time: ' + strcompress(minTime), $
            'End time: ' + strcompress(maxTime), $
            '', $
             'Histogram of classified points:', $
             strClassName, $
             strClass]
             
     dropList = ['Elevation', $
            'Returns', $
            'Classification', $
            'Intensity', $
            'Scan Angle', $
            'Veg. Height', $
            'Time']
             
endif else begin
    
    datainfo = ['File name: ' + file, $
            'Total area: ' + strtrim(bArea,2), $
            'Average point density: ' + strtrim(pDensity), $
            '', $
             'Histogram of classified points:', $
             strClassName, $
             strClass]
             
    dropList = ['Elevation', $
            'Returns', $
            'Classification', $
            'Intensity', $
            'Scan Angle', $
            'Veg. Height']

endelse




rlabels = ['Elevation', 'Intensity', 'ScanAngle', 'VegHeight']
clabels = ['Min', 'Max', 'Mean', 'StDev', 'Skew', 'Kurt']
             
    
    ; Create the widget that will record the user parameters

envi_report_init, base=statBase, /finish 

infoBase = widget_base(title='LAS Data Information', /base_align_center)

textBase   = widget_base(infoBase, /column)
dummy      = widget_text(textBase, value = datainfo, ysize=10, /scroll)
    
tableBase = widget_base(textbase, /column)
dummy = widget_label(tablebase, value="Basic statistics:", /align_left)
dummy = widget_table(tablebase, value=data, /row_major, uvalue='tvalue', $
                column_labels = clabels, row_labels=rlabels, /resizeable_columns)

drawBase = widget_base(textbase, /column)
dropBase = widget_base(drawbase, /column)
dropFields = widget_droplist(dropBase, VALUE=dropList, $
      title='Histogram by: ',event_pro='DataInfoLAS_dropdown')
      
dummy = widget_draw(drawbase, xsize=500, ysize=300)

state = {pdata:pdata, $
         header:header}
pstate = ptr_new(state, /NO_COPY)

widget_control, infoBase, /REALIZE
widget_control, infoBase, set_uvalue=pstate, /realize

hist = Histogram(pdata.elev * header.zScale + header.zOffset, min=header.zMin, $
      max=header.zmax, nbins=300, loc=xaxis)

plot,  xaxis, hist, xtitle="Elevation", ytitle='No. of returns', xstyle=1

xmanager, 'DataInfoLAS_BCAL', infoBase, cleanup='DataInfoLAS_BCAL_cleanup'

end