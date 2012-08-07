PRO Wizard_Generate_Data_ev, ev
WIDGET_CONTROL, ev.ID, GET_UVALUE=command
  CASE command OF
    'HeightFilter': HeightLAS_BCAL, ev
    'PrepareData': PrepareLAS_BCAL, ev
    'CreateRaster': LidarRasterLAS_BCAL, ev
    'Visualize': Visualize3D_BCAL, ev
    'ExportASCII': LASToAscii_BCAL, ev    
  ENDCASE
END


function Wizard_Generate_Data, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode,  XSIZE=width
  genDataBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, Map=0, /BASE_ALIGN_LEFT, XSIZE=width, SPACE=20)
  titleText = WIDGET_LABEL(genDataBase, value='Generate Result Data', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
  
  descriptionLabel = WIDGET_LABEL(genDataBase, value= $
      'Before we can generate datasets from the LiDAR data,  ' + String(13b) $
    + 'our dataset must be height filtered. If this is a new dataset,' + String(13b) $
    + 'use the Perform Height Filtering tool. If the data is height filtered' + String(13b) $
    + 'with a non-BCAL toolset, use the Prepare LAS tool. Otherwise, you can' + String(13b) $
    + 'skip this step and continue on to the Generate Raster Tool.' + String(13b) $
    + 'Finally, you can visualize results or export them to ASCII for external use.' + String(13b) $    
    + 'When finished, click ''Done'' to quit.' + String(13b) $
    ,/ALIGN_LEFT,YSIZE=140, FONT='Arial*16')  
    
  hLabel = WIDGET_LABEL(genDataBase, value='Height Filtering Tools', FONT='Arial*BOLD*UNDERLINE*18', $
    XSIZE=width, /ALIGN_CENTER)
    
  hFilterBase = WIDGET_BASE(genDataBase, /COLUMN, /ALIGN_CENTER)
  hFilterBtnGroup = WIDGET_BASE(hFilterBase, /ROW, /ALIGN_CENTER)
  hFilterBtn = WIDGET_BUTTON(hFilterBtnGroup, VALUE='Perform Height Filtering', UVALUE='HeightFilter', XSIZE=150, YOFFSET=25)
  prepareLASBtn = WIDGET_BUTTON(hFilterBtnGroup, VALUE='Prepare LAS Data', UVALUE='PrepareData', XSIZE=150, YOFFSET=25)
  
  ;Raster Creation Tools
  rasterLabel = WIDGET_LABEL(genDataBase, value='Raster Creation Tools', FONT='Arial*BOLD*UNDERLINE*18', $
    XSIZE=width, /ALIGN_CENTER)
  
  rasterToolsBase = WIDGET_BASE(genDataBase, /COLUMN, /ALIGN_CENTER)
  rasterToolsGroup = WIDGET_BASE(rasterToolsBase, /ROW, /ALIGN_CENTER)
  rasterCreationBtn = WIDGET_BUTTON(rasterToolsGroup, VALUE='Create Raster Tool', UVALUE='CreateRaster', XSIZE=150) 
  
  ;Visualize and Export
  veLabel = WIDGET_LABEL(genDataBase, value='Visualize and Export Tools', FONT='Arial*BOLD*UNDERLINE*18', $
    XSIZE=width, /ALIGN_CENTER)
  
  veToolsBase = WIDGET_BASE(genDataBase, /COLUMN, /ALIGN_CENTER)
  veToolsGroup = WIDGET_BASE(veToolsBase, /ROW, /ALIGN_CENTER)
  visualizeBtn = WIDGET_BUTTON(veToolsGroup, VALUE='Visualize Results',UVALUE='Visualize', XSIZE=150)
  exportBtn = WIDGET_BUTTON(veToolsGroup, VALUE='Export to ASCII',UVALUE='ExportASCII', XSIZE=150)
  ;have to specify the event-handler manually when inside a function apparently
  XMANAGER, 'Wizard_Generate_Data', genDataBase, EVENT_HANDLER='Wizard_Generate_Data_ev'
  return, genDataBase
END