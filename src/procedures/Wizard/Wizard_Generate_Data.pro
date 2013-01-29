
function Wizard_Generate_Data, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode,  XSIZE=width
  genDataBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, Map=0, /BASE_ALIGN_CENTER, XSIZE=width, SPACE=20)
  titleText = WIDGET_LABEL(genDataBase, value='Generate Result Data', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
  textWidget = WIDGET_TEXT(genDataBase, value="With Height Filtering complete, all that is left is" $
    + " to generate the rasters. Pressing the 'Finish' button will launch the Generate Rasters tool." $
    + " Once complete, the data will reside in a subdirectory off of the input file.", /WRAP, XSIZE=64, YSIZE=4)
 
  
  ;have to specify the event-handler manually when inside a function apparently
  ;XMANAGER, 'Wizard_Generate_Data', genDataBase, EVENT_HANDLER='Wizard_Generate_Data_ev'
  return, genDataBase
END