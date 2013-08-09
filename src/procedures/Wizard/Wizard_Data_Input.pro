;+
; This function is to act as the data input tool. We will try to perform some operations automatically and save
; files automatically along the way.  



PRO WIZARD_DATA_INPUT_EV, ev
  
  ;This grabs the local stashed variable
  base = ev.handler
  stash = WIDGET_INFO(base, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=fileLoadStash, /NO_COPY 
 
  ;get the button pressed
  WIDGET_CONTROL, ev.ID, GET_UVALUE=command
  CASE command OF    
    'FileBrowse': BEGIN
        ;get the file
        inputFiles = GetFiles()
        ;get the array
        
        ;list = WIDGET_INFO(fileLoadStash.fileLoadList)
        ;append to existing
        if fileLoadStash.fileList[0] EQ '' then begin
          files = inputFiles
        endif else begin
          files = [fileLoadStash.fileList, inputFiles]
        endelse
        
        ;set back to list        
        WIDGET_CONTROL, fileLoadStash.fileLoadList, SET_VALUE=files     
        
        
        ;now we want to try and make the top level next button visible
        WIDGET_CONTROL, ev.TOP, GET_UVALUE=MainStash
        Widget_Control, MainStash.nextBtn, Sensitive=1
        
        ;recreate the stash as we have a new array
        fileLoadStash ={fileLoadList:fileLoadStash.fileLoadList, selected:fileLoadStash.selected, fileList:files} 
        
      END
    'fileList': BEGIN
        ;set the currently selected item
        fileLoadStash.selected = ev.INDEX
        
      END
    'fileRemove': BEGIN
        if fileLoadStash.selected NE -1 then begin
          index = fileLoadStash.selected
          array =  fileLoadStash.fileList
          first = 0
          last = N_Elements(array)-1
          if last ne 0 then begin            
            CASE index OF
              first: array = array[1:*]
              last: array = array[first:last-1]
              ELSE: array = [ array[first:index-1], array[index+1:last] ]
            ENDCASE
          endif else begin
            array = ['']
          endelse
          ;set back to list
          WIDGET_CONTROL, fileLoadStash.fileLoadList, SET_VALUE=array
          fileLoadStash ={fileLoadList:fileLoadStash.fileLoadList, selected:fileLoadStash.selected, fileList:array}          
        endif
        
      END
  ENDCASE
  WIDGET_CONTROL, stash, SET_UVALUE=fileLoadStash, /NO_COPY
  
END

function GetFileList, id
 
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=fileLoadStash, /NO_COPY
  files = fileLoadStash.fileList
  
  WIDGET_CONTROL, stash, SET_UVALUE=fileLoadStash, /NO_COPY
  return, files
end

function Wizard_Data_Input, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode, XSIZE=width
  
  dataInputBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, Map=0, /BASE_ALIGN_LEFT, $
  XSIZE=width, SPACE=20, EVENT_PRO='WIZARD_DATA_INPUT_EV', FUNC_GET_VALUE='GetFileList')
  
  titleText = WIDGET_LABEL(dataInputBase, value='Data Preprocessing', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
  

  descriptionLabel = WIDGET_LABEL(dataInputBase, value= $
    'Please start by uploading a LiDAR dataset either in ' +  String(13b) $
    + '.las or another text format (ASCII).', /ALIGN_LEFT, YSIZE=135, FONT='Arial*16')
  
  ;base widget for the file upload line
  fileLoadRowBase = WIDGET_BASE(dataInputBase, /ROW, /ALIGN_CENTER, XSIZE=width)
  fileLoadLabel = WIDGET_LABEL(fileLoadRowBase, UVALUE='fileLoadLabel', value='Input Dataset: ', /ALIGN_LEFT, FONT='Arial*15')
  
  fileLoadList = WIDGET_LIST(fileLoadRowBase, XSIZE=50, YSIZE=10, XOFFSET=10, UVALUE='fileList')
  fileList = ['']
  selected = -1
  
  btnsGroup = WIDGET_BASE(fileLoadRowBase, UVALUE='btnBase', XSIZE=125, /COLUMN)
  
  fileLoadBtn = WIDGET_BUTTON(btnsGroup, XSIZE=125, FONT='Arial*15', VALUE='Add File', UVALUE='FileBrowse', YSIZE=30)
  fileRemoveBtn = WIDGET_BUTTON(btnsGroup, XSIZE=125, FONT='Arial*15', VALUE='Remove Selected', UVALUE='fileRemove',YSIZE=30, YOFFSET=20)
   
   
  
  fileLoadStash = {fileLoadList:fileLoadList, selected:selected, fileList:fileList}
  
  WIDGET_CONTROL, WIDGET_INFO(dataInputBase, /CHILD), SET_UVALUE=fileLoadStash, /NO_COPY
 
  return, dataInputBase
END

;function to get the file from the user and perform analysis
function GetFiles 
  inputFiles = ENVI_PICKFILE(TITLE='Select Input LiDAR Dataset', FILTER='*.las', /MULTIPLE_FILES)
  ;inputFile = 'C:\Users\moverton\Downloads\51763504\PeaRiv000017\PeaRiv000017.las'
  return, inputFiles
end
