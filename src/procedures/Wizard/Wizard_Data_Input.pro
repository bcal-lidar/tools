PRO WIZARD_DATA_INPUT_EV, ev
  ;get the button pressed
  WIDGET_CONTROL, ev.ID, GET_UVALUE=command
  CASE command OF
    'ASCIITool': AsciiToLAS_BCAL, ev
    'TileTool': TileLAS_BCAL, ev
    'DataInfo': Visualize3D_BCAL, ev
    'HeaderTool': FileInfoLAS_BCAL, ev
    'BoundaryTool': BoundLAS_BCAL, ev
    'BufferTool': BufferLAS_BCAL, ev
  ENDCASE
  
END

function Wizard_Data_Input, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode, XSIZE=width
  
  dataInputBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, Map=0, /BASE_ALIGN_LEFT, XSIZE=width, SPACE=20)
  titleText = WIDGET_LABEL(dataInputBase, value='Data Preprocessing', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
  
  descriptionLabel = WIDGET_LABEL(dataInputBase, value= $
      'First we will inspect and preprocess the data. ' + String(13b) $
    + '1. If your data is in ASCII format, first convert it to LAS. ' + String(13b) $
    + '2. Verify data by using the info, header, and boundary tools below. ' + String(13b) $
    + '3. If your LAS dataset is rather large (>200MB) consider tiling it.' + String(13b) $
    + '4. If your dataset consists of multiple LAS files, use the Buffer tool.' + String(13b) $
    ,/ALIGN_LEFT,YSIZE=135, FONT='Arial*16')  
    
  conversionLabel = WIDGET_LABEL(dataInputBase, value='Data Conversion', FONT='Arial*BOLD*UNDERLINE*18', $
    XSIZE=width, /ALIGN_CENTER)
    
  conversionBase = WIDGET_BASE(dataInputBase, /COLUMN, /ALIGN_CENTER)
  convertBtn = WIDGET_BUTTON(conversionBase, VALUE='Convert ASCII to LAS Tool', UVALUE='ASCIITool', XSIZE=150)
  
  optionalLabel = WIDGET_LABEL(dataInputBase, value='Optional Preprocessing', FONT='Arial*BOLD*UNDERLINE*18', $
    XSIZE=width, /ALIGN_CENTER)
  
  ;base for the three data inspection tools
  optionalBase = WIDGET_BASE(dataInputBase, /ROW, XSIZE=width)
  dataInfoBtn = WIDGET_BUTTON(optionalBase, VALUE='Visualize LAS Data', UVALUE='DataInfo', XSIZE=150)
  headerBtn = WIDGET_BUTTON(optionalBase, VALUE='View LAS Header', UVALUE='HeaderTool', XSIZE=150)
  boundaryBtn = WIDGET_BUTTON(optionalBase, VALUE='Create Vector Boundary', UVALUE='BoundaryTool', XSIZE=150)  
  
  ;tile and buffer options
  tbLabel = WIDGET_LABEL(dataInputBase, value='Tile/Buffer Data', FONT='Arial*BOLD*UNDERLINE*18', $
    XSIZE=width, /ALIGN_CENTER)
  
  
  tbBase = WIDGET_BASE(dataInputBase, /COLUMN, /ALIGN_CENTER)
  tbBtnGroup = WIDGET_BASE(tbBase, /ROW, /ALIGN_CENTER)
  tileBtn = WIDGET_BUTTON(tbBtnGroup, VALUE='Tile LAS Data', UVALUE='TileTool', XSIZE=150, YOFFSET=25)
  bufferBtn = WIDGET_BUTTON(tbBtnGroup, VALUE='Buffer LAS Dataset', UVALUE='BufferTool', XSIZE=150, YOFFSET=25)
  
  ;Height Filtering Group
  
  
  ;have to specify the event-handler manually when inside a function apparently
  XMANAGER, 'Wizard_Data_Input', dataInputBase, EVENT_HANDLER='WIZARD_DATA_INPUT_EV'
  return, dataInputBase
END