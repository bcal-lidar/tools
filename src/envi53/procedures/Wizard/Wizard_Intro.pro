PRO Wizard_Intro_Event, ev
  base = ev.handler
  stash = WIDGET_INFO(base, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=introStash, /NO_COPY  
  
  ;get the button pressed
  WIDGET_CONTROL, ev.ID, GET_UVALUE=command
  CASE command OF
    'folderBrowse': BEGIN
      folder = ENVI_PICKFILE(TITLE='Choose an Output Folder', /DIRECTORY) + '\'
      ;folder = 'C:\proc' + '\'     
      WIDGET_CONTROL, introStash.folderLoadText, SET_VALUE=folder 
      WIDGET_CONTROL, ev.TOP, GET_UVALUE=MainStash
      Widget_Control, MainStash.nextBtn, Sensitive=1     
      
      END    
  END
  
  WIDGET_CONTROL, stash, SET_UVALUE=introStash, /NO_COPY
END


function Wizard_Intro, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode
  ;COMPILE_OPT hidden
  
  introBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, /BASE_ALIGN_TOP, XSIZE=450, YSIZE=550, FUNC_GET_VALUE='GetRootFolder', EVENT_PRO='Wizard_Intro_Event')
  
  titleText = WIDGET_LABEL(introBase, value='BCAL LiDAR Processing Wizard', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
    
  descriptionText = WIDGET_LABEL(introBase, value= String(13B) $
    + 'Welcome to the BCAL LiDAR Processing Wizard. '$
    + String(13B) $
    + String(13B) $
    + 'This wizard will guide you through several processing steps '$
    + String(13B) $
    + 'typical for analysing LiDAR data with the BCAL tools. '$ 
    + String(13B) $
    + 'This tool will only include common workflows.' $
    + String(13B) $
    + 'More refined processing may require further investigation with ' $
    + String(13B) $
    + 'the other BCAL LiDAR tools.',$
    /ALIGN_CENTER,  YSIZE=300,  FONT='Arial*18')
    
    ;Directory chooser
    folderLoadRowBase = WIDGET_BASE(introBase, /ROW, /ALIGN_CENTER, XSIZE=width, YOFFSET=50)
    folderLoadLabel = WIDGET_LABEL(folderLoadRowBase, UVALUE='folderLoadLabel', value='Output Folder ', /ALIGN_LEFT, FONT='Arial*15')
    folderLoadText = WIDGET_TEXT(folderLoadRowBase, XSIZE=40, XOFFSET=10, UVALUE='folderName')
    folderLoadBtn = WIDGET_BUTTON(folderLoadRowBase, XSIZE=80, FONT='Arial*15', VALUE='Browse...', UVALUE='folderBrowse', YSIZE=30)
    
    ;save structure for events
    introStash = {folderLoadText:folderLoadText}
    WIDGET_CONTROL, WIDGET_INFO(introBase, /CHILD), SET_UVALUE=introStash, /NO_COPY
    
    return, introBase
END

function GetRootFolder, id

  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=introStash, /NO_COPY
  WIDGET_CONTROL, introStash.folderLoadText, GET_VALUE=folder
  
  WIDGET_CONTROL, stash, SET_UVALUE=introStash, /NO_COPY
  return, folder
end