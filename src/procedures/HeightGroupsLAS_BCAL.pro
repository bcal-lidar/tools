; sara ehinger
; april 11, 2010
; working on tool to classify by height groups
; add warning if las file has not been processed with ISU BCAL tools?
;------------------------------------------------------------------------------

pro HeightGroupsLAS_BCAL_Event, event
   ; default message to capture any undefined procedures for testing
   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   widget_control, event.id, get_uval=uval
   msg = 'Undefined Event: ' + uval
   msgBox = dialog_message(msg)
end
;------------------------------------------------------------------------------

pro HeightGroupsLAS_BCAL_outF, event
   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   outputFile = dialog_pickfile(title='Select output LAS file', $
      file=(*pstate).outputFile, /write, /overwrite_prompt, $
      filter='*.las', default_extension='las')
   (*pstate).outputFile = outputFile
   widget_control, (*pstate).woutF, set_value=outputFile
end
;------------------------------------------------------------------------------

pro HeightGroupsLAS_BCAL_btnLevels, event

   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   widget_control, event.id, get_uval=uval
   
   case uval of
      ; Execute the following when the Add button is clicked
      'btnAdd':  begin
         index = (*pstate).nlevels
         if (*pstate).nlevels EQ 10 then begin
            msg = 'Maximum of 10 levels.'
            msgBox = dialog_message(msg)
         endif else begin
            (*pstate).nlevels += 1
            i = (*pstate).nlevels
            widget_control, (*pstate).wtextLevels, get_value=text
            widget_control, (*pstate).wfieldMin, get_value=tempminH
            widget_control, (*pstate).wfieldMax, get_value=tempmaxH
            tempIndex = where(((*pstate).data).source GE tempMinH AND $
               ((*pstate).data).source LT tempMaxH, count)
            text = [text, 'Group ' + STRING((*pstate).groupH[i]) + ' :  ' + $
               STRTRIM(tempminH,2) + ' <= ' + 'vegetation height' + ' < ' + STRTRIM(tempmaxH,2) + $
               ',  ' + STRTRIM(count,2) + ' points']
            widget_control, (*pstate).wtextLevels, set_value=text, ysize=n_elements(text)+1
            
            (*pstate).minH[i] = tempminH
            (*pstate).maxH[i] = tempmaxH
            widget_control, (*pstate).wfieldMin, set_value=''
            widget_control, (*pstate).wfieldMax, set_value=''
         endelse
      ; The above statements create 0's, wish it just cleared the field
      end
      ; Execute the following when the Delete button is clicked
      'btnDel': begin
         widget_control, (*pstate).wtextLevels, get_value=text
         if (*pstate).nlevels GT 0 then begin
            text = text[0:n_elements(text)-2]
            widget_control, (*pstate).wtextLevels, set_value=text, ysize=n_elements(text)+2
            (*pstate).nlevels -= 1
         endif
      end
      ; Execute the following when the Reset button is clicked
      'btnReset': begin
         widget_control, (*pstate).wtextLevels, set_value='Vegetation Height Groups:', ysize=3
         (*pstate).nlevels = 0
      end
   endcase
   
end
;------------------------------------------------------------------------------

pro HeightGroupsLAS_BCAL_btnRun, event

   compile_opt idl2, logical_predicate
   widget_control, event.top, get_uvalue=pstate
   widget_control, event.id, get_uval=uval
   
   case uval of
      ; Run the height group program when the OK button is clicked
      'btnOK':  begin
         widget_control, (*pstate).wtextLevels, get_value=text
         outputFile = (*pstate).outputFile
         if file_test(outputFile) then begin
            msg = [outputFile + ' already exists.', $
               'Do you want to replace it?']
            msgOverwrite = dialog_message(msg, /question, /default_no, $
               title='Select output LAS file')
            if msgOverwrite eq 'No' then return
         endif
         ; ((*pstate).data).source
         ; ((*pstate).data)[10000].source
         data = (*pstate).data
         data.user = 0          ; set all user values to 0 (byte)
         for i = 1, (*pstate).nlevels do begin
            tempG = (*pstate).groupH[i]
            tempMin = (*pstate).minH[i]
            tempMax = (*pstate).maxH[i]
            tempIndex = where((data.source GE tempMin) AND (data.source LT tempMax), count)
            if count NE 0 then data[tempIndex].user = tempG
;            msg = STRING(tempG) + ' ' + STRTRIM(count,2)
;            msgBox = dialog_message(msg, /info)
         endfor
         noGroup = where(data.user EQ 0, countNoGroup)
         
         WriteLAS_BCAL, outputFile, (*pstate).header, data, records=(*pstate).records, /check
         
         inputFile = (*pstate).inputFile
         nPoints = ((*pstate).header).nPoints
         report = ['Input File:  ' + inputFile, $
         'Output File: ' + outputFile, $
         '', $   ; blank line
         text, $ ;     vegetation groups
         '', $   ; blank line
         'Point with no group assigned: ' + STRTRIM(countNoGroup, 2), $
         '', $   ; blank line
         'Total number of points: ' + STRTRIM(nPoints, 2), $
         '', $   ; blank line
         'File Created on : ' + systime()]
         ; memory clean-up
         data = 0B
         widget_control, event.TOP, /DESTROY
         envi_info_wid, report, title='Info: ', xs=max(strlen(report))+5, ys=40
      end
      ; end the program if the cancel button is clicked
      'btnCancel': widget_control, event.TOP, /DESTROY
      
   endcase
   
end
;------------------------------------------------------------------------------

PRO HeightGroupsLAS_BCAL_cleanup, tlb
   ; This routine is called when the application quits.
   ; Retrieve the state variable and free the pointer.
   widget_control, tlb, GET_UVALUE=pState
   ptr_free, pState
END
;------------------------------------------------------------------------------

pro HeightGroupsLAS_BCAL, event

   compile_opt idl2, logical_predicate
   
       ; Establish an error handler

    catch, theError
    if theError ne 0 then begin
      catch, /cancel
      help, /last_message, output=errText
      errMsg = dialog_message(errText, /error, title='Error reading file')
      return
    endif
   
   inputFile = envi_pickfile(title='Select LAS file(s)', filter='*.las')
   if (inputFile eq '') then return
   
   ReadLAS_BCAL, inputFile, header, data, records=records, projection=projection ;, check=check?
   ; add processing cursor or message
   
   ; get stats
   groundHeight = 0
   minHeight = min(data[where(data.source GT 0)].source)
   maxHeight = max(data[where(data.source LT 65535)].source)
   errorHeight = 65535
   countGround = n_elements(where(data.class EQ 2))
   countVeg = n_elements(where(data.class EQ 3))
   countError = n_elements(where(data.source EQ 65535))
   ; is the n_elements where height is 65535 always the same as the n_elements where class is 0 or 1?
   countTotal = n_elements(data)
   stats = ['Directory:  ' + file_dirname(inputFile),  $
      'Input File: ' + file_basename(inputFile), $
      '', $
      'Ground Point Height:                      ' + STRTRIM(groundHeight,2),   $
      'Minimum Vegetation Height:           ' + STRTRIM(minHeight,2),   $
      'Maximum Vegetation Height:          ' + STRTRIM(maxHeight,2),   $
      'Error Height:                                   ' + STRTRIM(errorHeight,2),   $
      '', $
      'Number of Ground Returns:           ' + STRTRIM(countGround,2), $
      'Number of Non-ground Returns:    ' + STRTRIM(countVeg,2),    $
      'Number of Classification Errors:     ' + STRTRIM(countError,2),  $
      'Total Number of Returns:              ' + STRTRIM(countTotal,2)]
      
   tlb = widget_base(title='Levels', /column, xoffset=100, yoffset=100)
   
   wtextStats = widget_text(tlb, value=stats, uvalue='wtextStats',ysize=13)
   ; Need a fixed-width font or table to line up data
   
   inputBase = widget_base(tlb, /row, tab_mode=1, title='Enter Min and Max: ')  ;, /FRAME
   ; Press Alt+242 for ≥ and Press Alt+243 for ≤
   ; these didn't work
   wfieldMin = CW_FIELD(inputBase, TITLE='Veg Height >= ', /LONG, value=0)
   wfieldMax = CW_FIELD(inputBase, TITLE='Veg Height < ', /LONG, value=0)
   ; /LONG keyword changes the input boxes to gray, wish they stayed white
   
   textLevels = 'Vegetation Height Groups:'
   wtextLevels = widget_text(tlb, value=textLevels, uvalue='wtextLevels', $
      ysize=n_elements(textLevels)+2)
      
   btnBase = widget_base(tlb, /row, event_pro='HeightGroupsLAS_BCAL_btnLevels')
   btnAdd = widget_button(btnBase, value='Add Level', uvalue='btnAdd')
   btnDel = widget_button(btnBase, value='Delete Level', uvalue='btnDel')
   btnReset = widget_button(btnBase, value='Reset', uvalue='btnReset')
   
   outBase = widget_base(tlb, /row, event_pro='HeightGroupsLAS_BCAL_outF', /frame)
   btnOutF = widget_button(outBase, value='Choose output LAS file', uvalue='btnOutF')
   outputFile = file_dirname(inputFile) + '\' + file_basename(inputFile, '.las') + $
      '_groups' + '.las'
   woutF = widget_text(outBase, value=outputFile, uvalue='woutF', $
      xsize=50)       ; or xsize=max(strlen(stats))?
      
   btnBase2 = widget_base(tlb, /row, event_pro='HeightGroupsLAS_BCAL_btnRun')
   btnOK = widget_button(btnBase2, value='OK', uvalue='btnOK')
   btnCancel = widget_button(btnBase2, value='Cancel', uvalue='btnCancel')
   
   widget_control, tlb, /realize
   
   ; assume ten levels max, add option to set number or levels
   ; just assume 100 levels max?
   ; other options?
   state = {nlevels:0, groupH:bindgen(11)+64B, minH:lonarr(11), maxH:lonarr(11), $
      wfieldMin:wfieldMin, wfieldMax:wfieldMax, wtextLevels:wtextLevels, $
      data:data, header:header, records:records, $
      woutF:woutF, outputFile:outputFile, inputFile:inputFile}         ; lidar data structure
   pstate = ptr_new(state, /no_copy)
   widget_control, tlb, set_uvalue=pstate
   
   xmanager, 'HeightGroupsLAS_BCAL', tlb, cleanup='HeightGroupsLAS_BCAL_cleanup'
   
end
;------------------------------------------------------------------------------

; END HeightGroupsLAS.pro