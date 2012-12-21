


function Wizard_Intro, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode
  ;COMPILE_OPT hidden
  
  introBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, /BASE_ALIGN_TOP, XSIZE=450, YSIZE=550)
  
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
    
    return, introBase
END