;+
; NAME:
;
;       HeightGroupsLAS_BCAL 
;
; PURPOSE:
;
;       The purpose of this program is to create separate input LAS file(s) into user-specified 
;       vegetation height groups. Input LAS file must be height-filtered through BCAL LiDAR Tools, or 
;       alternatively, 'Prepare LAS file(s)' tools under 'Create Raster Products' can be used to 
;       assign vegetation height to LiDAR points using an existing bare-earth DEM.
;
; PRODUCTS:
;
;       The output are the LAS files, one for each height group.
;
; AUTHOR:
;
;       Sara Ehinger
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
; KNOWN ISSUES:
;
;
; MODIFICATION HISTORY:
;
;       Written by Sara Ehinger, April 2010.
;       Updated by Sara Ehinger, June 2010.
;       Clean-ups and fixed multiple file creation, September 2010. (Rupesh Shrestha)
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
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
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################

    ; Begin main program

pro HeightGroupsLAS_outputF, event
   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   
   ; Choose output folder location
   path = file_dirname((*pstate).inputFile)
   outputFile = dialog_pickfile(title='Select output LAS folder', $
      path=path, /directory)
      
   if (outputFile EQ '') then return
   (*pstate).outputFile = outputFile
   widget_control, (*pstate).wtxtOutputF, set_value=outputFile
   
end
;------------------------------------------------------------------------------

pro HeightGroupsLAS_btnGroups, event
   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   widget_control, event.id, get_uval=uval
   
   case uval of
      ; Execute the following when the Add button is clicked
      'btnAdd':  begin
         index = (*pstate).nGroups
         if (*pstate).nGroups EQ 10 then begin
            msg = 'Maximum of 10 Groups.'
            msgBox = dialog_message(msg)
         endif else begin
            (*pstate).nGroups += 1
            i = (*pstate).nGroups
            widget_control, (*pstate).wtextGroups, get_value=text
            widget_control, (*pstate).wfieldMin, get_value=tempminH
            widget_control, (*pstate).wfieldMax, get_value=tempmaxH
            tempIndex = where(((*pstate).data).source GE tempMinH AND $
               ((*pstate).data).source LT tempMaxH, count)
            text = [text, 'Group ' + STRTRIM(FIX((*pstate).groupH[i]),2) + ' :  ' + $
               STRTRIM(tempminH,2) + ' <= ' + 'vegetation height' + ' < ' + STRTRIM(tempmaxH,2) + $
               ',  ' + STRTRIM(count,2) + ' points']
            widget_control, (*pstate).wtextGroups, set_value=text, ysize=n_elements(text)+1
            
            (*pstate).minH[i] = tempminH
            (*pstate).maxH[i] = tempmaxH
            widget_control, (*pstate).wfieldMin, set_value=''
            widget_control, (*pstate).wfieldMax, set_value=''
         endelse
      ; The above statements create 0's, wish it just cleared the field
      end
      
      ; Execute the following when the Delete button is clicked
      'btnDel': begin
         widget_control, (*pstate).wtextGroups, get_value=text
         if (*pstate).nGroups GT 0 then begin
            text = text[0:n_elements(text)-2]
            widget_control, (*pstate).wtextGroups, set_value=text, ysize=n_elements(text)+2
            (*pstate).nGroups -= 1
         endif
      end
      
      ; Execute the following when the Reset button is clicked
      'btnReset': begin
         widget_control, (*pstate).wtextGroups, set_value='Vegetation Height Groups:', ysize=3
         (*pstate).nGroups = 0
      end
   endcase
   
end
;------------------------------------------------------------------------------

pro HeightGroupsLAS_btnRun, event
   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   widget_control, event.id, get_uval=uval
   
   case uval of
   
      ; Run the height group program when the OK button is clicked
      'btnRun':  begin
      
         ; Initiate Writing new files notification window.
         envi_report_init, base=base, title='Please Wait', $
            'Writing new LAS files...'
            
         widget_control, (*pstate).wtextGroups, get_value=text
         outputDir = (*pstate).outputFile
         if (outputDir EQ '') then begin
            msg = 'Please select an Output LAS folder'
            msgBox = dialog_message(msg, title='Error')
            return
         endif else begin
         
            data = (*pstate).data
            data.user = 0          ; set all user values to 0 (byte)
            reportNames = ''
            
            for i = 1, (*pstate).nGroups do begin
               tempG = (*pstate).groupH[i]
               tempMin = (*pstate).minH[i]
               tempMax = (*pstate).maxH[i]
               tempIndex = where((data.source GE tempMin) AND (data.source LT tempMax), count)
               
               if count NE 0 then begin
                  data[tempIndex].user = tempG
                  outputFile =  outputDir +  $
                     file_basename((*pstate).inputFile, '.las') + '_group' + $
                     STRTRIM(FIX((*pstate).groupH[i]),2)+ '.las'
                  WriteLAS_BCAL, outputFile, (*pstate).header, data[tempIndex], $
                     records=(*pstate).records, /check
               endif
               reportNames = [reportNames, outputFile]
            endfor
            
            noGroup = where(data.user EQ 0, countNoGroup)
            
            outputFile =  outputDir + $
               file_basename((*pstate).inputFile, '.las') + '_groups' + '.las'
            
            WriteLAS_BCAL, outputFile, (*pstate).header, data, records=(*pstate).records, /check
            
            reportNames = reportNames[1:*]
            reportNames = [outputFile, reportNames]
            
            inputFile = (*pstate).inputFile
            nPoints = ((*pstate).header).nPoints
            report = ['Input File:  ' + inputFile, $
               'Output File(s): ', $
               reportNames, $
               '', $   ; blank line
               text, $ ;     vegetation groups
               '', $   ; blank line
               'Point with no group assigned (Group 0): ' + STRTRIM(countNoGroup, 2), $
               '', $   ; blank line
               'Total number of points: ' + STRTRIM(nPoints, 2), $
               '', $   ; blank line
               'File Created on : ' + systime()]
            ; memory clean-up
            data = 0B
            
            ; close widget
            widget_control, event.TOP, /DESTROY
            
            ; close writing new files status window
            envi_report_init, base=base, /finish
            
            ; display processing information report
            envi_info_wid, report, title='Vegetation Height Groups Info: ', $
               xs=max(strlen(report))+5, ys=n_elements(report)+1
         endelse
      end
      
      ; end the program if the cancel button is clicked
      'btnExit': widget_control, event.TOP, /DESTROY
      
   endcase
   
end
;------------------------------------------------------------------------------

PRO HeightGroupsLAS_cleanup, tlb
   ; This routine is called when the application quits.
   ; Retrieve the state variable and free the pointer.
   widget_control, tlb, GET_UVALUE=pState
   ptr_free, pState
END
;------------------------------------------------------------------------------

pro HeightGroupsLAS_BCAL, event
   compile_opt idl2, logical_predicate
   
   ; Set-up error handler
   catch, theError
   if theError ne 0 then begin
      catch, /cancel
      help, /last_message, output=errText
      envi_report_init, base=base, /finish
      errMsg = dialog_message(errText, /error, title='Error processing request')
      return
   endif
   
   ; Get input LAS file from user
   inputFile = envi_pickfile(title='Select LAS file', filter='*.las')
   if (inputFile eq '') then return
   
   ; Initiate Reading LAS notification window.
   envi_report_init, base=base, title='Please Wait', $
      'Reading LAS file...'
      
   ; Read LAS file into IDL structures.
   ReadLAS_BCAL, inputFile, header, data, records=records, projection=projection
   
   ; get map units from projection structure if available
   units = 'undefined'
   if n_tags(projection) then $
      units = strlowcase(envi_translate_projection_units(projection.units))
      
   ; Get vegetation height statistics from lidar data.
   groundHeight = 0
   errorHeight = 65535
   minHeight = min(data[where(data.source GT 0)].source)
   maxHeight = max(data[where(data.source LT 65535)].source)
   meanHeight = round(mean(data[where(data.source NE 0 and data.source NE 65535)].source))
   stddevHeight = round(stddev(data[where(data.source NE 0 and data.source NE 65535)].source))
   
   groundPts = where(data.class EQ 2, countGround)
   vegPts = where(data.class GE 3, countVeg)
   errorPts = where(data.source EQ 0 OR data.source EQ 1, countError)
   countTotal = n_elements(data)
   
   
   ; Store statistics in a string array for display in the text widget.
   stats = [ $
      'Input File:  ' + inputFile, $
      '', $
      'Z Scale Factor:  ' + STRTRIM(header.zScale, 2), $
      'Map Projection Units:  ' + units, $
      'Note:  Vegetation heights are displayed and input below as integer values.', $
      '     Multiply the vegetation height values by the Z scale factor', $
      '     to calculate heights in the map projection units.', $
      '', $
      'Ground Point Height:                      ' + STRTRIM(groundHeight,2),   $
      'Error Height:                                   ' + STRTRIM(errorHeight,2),   $
      '', $
      'Minimum Vegetation Height:           ' + STRTRIM(minHeight,2),   $
      'Maximum Vegetation Height:          ' + STRTRIM(maxHeight,2),   $
      'Mean Vegetation Height:                ' + STRTRIM(meanHeight,2),   $
      'Standard Deviation:                        ' + STRTRIM(stddevHeight,2),   $
      '', $
      'Number of Ground Returns:           ' + STRTRIM(countGround,2), $
      'Number of Non-ground Returns:    ' + STRTRIM(countVeg,2),    $
      'Number of Classification Errors:     ' + STRTRIM(countError,2),  $
      'Total Number of Returns:              ' + STRTRIM(countTotal,2)]
      
   ; Close Reading LAS notification window.
   envi_report_init, base=base, /finish
   
   ; Set-up top-level base (tlb) widget
   tlb = widget_base(title='Vegetation Height Groups LAS', /column, xoffset=100, yoffset=100, $
      /base_align_center)
      
   ; Set-up text widget to display vegetation height statistics
   wbaseStats = widget_base(tlb, /col, xpad=10, ypad=5)
   wtextStats = widget_text(wbaseStats, value=stats, uvalue='wtextStats', $
      xsize=75, ysize=n_elements(stats)+1)
   ; Need a fixed-width font or table to line up data
      
   ; Set-up widget to define and display user vegetation height groups
   wbaseGroups = widget_base(tlb, /col, xpad=10, ypad=5, /base_align_center)
   groupLabelTxt = ['Enter the minimum and maximum values (integer) for each height group below.', $
      'Then click on the Add Group button']
   wgroupLabel1 = widget_label(wbaseGroups, value=groupLabelTxt[0])
   wgroupLabel2 = widget_label(wbaseGroups, value=groupLabelTxt[1])
   minmaxBase = widget_base(wbaseGroups, /row, tab_mode=1, xpad=1, ypad=1)
   ; /LONG keyword changes the input boxes to gray, wish they stayed white
   wfieldMin = CW_FIELD(minmaxBase, TITLE='Veg Height >= ', /LONG, value=0)
   wfieldMax = CW_FIELD(minmaxBase, TITLE='Veg Height < ', /LONG, value=0)
   
   btnBase = widget_base(wbaseGroups, /row, event_pro='HeightGroupsLAS_btnGroups')
   btnAdd = widget_button(btnBase, value='Add Group', uvalue='btnAdd')
   btnDel = widget_button(btnBase, value='Delete Group', uvalue='btnDel')
   btnReset = widget_button(btnBase, value='Reset', uvalue='btnReset')
   
   textGroups = 'Vegetation Height Groups:'
   wtextGroups = widget_text(wbaseGroups, value=textGroups, uvalue='wtextGroups', $
      xsize=75, ysize=n_elements(textGroups)+2)
      
   ; Set-up widget to select output LAS file name.
   wbaseOutputF = widget_base(tlb, /row, event_pro='HeightGroupsLAS_outputF', $
      xpad=10, ypad=5)
   btnoutputF = widget_button(wbaseOutputF, value='Choose Output LAS Folder', uvalue='btnoutputF')
   outputFile=''
   wtxtOutputF = widget_text(wbaseOutputF, value=outputFile, uvalue='woutputF', $
      xsize=55)       ; or xsize=max(strlen(stats))?
      
   ; Set-up widget with Run and Exit buttons
   btnBase2 = widget_base(tlb, /row, event_pro='HeightGroupsLAS_btnRun', $
      xpad=10, ypad=5)
   wbtnRun = widget_button(btnBase2, value='Run', uvalue='btnRun')
   wbtnExit = widget_button(btnBase2, value='Exit', uvalue='btnExit')
   
   widget_control, tlb, /realize
   
   ; set maximum of 100 groups
   state = {inputFile:inputFile, $
      nGroups:0, groupH:bindgen(101), minH:lonarr(101), maxH:lonarr(101), $
      wfieldMin:wfieldMin, wfieldMax:wfieldMax, wtextGroups:wtextGroups, $
      data:data, header:header, records:records, $
      wtxtOutputF:wtxtOutputF, outputFile:outputFile}         ; lidar data structure
   pstate = ptr_new(state, /no_copy)
   widget_control, tlb, set_uvalue=pstate
   
   xmanager, 'HeightGroupsLAS', tlb, cleanup='HeightGroupsLAS_cleanup'
   
end