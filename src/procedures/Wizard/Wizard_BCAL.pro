
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
      Widget_Control, stash.nextBtn, Sensitive=0
      WIDGET_CONTROL, stash.currentContent, MAP=0
      WIDGET_CONTROL, stash.dataInput, MAP=1
      
      WIDGET_CONTROL, stash.intro, GET_VALUE=rootFolder
      stash.baseDir = rootFolder
      stash.currentContent = stash.dataInput
      
      WIDGET_CONTROL, ev.TOP, SET_UVALUE=stash
    END
    'DataInput': BEGIN
      IF command EQ 'Next' THEN BEGIN        
        ;we also want to grab the file name specified 
        WIDGET_CONTROL, stash.dataInput, GET_VALUE=inputFiles
        ;get and store the base directory
        ;baseDir = DirectoryFromFile(fileName)
       
        WIDGET_CONTROL, stash.procMsg, MAP=1
         Widget_Control, stash.prevBtn, Sensitive=0
         Widget_Control, stash.nextBtn, Sensitive=0
        
        processedFiles = Preprocess_Data(inputFiles, stash.baseDir)
        
        Widget_Control, stash.prevBtn, Sensitive=1
        Widget_Control, stash.nextBtn, Sensitive=1
        WIDGET_CONTROL, stash.procMsg, MAP=0
        WIDGET_CONTROL, stash.currentContent, MAP=0
        WIDGET_CONTROL, stash.heightFiltering, MAP=1
        stash.currentContent = stash.heightFiltering
        
        newStash = {nextBtn:stash.nextBtn, prevBtn:stash.prevBtn, currentContent:stash.currentContent, $
          intro:stash.intro, dataInput:stash.dataInput, dataGen:stash.dataGen, $
          processedFiles:processedFiles, heightFiltering:stash.heightFiltering, baseDir:stash.baseDir, procMsg:stash.procMsg}
        
        WIDGET_CONTROL, ev.TOP, SET_UVALUE=newStash
      ENDIF ELSE BEGIN
        ;go back to intro
         WIDGET_CONTROL, stash.currentContent, MAP=0
          WIDGET_CONTROL, stash.intro, MAP=1
        Widget_Control, stash.prevBtn, Sensitive=0
        stash.currentContent = stash.intro
      ENDELSE       
    END
    'HeightFiltering': BEGIN
      IF command EQ 'Next' THEN BEGIN 
        
        WIDGET_CONTROL, stash.heightFiltering, GET_VALUE=HeightFilterType
       
        
        stash.currentContent = stash.dataGen
        WIDGET_CONTROL, stash.procMsg, MAP=1
        Widget_Control, stash.prevBtn, Sensitive=0
        Widget_Control, stash.nextBtn, Sensitive=0
        ;Height Filter Time!
        if (HeightFilterType EQ 0) then begin
          ;call the height filtering function
          heightFilteredFiles = HeightFilter(stash.processedFiles, stash.baseDir)
        endif else if (HeightFilterType EQ 1) then begin
          ;Call logic to Prepare LAS data
          heightFilteredFiles = PrepareData(stash.processedFiles, stash.baseDir)
        endif else begin
          ;We assume that the data was processed by BCAL already and height filtered
          heightFilteredFiles = stash.processedFiles        
        endelse
        
        Widget_Control, stash.prevBtn, Sensitive=1
        Widget_Control, stash.nextBtn, Sensitive=1
        WIDGET_CONTROL, stash.procMsg, MAP=0
        WIDGET_CONTROL, stash.currentContent, MAP=0
        WIDGET_CONTROL, stash.dataGen, MAP=1
        ;Now we need to add the filtered files list to the stash
         newStash = {nextBtn:stash.nextBtn, prevBtn:stash.prevBtn, currentContent:stash.currentContent, $
          intro:stash.intro, dataInput:stash.dataInput, dataGen:stash.dataGen, $
          processedFiles:stash.processedFiles, heightFiltering:stash.heightFiltering, $
          heightFilteredFiles: heightFilteredFiles, baseDir:stash.baseDir, procMsg:stash.procMsg}
        
        WIDGET_CONTROL, ev.TOP, SET_UVALUE=newStash
        ;Change the value to done
        WIDGET_CONTROL, stash.nextBtn, SET_VALUE='Finish'
       ENDIF ELSE BEGIN
        ;go back to Data Input
         WIDGET_CONTROL, stash.currentContent, MAP=0
          WIDGET_CONTROL, stash.dataInput, MAP=1
        Widget_Control, stash.prevBtn, Sensitive=0
        stash.currentContent = stash.dataInput
      ENDELSE   
      
    END
    'GenerateData': BEGIN
      IF command EQ 'Finish' THEN BEGIN
        WIDGET_CONTROL, stash.procMsg, MAP=1
        Widget_Control, stash.prevBtn, Sensitive=0
        Widget_Control, stash.nextBtn, Sensitive=0
        GenerateRasterData, stash.heightFilteredFiles, stash.baseDir
        WIDGET_CONTROL, stash.procMsg, MAP=0
        Widget_Control, stash.prevBtn, Sensitive=1
        Widget_Control, stash.nextBtn, Sensitive=1
        done = 1        
      ENDIF ELSE BEGIN
        ;go back to the data preprocessing tab
        WIDGET_CONTROL, stash.currentContent, MAP=0
        WIDGET_CONTROL, stash.heightFiltering, MAP=1        
        stash.currentContent = stash.heightFiltering
        
        WIDGET_CONTROL, stash.nextBtn, SET_VALUE='Next'
      ENDELSE       
    END
  ENDCASE
  
  IF done EQ 1 THEN BEGIN  
    WIDGET_CONTROL, ev.Top, /DESTROY
  ENDIF ELSE BEGIN
    ;WIDGET_CONTROL, ev.TOP, SET_UVALUE=stash
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
  ;any newly created tabs must have mapping set to 0 so that they are not shown on startup
  introBase = Wizard_Intro(contentBase, UVALUE='Intro')
  dataInputBase = Wizard_Data_Input(contentBase, UVALUE='DataInput', XSIZE=500)
  dataHeightFilteringBase = Wizard_Height_Filtering(contentBase, UVALUE='HeightFiltering', XSIZE=500)
  dataGenBase = Wizard_Generate_Data(contentBase, UVALUE='GenerateData', XSIZE=500)
  
  
  buttonsBase = WIDGET_BASE(base, /COLUMN, /ALIGN_BOTTOM, /BASE_ALIGN_RIGHT, XSIZE=500, YSIZE=50)
  buttonGroup = WIDGET_BASE(buttonsBase, /ROW)
  
  
  ;create a base and text label to show that work is being done
  ;need an extra base widget here in order to map and unmap correctly
  textBase = WIDGET_BASE(buttonGroup, UVALUE='txtBase', XSIZE=85, /ALIGN_CENTER)
  processingMessage = WIDGET_LABEL(textBase, UVALUE='procMsg', value='Processing...',FONT='Arial*15',  /ALIGN_CENTER)
  
  ;Create the Next and Prev buttons
  prevBtn = WIDGET_BUTTON(buttonGroup, UVALUE='prevBtn', value='Previous', FONT='Arial*15', XSIZE=60, /ALIGN_CENTER, SENSITIVE=0)
  nextBtn = WIDGET_BUTTON(buttonGroup, UVALUE='nextBtn', value='Next', FONT='Arial*15', XSIZE=60, /ALIGN_CENTER, SENSITIVE=0)
   
  baseDir = ''
  stash = { nextBtn:nextBtn, prevBtn:prevBtn, currentContent:introBase, intro:introBase, dataInput:dataInputBase, $
    dataGen:dataGenBase, heightFiltering:dataHeightFilteringBase, procMsg:textBase, baseDir:baseDir}

  ; Realize the widgets, set the user value of the top-level
  ; base, and call XMANAGER to manage everything.
  WIDGET_CONTROL, base, /REALIZE
  ;hide the label
  
  WIDGET_CONTROL, textBase, MAP=0
  WIDGET_CONTROL, base, SET_UVALUE=stash
  XMANAGER, 'Wizard_BCAL', base, /NO_BLOCK
  

  
  
END