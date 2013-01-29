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
        inputFile = GetFiles()        
        WIDGET_CONTROL, fileLoadStash.fileLoadName, SET_VALUE=inputFile     
        
        ;now we want to try and make the top level next button visible
        WIDGET_CONTROL, ev.TOP, GET_UVALUE=MainStash
        Widget_Control, MainStash.nextBtn, Sensitive=1
        
      END
  ENDCASE
  WIDGET_CONTROL, stash, SET_UVALUE=fileLoadStash, /NO_COPY
  
END

function GetFileName, id
 
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=fileLoadStash, /NO_COPY
  WIDGET_CONTROL, fileLoadStash.fileLoadName, GET_VALUE=fileName
  
  WIDGET_CONTROL, stash, SET_UVALUE=fileLoadStash, /NO_COPY
  return, fileName
end

function Wizard_Data_Input, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode, XSIZE=width
  
  dataInputBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, Map=0, /BASE_ALIGN_LEFT, $
  XSIZE=width, SPACE=20, EVENT_PRO='WIZARD_DATA_INPUT_EV', FUNC_GET_VALUE='GetFileName')
  
  titleText = WIDGET_LABEL(dataInputBase, value='Data Preprocessing', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
  

  descriptionLabel = WIDGET_LABEL(dataInputBase, value= $
    'Please start by uploading a LiDAR dataset either in ' +  String(13b) $
    + '.las or another text format (ASCII).', /ALIGN_LEFT, YSIZE=135, FONT='Arial*16')
  
  ;base widget for the file upload line
  fileLoadRowBase = WIDGET_BASE(dataInputBase, /ROW, /ALIGN_CENTER, XSIZE=width)
  fileLoadLabel = WIDGET_LABEL(fileLoadRowBase, UVALUE='fileLoadLabel', value='Input Dataset: ', /ALIGN_LEFT, FONT='Arial*14')
  fileLoadName = WIDGET_TEXT(fileLoadRowBase, XSIZE=30, XOFFSET=10, /EDITABLE)
  fileLoadBtn = WIDGET_BUTTON(fileLoadRowBase, XSIZE=50, VALUE='Browse...', UVALUE='FileBrowse')
   
   
  fileLoadStash = {fileLoadName:fileLoadName}
  WIDGET_CONTROL, WIDGET_INFO(dataInputBase, /CHILD), SET_UVALUE=fileLoadStash, /NO_COPY
 
  return, dataInputBase
END

;function to get the file from the user and perform analysis
function GetFiles 
  inputFile = ENVI_PICKFILE(TITLE='Select Input LiDAR Dataset', FILTER='*.las') 
  
  return, inputFile[0]
end
