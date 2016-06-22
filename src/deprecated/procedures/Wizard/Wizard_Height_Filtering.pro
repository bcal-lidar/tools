; This file contains the ui for the height filtering
; We will include the ability to utilize a previously height filtered data set

PRO Wizard_Height_Filtering_EV, event
END

FUNCTION Wizard_Height_Filtering, parent, UVALUE=uvalue, UNAME=uname, TAB_MODE=tab_mode, XSIZE=width
  
  HeightFilterBase = WIDGET_BASE(parent, UVALUE=uvalue, /COLUMN, Map=0, /BASE_ALIGN_LEFT, $
    XSIZE=width, SPACE=20, EVENT_PRO='Wizard_Height_Filtering_EV', FUNC_GET_VALUE='GetHeightFilteringSelection')
  
  titleText = WIDGET_LABEL(HeightFilterBase, value='Height Filtering', FONT='Arial*BOLD*UNDERLINE', $
    /ALIGN_CENTER)
  
  descriptionLabel = WIDGET_TEXT( HeightFilterBase, VALUE="Now that the data has been prepared, we need to perform height" + $
    " filtering. In some cases, height fltering may have already been performed either by BCAL tools, or" + $
    " other toolsets. If you don't know, just click the 'Next' button below.", /WRAP, XSIZE=64, YSIZE=6)
    
  RadioButtonBase = WIDGET_BASE(HeightFilterBase, SCR_XSIZE=500, /Exclusive)
  
  NotFilteredBtn = WIDGET_BUTTON(RadioButtonBase, Value="Data Not Height Filtered")
  FilteredBtn = WIDGET_BUTTON(RadioButtonBase, Value="Data Height Filtered Using External Tools")
  FilteredBCALBtn = WIDGET_BUTTON(RadioButtonBase, Value="Data Height Filtered using BCAL tools")
  ;set the default state to be not filtered
  Widget_Control, NotFilteredBtn, Set_Button=1
   
  heightFilterStash = {NotFiltered:NotFilteredBtn, Filtered:FilteredBtn, FilteredBCAL:FilteredBCALBtn}
  WIDGET_CONTROL, WIDGET_INFO(HeightFilterBase, /CHILD), SET_UVALUE=heightFilterStash, /NO_COPY
 
  return, HeightFilterBase
  
END

FUNCTION GetHeightFilteringSelection, id
  ; we are going to use return values of 0, 1, and 2 for not filtered, filtered using external tools
  ; and filtered using BCAL tools respectively
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=heightFilterStash, /NO_COPY
  ;grab the buttons
  notFiltered = WIDGET_INFO(heightFilterStash.NotFiltered, /BUTTON_SET)
  Filtered = WIDGET_INFO(heightFilterStash.Filtered, /BUTTON_SET)
  FilteredBCAL = WIDGET_INFO(heightFilterStash.FilteredBCAL, /BUTTON_SET)
  
  ;WIDGET_CONTROL, heightFilterStash.Filtered, GET_VALUE=FilteredBtn
  ;WIDGET_CONTROL, heightFilterStash.FilteredBCAL, GET_VALUE=FilteredBCALBtn
  if (notFiltered EQ 1) then return, 0
  if (Filtered EQ 1) then return, 1
  if (FilteredBCAL EQ 1) then return, 2
  
  
END