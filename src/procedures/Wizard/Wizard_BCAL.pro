
PRO Wizard_BCAL_event, ev
  
  WIDGET_CONTROL, ev.TOP, GET_UVALUE=stash
  currentContentBase = stash.currentContent
  WIDGET_CONTROL, currentContentBase, GET_UVALUE=contentName
  WIDGET_CONTROL, ev.ID, GET_VALUE=command
  done = 0
  
  CASE contentName OF
    'Intro': BEGIN
      ;we can only have pressed the next button, so that is what we will do
      Widget_Control, stash.prevBtn, Sensitive=1
      WIDGET_CONTROL, stash.currentContent, MAP=0
      WIDGET_CONTROL, stash.dataInput, MAP=1
      stash.currentContent = stash.dataInput
    END
    'DataInput': BEGIN
      IF command EQ 'Next' THEN BEGIN        
        WIDGET_CONTROL, stash.currentContent, MAP=0
        WIDGET_CONTROL, stash.dataGen, MAP=1
        stash.currentContent = stash.dataGen
        ;Change the value to done
         WIDGET_CONTROL, stash.nextBtn, SET_VALUE='Done'
      ENDIF ELSE BEGIN
        ;go back to intro
         WIDGET_CONTROL, stash.currentContent, MAP=0
          WIDGET_CONTROL, stash.intro, MAP=1
        Widget_Control, stash.prevBtn, Sensitive=0
        stash.currentContent = stash.intro
      ENDELSE       
    END
    'GenerateData': BEGIN
      IF command EQ 'Done' THEN BEGIN
        done = 1        
      ENDIF ELSE BEGIN
        ;go back to the data preprocessing tab
        WIDGET_CONTROL, stash.currentContent, MAP=0
        WIDGET_CONTROL, stash.dataInput, MAP=1        
        stash.currentContent = stash.dataInput
        
        WIDGET_CONTROL, stash.nextBtn, SET_VALUE='Next'
      ENDELSE       
    END
  ENDCASE
  
  IF done EQ 1 THEN BEGIN
    WIDGET_CONTROL, ev.Top, /DESTROY
  ENDIF ELSE BEGIN
    WIDGET_CONTROL, ev.TOP, SET_UVALUE=stash
  ENDELSE
END

PRO Wizard_BCAL, ev

  compile_opt hidden
  
  
  
  ; Create the top-level base 
  base = WIDGET_BASE(ROW=2, /BASE_ALIGN_TOP, TITLE='BCAL LiDAR Wizard', XSIZE=500, YSIZE=600 )
  ;Very first thing is to create a welcome screen that introduces the wizard 
  ;and what they should expect going forward.
  
  ;The current content shown
  contentBase = WIDGET_BASE(base) 
  
  ;create new tabs here
  ;any newly created tabs must have mapping set to 0so that they are not shown on startup
  introBase = Wizard_Intro(contentBase, UVALUE='Intro')
  dataInputBase = Wizard_Data_Input(contentBase, UVALUE='DataInput', XSIZE=500)
  dataGenBase = Wizard_Generate_Data(contentBase, UVALUE='GenerateData', XSIZE=500)
  
  
  buttonsBase = WIDGET_BASE(base, /COLUMN, /ALIGN_BOTTOM, /BASE_ALIGN_RIGHT, XSIZE=500, YSIZE=50)
  buttonGroup = WIDGET_BASE(buttonsBase, /ROW)
  
 
  
  
  
  
   ;Create the Next and Prev buttons
  
  prevBtn = WIDGET_BUTTON(buttonGroup, UVALUE='prevBtn', value='Previous', FONT='Arial*15', XSIZE=60, /ALIGN_CENTER, SENSITIVE=0)
  nextBtn = WIDGET_BUTTON(buttonGroup, UVALUE='nextBtn', value='Next', FONT='Arial*15', XSIZE=60, /ALIGN_CENTER)
   
  stash = { nextBtn:nextBtn, prevBtn:prevBtn, currentContent:introBase, intro:introBase, dataInput:dataInputBase, $
    dataGen:dataGenBase}

  ; Realize the widgets, set the user value of the top-level
  ; base, and call XMANAGER to manage everything.
  WIDGET_CONTROL, base, /REALIZE
  
  WIDGET_CONTROL, base, SET_UVALUE=stash
  XMANAGER, 'Wizard_BCAL', base, /NO_BLOCK
  

  
  
END