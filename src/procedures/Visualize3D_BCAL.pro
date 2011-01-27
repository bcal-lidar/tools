;+
; NAME:
;
;       Visualize3D_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to create an interactive, 3D
;       viewer for point LiDAR data as stored in the LAS format.
;
; AUTHOR:
;
;       David Streutker
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St. #240
;       Boise, ID  83702
;       http://geology.isu.edu/BCAL
;
;       Adapted from:
;
;               FSC_SURFACE
;
;               Fanning Software Consulting
;               David Fanning, Ph.D.
;               E-mail: davidf@dfanning.com
;               Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CALLING SEQUENCE:
;
;       Visualize3D_BCAL
;
; REQUIRED INPUTS:
;
;       None. LAS Data files can be opened interactively
;
; SIDE EFFECTS:
;
;       None.  (I hope.)
;
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;       InitHeaderLAS_BCAL.pro
;       InitDataLAS_BCAL.pro
;
;       This program also requires the following additional files from
;       David Fanning's Coyote Library:
;
;          normalize_BCAL.pro
;          xcolors_BCAL.pro
;
; EXAMPLE:
;
;       To use this program with your data, type:
;
;        IDL> Visualize3D_BCAL
;
;       Use your LEFT mouse button to rotate the surface plot in the window.
;       Use your RIGHT mouse button to translate the surface plot in the window.
;       Use your SCROLL wheel to zoom into and away from the plot.
;
; MODIFICATION HISTORY:
;
;       March 2006 - Written by David Streutker
;       April 2006 - Capability to open full files
;        June 2007 - Capability to open multiple files
;       April 2010 - Minor bug fixes (Rupesh Shrestha)
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;
; 3. This notice may not be removed or altered from any source distribution.
;
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;
;###########################################################################


PRO GetColor_BCAL_event, event

compile_opt idl2

    ; This is the event handler for the GetColor_BCAL routine.  Moving the sliders changes
    ; the color.  Button 0 accepts the current color.  The widget is destroyed after
    ; either button is pressed

Widget_Control, event.top, Get_UValue=state, /No_Copy

if event.id EQ state.buttonID then begin

    case event.value of
        0: begin
            widget_control, state.colorID, get_value=colorUpdate
            *state.colorPtr = colorUpdate
        end
        1: *state.colorPtr = -1
    endcase

    Widget_Control, event.top, /Destroy       ; Exit.

endif

if event.id EQ state.colorID then Widget_Control, event.top, Set_UValue=state, /No_Copy

END
;------------------------------------------------------------------------------


Pro GetColor_BCAL, colorPtr, oldColor=oldColor, group_leader=group_leader

compile_opt idl2
    ; This program opens a widget containing the CW_RGBSLIDER widget, which allows
    ; the user to select a color.

if n_elements(oldColor) ne 3 then oldColor = [0,0,0]

colorBase = Widget_Base(Title='Pick Color', /Column, group_leader=group_leader, /modal)

colorID  = cw_rgbslider(colorBase, /drag, graphics_level=2, value=oldColor)
buttonID = cw_bgroup(colorBase, ['Accept', 'Cancel'], /row, space=50)

state = {colorPtr : colorPtr,    $
         oldColor : oldColor,    $
         colorID  : colorID,     $
         buttonID : buttonID}

Widget_Control, colorBase, set_uvalue=state, /no_copy, /realize

XManager, 'GetColor_BCAL', colorBase

end
;------------------------------------------------------------------------------


PRO GetSubset_BCAL_event, event

compile_opt idl2
    ; This is the event handler for the GetSubset_BCAL routine.  Moving the slider changes
    ; the number of subset points.  Button 0 accepts the current number.  The widget is
    ; destroyed after either button is pressed

Widget_Control, event.top, Get_UValue=state, /No_Copy

if event.id EQ state.buttonID then begin

    case event.value of
        0: begin
            widget_control, state.sliderID, get_value=subsetUpdate
            *state.newSubset = subsetUpdate
        end
        1: *state.newSubset = state.oldSubset
    endcase

    Widget_Control, event.top, /Destroy       ; Exit.

endif

if event.id EQ state.sliderID then Widget_Control, event.top, Set_UValue=state, /No_Copy

END
;------------------------------------------------------------------------------


Pro GetSubset_BCAL, newSubset, oldSubset=oldSubset, maxSubset=maxSubset, group_leader=group_leader

compile_opt idl2
    ; This program opens a widget containing the CW_FSLIDER widget, which allows
    ; the user to select a value for the subset number.

subsetBase = Widget_Base(Title='Pick A Subset Value', /Column, group_leader=group_leader, /modal)

sliderID = cw_fslider(subsetBase, /double, /drag, /edit, format='(I)', maximum=maxSubset, value=oldSubset, xsize=150)
buttonID = cw_bgroup(subsetBase, ['Accept', 'Cancel'], /row, space=50)

state = {newSubset : newSubset, $
         oldSubset : oldSubset, $
         sliderID  : sliderID,  $
         buttonID  : buttonID}

Widget_Control, subsetBase, set_uvalue=state, /no_copy, /realize

XManager, 'GetSubset_BCAL', subsetBase

end
;------------------------------------------------------------------------------


PRO Data_Open_BCAL, event

compile_opt idl2
    ; Establish error handler.  The most likely problem is that the user will open a data
    ; file that is too large to process.

catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    Widget_Control, event.top, Set_UValue=info, /No_Copy
    return
endif

    ; This procedure opens and reads an LAS data file and creates a data object to display.
    ; It also performs the necessary scaling to retain the proper perspective.

Widget_Control, event.top, Get_UValue=info, /No_Copy

    ; Get the file

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', $
              /fix_filter, /must_exist, /multiple, Get_Path = CurrentDirectory, $
              path = info.LastDirectory)

info.LastDirectory = CurrentDirectory

if (inputFiles[0] ne '') then begin

    nFiles = n_elements(inputFiles)
    ReadLAS_BCAL, inputFiles[0], header, /nodata

    filesStr = replicate({name : inputFiles[0], nPoints:header.nPoints}, nFiles)

        ; Zero the previous data

   *info.dataPtr  = 0B

        ; Read the data headers to get the geographical extents

    if nFiles gt 1 then begin

        for a=1,nFiles-1 do begin

            ReadLAS_bcal, inputFiles[a], inputHeader, /nodata

            header.nPoints += inputHeader.nPoints

            header.xMin <= inputHeader.xMin
            header.xMax >= inputHeader.xMax
            header.yMin <= inputHeader.yMin
            header.yMax >= inputHeader.yMax
            header.zMin <= inputHeader.zMin
            header.zMax >= inputHeader.zMax

            filesStr[a].name    = inputFiles[a]
            filesStr[a].nPoints = inputHeader.nPoints

        endfor

    endif

    info.header   = header
   *info.filesPtr = filesStr

       ; Calculate the data range in all three dimensions.  I want the surface data to have
       ; the same aspect ratio as the data itself in the X, Y, and Z directions.

    xRange = [header.xMin, header.xMax]
    yRange = [header.yMin, header.yMax]
    zRange = [header.zMin, header.zMax]

    maxRange = (xRange[1] - xRange[0]) > (yRange[1] - yRange[0]) > (zRange[1] - zRange[0])

       ; Calculate normalized positions in window, scale to the maximum data range.  Make sure
       ; the data range is symmetric about (0,0,0) and all scaled uniformly to preserve perspective

    xStart = 0.5 - 0.5 * (xRange[1] - xRange[0]) / maxRange
    xEnd   = 0.5 + 0.5 * (xRange[1] - xRange[0]) / maxRange
    yStart = 0.5 - 0.5 * (yRange[1] - yRange[0]) / maxRange
    yEnd   = 0.5 + 0.5 * (yRange[1] - yRange[0]) / maxRange
    zStart = 0.5 - 0.5 * (zRange[1] - zRange[0]) / maxRange
    zEnd   = 0.5 + 0.5 * (zRange[1] - zRange[0]) / maxRange

    pos = [xStart, xEnd, yStart, yEnd, zStart, zEnd] - 0.5

    info.xAxis->SetProperty, Range=xRange
    info.yAxis->SetProperty, Range=yRange
    info.zAxis->SetProperty, Range=zRange

        ; Set scaling parameters for the surface and axes so that everything is scaled into the
        ; range -0.5 to 0.5. We do this so that when the surface is rotated we don't have to
        ; worry about translations. In other words, the rotations occur about the point (0,0,0).

    xs = normalize_BCAL(xRange, Position=[pos[0], pos[1]])
    ys = normalize_BCAL(yRange, Position=[pos[2], pos[3]])
    zs = normalize_BCAL(zRange, Position=[pos[4], pos[5]])

        ; Scale the axes and place them in the coordinate space. Note that not all values
        ; in the Location keyword are used. (I've put really large values into the positions
        ; that are not being used to demonstate this.) For example, with the X axis only
        ; the Y and Z locations are used.

    info.xAxis->SetProperty, Location=[9999.0, pos[2], pos[4]], XCoord_Conv=xs
    info.yAxis->SetProperty, Location=[pos[0], 9999.0, pos[4]], YCoord_Conv=ys
    info.zAxis->SetProperty, Location=[pos[0], pos[3], 9999.0], ZCoord_Conv=zs

        ; Initialize and scale the point data, subsetting to a default maximum number of points.

    Data_Initialize_BCAL, info, 5e4

    info.poly->SetProperty, XCoord_Conv=xs, YCoord_Conv=ys, ZCoord_Conv=zs

        ; Place and direct the light objects

    info.rotatingLight->SetProperty, Location  = [xRange[1], yRange[1], 4*zRange[1]], $
                                     Direction = [xRange[0], yRange[0],   zRange[0]]

    info.fillLight->SetProperty, Location  = [(xRange[1]-xRange[0])/2.0, (yRange[1]-yRange[0])/2.0, -2*Abs(zRange[0])], $
                                 Direction = [(xRange[1]-xRange[0])/2.0, (yRange[1]-yRange[0])/2.0,        zRange[1]]

    info.staticLight->SetProperty, Location  = [-xRange[1], (yRange[1]-yRange[0])/2.0, 4*zRange[1]], $
                                   Direction = [ xRange[1], (yRange[1]-yRange[0])/2.0,   zRange[0]]

        ; Scale the light sources.

    info.rotatingLight->SetProperty, XCoord_Conv=xs, YCoord_Conv=ys, ZCoord_Conv=zs
    info.fillLight->SetProperty,     XCoord_Conv=xs, YCoord_Conv=ys, ZCoord_Conv=zs
    info.staticLight->SetProperty,   XCoord_Conv=xs, YCoord_Conv=ys, ZCoord_Conv=zs

        ; Rename the widget window

;    widget_control, info.tlb, base_set_title='LiDAR Data Viewer' + inputFile

endif

    ;Draw the display

info.thisWindow->Draw, info.thisView
Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;------------------------------------------------------------------------------


PRO Data_Initialize_BCAL, info, subset

compile_opt idl2
    ; This procedure initialzes the data object to requested parameters.

    ; Create the subset indices of the requested size

seed   = systime(1) mod 100
subset = subset < info.header.nPoints
nTemp  = round(((*info.filesPtr).nPoints / total((*info.filesPtr).nPoints, /double)) * subset)
if n_elements(*info.filesPtr) gt 1 then nTemp[0] = subset - total(nTemp[1:*])

dataStr = InitDataLAS_BCAL(pointFormat=info.header.pointFormat)
data = replicate(dataStr, subset)

    ; Read the data from each of the files

widget_control, /hourglass
for a=0,n_elements(*info.filesPtr)-1 do begin

    assocLun = 1
    ReadLAS_bcal, (*info.filesPtr)[a].name, inputHeader, assocData, assocLun=assocLun

    index = randomu(seed,nTemp[a]) * ((*info.filesPtr)[a].nPoints - 1)
    index = index[sort(index)]

    dStart = total(nTemp[0:a], /int) - nTemp[a]

    for b=0L,nTemp[a]-1 do data[dStart+b] = assocData[index[b]]

    free_lun, assocLun

endfor

*info.dataPtr = data

    ; Create polygons from the points data and the data index, and assign them to thisPointData,
    ; a polygon object created when the program was initialized.

widget_control, /hourglass
mesh_obj, 0, vert, poly, $
        transpose([[(*info.dataPtr).east  * info.header.xScale + info.header.xOffset], $
                   [(*info.dataPtr).north * info.header.yScale + info.header.yOffset], $
                   [(*info.dataPtr).elev  * info.header.zScale + info.header.zOffset]])

info.poly->SetProperty, data=vert, polygons=poly

    ; Update the surface

Viz_Surface_BCAL_Update, info

    ; Set value of subset button

widget_control, info.buttons.bSubset, $
    set_value=strcompress(n_elements(*info.dataPtr), /remove_all) + ' Points'

END
;------------------------------------------------------------------------------


PRO Viz_Surface_BCAL_Elevation_Colors, event

compile_opt idl2

    ; This event handler changes color tables for elevation shading.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; What kind of event is this?

thisEvent = Tag_Names(event, /Structure_Name)

CASE thisEvent OF

   "WIDGET_BUTTON": BEGIN
      TVLCT, info.r, info.g, info.b
      xcolors_BCAL, Group_Leader=event.top, NotifyID=[event.id, event.top], Title="Shading Colors"
      END

   "XCOLORS_LOAD": BEGIN
      info.r = event.r
      info.g = event.g
      info.b = event.b
      info.colortable = event.index
      IF Obj_Valid(info.thisPalette) THEN info.thisPalette->SetProperty, Red=event.r, Green=event.g, Blue=event.b
      END

ENDCASE

   ; Draw the graphic display.

info.thisWindow->Draw, info.thisView
Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;------------------------------------------------------------------------------


PRO Viz_Surface_BCAL_Shading, event

compile_opt idl2

    ; This event handler sets up elevation shading for the surface.

Widget_Control, event.top, Get_UValue=info, /No_Copy
Widget_Control, event.id,  Get_Value=buttonValue, Get_UValue=uvalue
Widget_Control, event.id,  Set_Value=uvalue, Set_UValue=buttonValue

CASE buttonValue OF

   'Surface Shading ON': BEGIN

        ; Make sure lights are turned off.

      info.staticLight->SetProperty,   Hide=1
      info.rotatingLight->SetProperty, Hide=1
      info.fillLight->SetProperty,     Hide=1
      info.ambientLight->SetProperty,  Hide=1
      END

   'Surface Shading OFF': BEGIN

        ; Make sure lights are turned on.

      info.staticLight->SetProperty,   Hide=0
      info.rotatingLight->SetProperty, Hide=0
      info.fillLight->SetProperty,     Hide=0
      info.ambientLight->SetProperty,  Hide=0
      END

ENDCASE

   ; Draw the graphic display.

info.thisWindow->Draw, info.thisView
Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;------------------------------------------------------------------------------


PRO Viz_Labels_BCAL, event

compile_opt idl2

; This event handler turns the axes on and off.

Widget_Control, event.top, Get_UValue=info, /No_Copy
Widget_Control, event.id,  Get_Value=buttonValue, Get_UValue=uvalue
Widget_Control, event.id,  Set_Value=uvalue, Set_UValue=buttonValue

CASE buttonValue OF

   'Axes ON' : BEGIN
      info.xAxis->SetProperty, Hide=1
      info.yAxis->SetProperty, Hide=1
      info.zAxis->SetProperty, Hide=1
      END

   'Axes OFF' : BEGIN
      info.xAxis->SetProperty, Hide=0
      info.yAxis->SetProperty, Hide=0
      info.zAxis->SetProperty, Hide=0
      END

    'Colorbar ON'  : info.thisColorbar->SetProperty, Hide=1
    'Colorbar OFF' : info.thisColorbar->SetProperty, Hide=0

ENDCASE

   ; Draw the graphic display.

info.thisWindow->Draw, info.thisView
Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;------------------------------------------------------------------------------


PRO Viz_Draw_BCAL_Events, event

compile_opt idl2

     ; Draw widget events handled here: expose events and trackball events. The trackball
     ; uses RSI-supplied TRACKBALL_DEFINE.PRO from the IDL50/examples/object directory.

Widget_Control, event.top, Get_UValue=info, /No_Copy

drawTypes = ['PRESS', 'RELEASE', 'MOTION', 'SCROLLBAR', 'EXPOSE', 'KEY', 'SKEY', 'WHEEL' ]
thisEvent = drawTypes[event.type]

info.thisModel->GetProperty, Transform=modelTransform

CASE thisEvent OF

    'EXPOSE':  ; Nothing required except to draw the view.

    'PRESS': begin
             Widget_Control, event.id, Draw_Motion_Events=1         ; Motion events ON.
             info.thisWindow->SetProperty, Quality=info.dragQuality ; Set Drag Quality.
             end

    'RELEASE': begin
               Widget_Control, event.id, Draw_Motion_Events=0 ; Motion events OFF.
               info.thisWindow->SetProperty, Quality=2        ; Drag Quality to High.
               end

    'MOTION': begin ; Trackball events
              end

        ;Zoom on mouse wheel event

    'WHEEL': begin

             transform = fltarr(3) + 1.0 - 0.02 * event.clicks
             transform = diag_matrix([transform,1])

             info.thisModel->SetProperty, Transform=modelTransform # transform

             end

   ELSE:

ENDCASE

   ; Does the trackball need updating? If so, update.  If the left button was used,
   ; rotate the model.  If the right button was used, translate the model.

leftUpdate  = info.leftTrackball->Update(event, Transform=transform, Mouse=1)
rightUpdate = info.rightTrackball->Update(event, Transform=transform, Mouse=4, Translate=1)

if rightUpdate or leftUpdate then info.thisModel->SetProperty, Transform=modelTransform # transform

    ; Draw the view.

info.thisWindow->Draw, info.thisView

    ;Put the info structure back.

Widget_Control, event.top, Set_UValue=info, /No_Copy

END
;-------------------------------------------------------------------


PRO Viz_Surface_BCAL_Event, event

compile_opt idl2

     ; Event handler to select changes to the data object.

Widget_Control, event.top, Get_UValue=info, /No_Copy

    ; What change is wanted?

Widget_Control, event.id, Get_UValue=newChange
CASE newChange OF

        ; Change the representation of the point data

    'DOTS':  begin
        info.poly->SetProperty, Style=0
        widget_control, info.buttons.bDots,  set_button=1
        widget_control, info.buttons.bWire,  set_button=0
        widget_control, info.buttons.bSolid, set_button=0
        end
    'MESH':  begin
        info.poly->SetProperty, Style=1
        widget_control, info.buttons.bDots,  set_button=0
        widget_control, info.buttons.bWire,  set_button=1
        widget_control, info.buttons.bSolid, set_button=0
        end
    'SOLID': begin
        info.poly->SetProperty, Style=2
        widget_control, info.buttons.bDots,  set_button=0
        widget_control, info.buttons.bWire,  set_button=0
        widget_control, info.buttons.bSolid, set_button=1
        end

        ; Change the Drag Qualtiy

    'DRAG_LOW':    begin
        info.dragQuality = 0
        widget_control, info.buttons.bDragL, set_button=1
        widget_control, info.buttons.bDragM, set_button=0
        widget_control, info.buttons.bDragH, set_button=0
        end
    'DRAG_MEDIUM': begin
        info.dragQuality = 1
        widget_control, info.buttons.bDragL, set_button=0
        widget_control, info.buttons.bDragM, set_button=1
        widget_control, info.buttons.bDragH, set_button=0
        end
    'DRAG_HIGH':   begin
        info.dragQuality = 2
        widget_control, info.buttons.bDragL, set_button=0
        widget_control, info.buttons.bDragM, set_button=0
        widget_control, info.buttons.bDragH, set_button=1
        end

        ; Change the data coloring (constant, by elevation, or by intensity) and update
        ; the button checklist

    'SINGLE':  begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.single, set_button=1
        Viz_Surface_BCAL_Update, info
        end
    'RAMPED':  begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.elev, set_button=1
        Viz_Surface_BCAL_Update, info
        end
    'INTEN':  begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.inten, set_button=1
        Viz_Surface_BCAL_Update, info
        end
    'HEIGHT': begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.height, set_button=1
        Viz_Surface_BCAL_Update, info
        end
    'CLASS': begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.class, set_button=1
        Viz_Surface_BCAL_Update, info
        end
    'RETURN' : begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.nReturn, set_button=1
        Viz_Surface_BCAL_Update, info
        END
    'ANGLE' : begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.angle, set_button=1
        Viz_Surface_BCAL_Update, info
        END
    'IMAGE' : begin
        for i=0,n_tags(info.buttons.source)-1 do widget_control, info.buttons.source.(i), set_button=0
        widget_control, info.buttons.source.image, set_button=1
        Viz_Surface_BCAL_Update, info
        END

        ; Save a screenshot

    'CAPTURE': begin

           ; Get a snapshop of window contents. (TVRD equivalent.)  Wait for just a moment to allow the
           ; pull-down menu button to disappear. Otherwise, we will get extraneous text in our output image.

        Widget_Control, /Hourglass
        Wait, 0.5
        info.thisWindow->GetProperty, Image_Data=snapshot
        dummy = dialog_write_image(snapshot, file='image.tif')
        end

        ; Subset the data

    'SUBSET': begin

            ; Determine the subset values

        newSubset = ptr_new(/allocate_heap, /no_copy)
        oldSubset = n_elements(*info.dataPtr)

            ; Get the subset value.  If it has changed, update the data, then destroy the pointer

        GetSubset_BCAL, newSubset, oldSubset=oldSubset, maxSubset=info.header.nPoints, group_leader=event.top
        if *newSubset ne oldSubset then Data_Initialize_BCAL, info, *newSubset
        ptr_free, newSubset
        end

ENDCASE

    ; Redraw the graphic.

info.thisWindow->Draw, info.thisView

    ;Put the info structure back.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;-------------------------------------------------------------------


PRO Viz_Surface_BCAL_Update, info

compile_opt idl2

info.thisColorbar->GetProperty, Title=oTitle
info.thisColorbar->GetProperty, TickText=oTickText

if (widget_info(info.buttons.source.single, /button_set)) then begin
    info.poly->SetProperty, vert_colors=0
    info.thisColorbar->SetProperty, Hide=1
endif

if (widget_info(info.buttons.source.elev, /button_set)) then begin
    info.poly->SetProperty, vert_colors=bytscl((*info.dataPtr).elev, /nan)
    info.thisColorbar->SetProperty, Hide=0
    oTitle->SetProperty, Strings='Elevation'
    oTickText->SetProperty, Strings=strcompress(round([info.header.zMin,info.header.zMax]),/remove)
endif

if (widget_info(info.buttons.source.inten, /button_set)) then begin
    info.poly->SetProperty, vert_colors=hist_equal((*info.dataPtr).inten, omin=oMin, omax=oMax)
    info.thisColorbar->SetProperty, Hide=0
    oTitle->SetProperty, Strings='Intensity'
    oTickText->SetProperty, Strings=strcompress([oMin,oMax],/remove)
endif

if (widget_info(info.buttons.source.height, /button_set)) then begin
    good = where((*info.dataPtr).source ne 65535)
    maxVeg = max((*info.dataPtr)[good].source)
    info.poly->SetProperty, vert_colors=bytscl((*info.dataPtr).source, min=0, max=maxVeg)
    info.thisColorbar->SetProperty, Hide=0
    oTitle->SetProperty, Strings='Vegetation Height'
    oTickText->SetProperty, Strings=strcompress(string([0,maxVeg*info.header.zScale],format='(f8.2)'),/remove)
endif

if (widget_info(info.buttons.source.class, /button_set)) then begin
    info.poly->SetProperty, vert_colors=hist_equal((*info.dataPtr).user, omin=oMin, omax=oMax)
    info.thisColorbar->SetProperty, Hide=0
    oTitle->SetProperty, Strings='Classification Value'
    oTickText->SetProperty, Strings=strcompress([oMin,oMax],/remove)
endif

if (widget_info(info.buttons.source.nReturn, /button_set)) then begin
    info.poly->SetProperty, vert_colors=hist_equal((*info.dataPtr).nReturn mod 8, omin=oMin, omax=oMax)
    info.thisColorbar->SetProperty, Hide=0
    oTitle->SetProperty, Strings='Return Number'
    oTickText->SetProperty, Strings=strcompress([oMin,oMax],/remove)
endif

if (widget_info(info.buttons.source.angle, /button_set)) then begin
    info.poly->SetProperty, vert_colors=bytscl((*info.dataPtr).angle-128B)
    info.thisColorbar->SetProperty, Hide=0
    oTitle->SetProperty, Strings='Scan Angle'
    oTickText->SetProperty, Strings=strcompress([min((*info.dataPtr).angle-128B,max=maxAngle), maxAngle]-128,/remove)
endif

if (widget_info(info.buttons.source.image, /button_set)) then begin
    envi_select, fid=imgID, pos=imgPos, /no_dims
    if n_elements(imgPos) eq 1 or n_elements(imgPos) eq 3 then begin
        envi_convert_file_coordinates, imgID, xImage, yImage, $
            (*info.dataPtr).east  * info.header.xScale + info.header.xOffset, $
            (*info.dataPtr).north * info.header.yScale + info.header.yOffset
        envi_file_query, imgID, ns=ns, nl=nl
        imgRoi = envi_create_roi(ns=ns, nl=nl, /no_update)
        envi_define_roi, imgRoi, /no_update, /point, xpts=xImage, ypts=yImage

        if n_elements(imgPos) eq 1 then begin
            info.thisColorbar->SetProperty, Hide=0
            oTitle->SetProperty, Strings='Band' + strcompress(imgPos+1) + ' Value'
            oTickText->SetProperty, Strings=strcompress([0,255],/remove)
            imgColors = envi_get_roi_data(imgRoi, fid=imgID, pos=imgPos)
        endif else begin
            info.thisColorbar->SetProperty, Hide=1
            imgColors = bytarr(3,n_elements(*info.dataPtr))
            for j=0,2 do imgColors[j,*] = envi_get_roi_data(imgRoi, fid=imgID, pos=imgPos[j])
        endelse

        info.poly->SetProperty, vert_colors=imgColors
    endif else dummy = dialog_message('Please select one or three bands', /error)
endif

end
;-------------------------------------------------------------------


PRO Viz_Surface_BCAL_Properties, event

compile_opt idl2

     ; Event handler to set change the color setting of various objects.

Widget_Control, event.top, Get_UValue=info, /No_Copy
Widget_Control, event.id,  Get_UValue=newProperty

newColor = ptr_new(/allocate_heap, /no_copy)

CASE newProperty OF

        ; Change the color property of the data

   'SURFACE_COLOR': BEGIN
        info.poly->GetProperty, color=oldColor
        GetColor_BCAL, newColor, oldColor=oldColor, group_leader=event.top
        if ((*newColor)[0] ne -1) then info.poly->SetProperty, Color=*newColor
    END

        ; Change the color of the axes

    'LABEL_COLOR': begin
        info.xAxis->GetProperty, color=oldColor
        GetColor_BCAL, newColor, oldColor=oldColor, group_leader=event.top
        if ((*newColor)[0] ne -1) then begin
            info.xAxis->SetProperty, Color=*newColor
            info.yAxis->SetProperty, Color=*newColor
            info.zAxis->SetProperty, Color=*newColor
            info.thisColorbar->SetProperty, Color=*newColor
        endif
    end

        ; Change the color of the view background

    'BACKGROUND_COLOR': begin
        info.thisView->GetProperty, color=oldColor
        GetColor_BCAL, newColor, oldColor=oldColor, group_leader=event.top
        if ((*newColor)[0] ne -1) then info.thisView->SetProperty, Color=*newColor
    end

ENDCASE

    ; Redraw the graphic.

info.thisWindow->Draw, info.thisView

    ; Destroy the color pointer

ptr_free, newColor

    ;Put the info structure back.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;-------------------------------------------------------------------


PRO Viz_Resize_BCAL, event

compile_opt idl2

     ; Event handler for resizing the widget

Widget_Control, event.top, Get_UValue=info, /No_Copy
maxDim = event.x > event.y

    ; Resize the draw widget, preserving the aspect ratio.  This keeps the view from
    ; getting scaled unevenly in various dimensions

info.thisWindow->GetProperty, Dimension=wDim
info.thisWindow->SetProperty, Dimension=[event.x, event.y]

rScale = [event.x, event.y] / wDim

info.thisView->GetProperty, ViewPlane_Rect=vRect
info.thisView->SetProperty, ViewPlane_Rect=vRect*[rScale,rScale]

    ; Reposition the colorbar with respect to the lower right corner

xPos = vRect[0] * rScale[0] + info.colorbarLocation.x
yPos = vRect[1] * rScale[1] + info.colorbarLocation.y

info.thisColorbar->SetProperty, XCoord_Conv=normalize_BCAL([0,255], Position=xPos)
info.thisColorbar->SetProperty, YCoord_Conv=normalize_BCAL([0,14],  Position=yPos)

    ; Redisplay the graphic.

info.thisWindow->Draw, info.thisView

    ; Update the trackball objects' locations in the center of the window.

info.leftTrackball->Reset,  [event.x, event.y], maxDim
info.rightTrackball->Reset, [event.x, event.y], maxDim

    ; Put the info structure back.

Widget_Control, event.top, Set_UValue=info, /No_Copy
END
;-------------------------------------------------------------------


Pro Viz_Surface_BCAL_Cleanup, tlb

compile_opt idl2

    ; Come here when program dies. Free all created objects and pointers.

Widget_Control, tlb, Get_UValue=info
IF N_Elements(info) NE 0 THEN Obj_Destroy, info.thisContainer
ptr_free, info.filesPtr, info.dataPtr
loadct, 0, /silent

END
;-------------------------------------------------------------------


PRO Viz_Surface_BCAL_Exit, event

compile_opt idl2

   ; Exit the program. This will cause the CLEANUP routine to be called automatically.

Widget_Control, event.top, /Destroy
END
;------------------------------------------------------------------------

pro Viz_Surface_BCAL_Help, event  
 
; Error Handler
Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   Help, /last_message, output=errText
   errMsg = dialog_message(errText, /error, title='Error displaying help')
   return
ENDIF

compile_opt idl2  

  myapp_help_path = ENVI_GET_PATH() + PATH_SEP() + 'save_add' + PATH_SEP() + 'help'  
  !HELP_PATH = !HELP_PATH + PATH_SEP(/SEARCH_PATH) + myapp_help_path  
  ONLINE_HELP, 'viewer', BOOK="help.adp" 
   
end


pro Visualize3D_BCAL, event

compile_opt idl2

    ; Set the initial colortable

colortable = 34
tvlct, r, g, b, /Get

    ; Create a view. Use RGB color. Black background. The coodinate system is
    ; chosen so that (0,0,0) is in the center of the window. This will make rotations
    ; easier.  Give the viewplane a 4:3 aspect ratio.

thisRect = [-1.00, -0.75, 2.00, 1.50]
thisView = Obj_New('IDLgrView', Color=[0,0,0], Viewplane_Rect=thisRect)
thisView->SetProperty, ZClip=[10,-10], Eye=11

    ; Create a model for the data and axes and add it to the view.
    ; This model will rotate under the direction of the trackball objects.

thisModel = Obj_New('IDLgrModel')
thisView->Add, thisModel

    ; Create helper objects. First, create title objects for the axes and plot.
    ; Color them white.  Set the keyword Recompute_Dimensions=2 so they will adjust
    ; when the data range is changed

xTitle = Obj_New('IDLgrText', 'Easting (m)',   Color=[255,255,255], recompute_dimensions=2)
yTitle = Obj_New('IDLgrText', 'Northing (m)',  Color=[255,255,255], recompute_dimensions=2)
zTitle = Obj_New('IDLgrText', 'Elevation (m)', Color=[255,255,255], recompute_dimensions=2)

    ; Create font objects.

helvetica10pt = Obj_New('IDLgrFont', 'Helvetica', Size=10)
helvetica14pt = Obj_New('IDLgrFont', 'Helvetica', Size=14)

    ; Create two trackball objects, one for rotations (left button) and one for translations
    ; (right button). Center them in the 800-by-600 window. Give them a 400 pixel diameter.

leftTrackball  = Obj_New('Trackball', [400, 300], 400)
rightTrackball = Obj_New('Trackball', [400, 300], 400)

    ; Create a palette for the surface.

thisPalette = Obj_New('IDLgrPalette')
thisPalette->LoadCT, colortable
thisPalette->GetProperty, Red=r, Green=g, Blue=b

    ; Create a colorbar

thisColorbar = Obj_New('IDLgrColorbar', major=2, minor=3)
thisColorbar->SetProperty, Dimensions=[256,16], Palette=thisPalette
thisColorbar->SetProperty, Show_Axis=2, Show_Outline=1, Color=[255,255,255], hide=1

colorbarLocation = { x : [0.05, 0.50], y : [0.13, 0.18] }

thisColorbar->SetProperty, XCoord_Conv=normalize_BCAL([0,255], Position=[thisRect[0] + colorbarLocation.x])
thisColorbar->SetProperty, YCoord_Conv=normalize_BCAL([0,15],  Position=[thisRect[1] + colorbarLocation.y])
thisColorbar->SetProperty, Title=Obj_New('IDLgrText')

colorbarModel = Obj_New('IDLgrModel')
colorbarModel->Add, thisColorbar

thisView->Add, colorbarModel

    ; Create the point data objects and pointers to the data, data index, and file.  Intialize a
    ; data header. Create objects and indices for both first and last pulses

poly = Obj_New('IDLgrPolygon', color=[100,100,100], palette=thisPalette, style=0)
poly->SetProperty, Thick=2

filesPtr = ptr_new(/allocate_heap, /no_copy)
dataPtr  = ptr_new(/allocate_heap, /no_copy)
header   = InitHeaderLAS_BCAL()

    ; Create axes objects for the surface. Color them white. Hide them. Axes are created after the
    ; surface so the range can be set correctly. Note how the font is set to 10 pt helvetica.

xAxis = Obj_New('IDLgrAxis', 0, Color=[255,255,255], Ticklen=0.05, Title=xtitle, /Exact, Hide=1, Tickformat='(I)')
xAxis->GetProperty, Ticktext=xAxisText
xAxisText->SetProperty, Font=helvetica10pt, recompute_dimensions=2

yAxis = Obj_New('IDLgrAxis', 1, Color=[255,255,255], Ticklen=0.05, Title=ytitle, /Exact, Hide=1, Tickformat='(I)')
yAxis->GetProperty, Ticktext=yAxisText
yAxisText->SetProperty, Font=helvetica10pt, recompute_dimensions=2

zAxis = Obj_New('IDLgrAxis', 2, Color=[255,255,255], Ticklen=0.05, Title=ztitle, /Exact, Hide=1)
zAxis->GetProperty, Ticktext=zAxisText
zAxisText->SetProperty, Font=helvetica10pt, recompute_dimensions=2

    ; Add the data and axes objects to the model.

thisModel->Add, poly
thisModel->Add, xAxis
thisModel->Add, yAxis
thisModel->Add, zAxis

    ; Rotate the data model to the standard surface view.

thisModel->Rotate,[1,0,0], -90  ; To get the Z-axis vertical.
thisModel->Rotate,[0,1,0],  30  ; Rotate it slightly to the right.
thisModel->Rotate,[1,0,0],  30  ; Rotate it down slightly.

    ; Create some lights to view the surface. Surfaces will look best if there is some ambient
    ; lighting to illuminate them uniformly, and some positional lights to give the surface
    ; definition. We will create three positional lights: one, non-rotating light will provide
    ; overhead definition. Two rotating lights will provide specific surface definition.
    ; Lights should be turned off or hidden if surface shading is in effect.

    ; First create the ambient light. Don't turn it on too much,
    ; or the surface will appear washed out.

ambientLight = Obj_New('IDLgrLight', Type=0, Intensity=0.2, Hide=0)
thisModel->Add, ambientLight

    ; Shaded surfaces will not look shaded unless there is a positional light source to give
    ; the surface edges definition. This light will rotate with the surface.

rotatingLight = Obj_New('IDLgrLight', Type=1, Intensity=0.60, Hide=0)
thisModel->Add, rotatingLight

    ; Create a fill light source so you can see the underside of the surface. Otherwise,
    ; just the top surface will be visible. This light will also rotate with the surface.

fillLight = Obj_New('IDLgrLight', Type=1, Intensity=0.4, Hide=0)
thisModel->Add, fillLight

    ; Create a non-rotating overhead side light.

staticLight = Obj_New('IDLgrLight', Type=1, Intensity=0.8, Hide=0)
staticModel = Obj_New('IDLgrModel')
staticModel->Add, staticLight

    ; Be sure to add the non-rotating model to the view, or it won't be visualized.

thisView->Add, staticModel

    ; Rotate the non-rotating model to the standard surface view.

staticModel->Rotate,[1,0,0], -90  ; To get the Z-axis vertical.
staticModel->Rotate,[0,1,0],  30  ; Rotate it slightly to the right.
staticModel->Rotate,[1,0,0],  30  ; Rotate it down slightly.

    ; Create the widgets to view the surface. Set expose events
    ; on the draw widget so that it refreshes itself whenever necessary.
    ; Button and wheel events are on to enable trackball movement.

tlb    = Widget_Base(Title='LiDAR Data Viewer', Column=1, TLB_Size_Events=1, MBar=menuBase)
drawID = Widget_Draw(tlb, XSize=800, YSize=600, Graphics_Level=2, Retain=1, Renderer=1, $
                     /Expose_Events, /Button_Events, /Wheel_Events, Event_Pro='Viz_Draw_BCAL_Events')

    ; Create FILE menu buttons for opening files and exiting.

fileMenu = Widget_Button(menuBase, Value='File', /Menu)

dummy = Widget_button(fileMenu, Value='Open LAS File(s)', Event_Pro='Data_Open_BCAL')
dummy = Widget_button(fileMenu, Value='Save Screenshot', Event_Pro='Viz_Surface_BCAL_Event', UValue='CAPTURE', /separator)
dummy = Widget_Button(fileMenu, Value='Exit', Event_Pro='Viz_Surface_BCAL_Exit', /separator)

    ; Create STYLE menu buttons for surface style.

styleMenu = Widget_Button(menuBase, Value='Style', /Menu)

    ; Surface Type

surfMenu = Widget_Button(styleMenu, Value='Surface Type', /Menu)

bDots  = Widget_Button(surfMenu, Value='Dot Surface', Event_Pro='Viz_Surface_BCAL_Event', UValue='DOTS', /checked)
bWire  = Widget_Button(surfMenu, Value='Wire Mesh',   Event_Pro='Viz_Surface_BCAL_Event', UValue='MESH', /checked)
bSolid = Widget_Button(surfMenu, Value='Solid',       Event_Pro='Viz_Surface_BCAL_Event', UValue='SOLID', /checked)

colorMenu = Widget_Button(styleMenu, Value='Surface Color Type', /Menu, /Separator)

bSingle = Widget_Button(colorMenu, Value='Single Color',     Event_Pro='Viz_Surface_BCAL_Event', UValue='SINGLE', /checked)
bElev   = Widget_Button(colorMenu, Value='Elevation Range',  Event_Pro='Viz_Surface_BCAL_Event', UValue='RAMPED', /checked)
bInten  = Widget_Button(colorMenu, Value='Intensity Range',  Event_Pro='Viz_Surface_BCAL_Event', UValue='INTEN',  /checked)
bHeight = Widget_Button(colorMenu, Value='Vegetation Range', Event_Pro='Viz_Surface_BCAL_Event', UValue='HEIGHT', /checked)
bClass  = Widget_Button(colorMenu, Value='Classification',   Event_Pro='Viz_Surface_BCAL_Event', UValue='CLASS',  /checked)
bReturn = Widget_Button(colorMenu, Value='Return Number',    Event_Pro='Viz_Surface_BCAL_Event', UValue='RETURN', /checked)
bAngle  = Widget_Button(colorMenu, Value='Scan Angle',       Event_Pro='Viz_Surface_BCAL_Event', UValue='ANGLE',  /checked)
bImage  = Widget_Button(colorMenu, Value='From Image',       Event_Pro='Viz_Surface_BCAL_Event', UValue='IMAGE',  /checked)

dummy = Widget_Button(styleMenu, Value='Set Surface Color Table', Event_Pro='Viz_Surface_BCAL_Elevation_Colors')
dummy = Widget_Button(styleMenu, Value='Set Surface Color',       Event_Pro='Viz_Surface_BCAL_Properties', $
                                 UValue='SURFACE_COLOR')

dummy = Widget_Button(styleMenu, Value='Surface Shading ON', /Separator, UValue='Surface Shading OFF', $
                                 Event_Pro='Viz_Surface_BCAL_Shading')

   ; Create PROPERTIES menu buttons for surface properties.

propMenu = Widget_Button(menuBase, Value='Properties', /Menu)

   ; Drag Quality.

dragMenu = Widget_Button(propMenu, Value='Drag Quality', /Menu)

bDragL = Widget_Button(dragMenu, Value='Low',    Event_Pro='Viz_Surface_BCAL_Event', UValue='DRAG_LOW', /checked)
bDragM = Widget_Button(dragMenu, Value='Medium', Event_Pro='Viz_Surface_BCAL_Event', UValue='DRAG_MEDIUM', /checked)
bDragH = Widget_Button(dragMenu, Value='High',   Event_Pro='Viz_Surface_BCAL_Event', UValue='DRAG_HIGH', /checked)

    ; Axes and colors.

dummy = Widget_Button(propMenu, Value='Set Label Color',      Event_Pro='Viz_Surface_BCAL_Properties', UValue='LABEL_COLOR')
dummy = Widget_Button(propMenu, Value='Set Background Color', Event_Pro='Viz_Surface_BCAL_Properties', UValue='BACKGROUND_COLOR')

dummy = Widget_Button(propMenu, Value='Axes OFF', /Separator, UValue='Axes ON', Event_Pro='Viz_Labels_BCAL')
dummy = Widget_Button(propMenu, Value='Colorbar ON',     UValue='Colorbar OFF', Event_Pro='Viz_Labels_BCAL')

   ; Subsetting the data.

subMenu = Widget_button(propMenu, Value='Data Points', /menu, /separator)
bSubset = Widget_button(subMenu,  Value='*no data loaded*', sensitive=0)
dummy   = Widget_button(subMenu,  Value='Change Subset Number', Event_Pro='Viz_Surface_BCAL_Event', UValue='SUBSET', /separator)

    ; Create PROPERTIES menu buttons for surface properties.

helpMenu = Widget_Button(menuBase, Value='Help', /Menu)
dummy = Widget_Button(helpMenu, Value='Start Help', Event_Pro='Viz_Surface_BCAL_Help', UValue='VIZ_HELP')

    ; Set the initial button states and create structure with the button IDs

widget_control, bDots,   set_button=1
widget_control, bElev,   set_button=1
widget_control, bDragH,  set_button=1

buttons = { bDots   : bDots, $                      ; The dot surface button.
            bWire   : bWire, $                      ; The wire mesh surface button.
            bSolid  : bSolid, $                     ; The solid surface button.
            source  : { single  : bSingle, $        ; The single color button.
                        elev    : bElev, $          ; The elevation color button.
                        inten   : bInten, $         ; The intensity color button.
                        height  : bHeight, $        ; The veg height color button.
                        class   : bClass, $         ; The classification color button.
                        nReturn : bReturn, $        ; The classification color button.
                        angle   : bAngle, $         ; The scan angle color button.
                        image   : bImage }, $       ; The image-based color button.
            bDragL   : bDragL, $                    ; The drag quality LOW button.
            bDragM   : bDragM, $                    ; The drag quality MEDIUM button.
            bDragH   : bDragH, $                    ; The drag quality HIGH button.
            bSubset  : bSubset }                    ; The subset button.


Widget_Control, tlb, /Realize

    ; Get the window destination object. The view will
    ; be drawn when the window is exposed.

Widget_Control, drawID, Get_Value=thisWindow

   ; Create a container object to hold all the other objects. This will make it easy
   ; to free all the objects when we are finished with the program.

thisContainer = Obj_New('IDL_Container')

   ; Add created objects to the container.

thisContainer->Add, thisView
thisContainer->Add, leftTrackball
thisContainer->Add, rightTrackball
thisContainer->Add, xTitle
thisContainer->Add, yTitle
thisContainer->Add, zTitle
thisContainer->Add, xAxis
thisContainer->Add, yAxis
thisContainer->Add, zAxis
thisContainer->Add, poly
thisContainer->Add, staticModel
thisContainer->Add, thisModel
thisContainer->Add, helvetica10pt
thisContainer->Add, helvetica14pt
thisContainer->Add, thisPalette

CD, current = lastdirectory
   ; Create an INFO structure to hold needed program information.

info = { tlb:tlb, $                           ; The top level base.
         thisView:thisView, $                 ; The view object.
         thisContainer:thisContainer, $       ; The object container.
         thisWindow:thisWindow, $             ; The window object.
         poly:poly, $                         ; The point data object
         leftTrackball:leftTrackball, $       ; The trackball object.
         rightTrackball:rightTrackball, $     ; The trackball object.
         thisModel:thisModel, $               ; The model object.
         xAxis:xAxis, $                       ; The X Axis object.
         yAxis:yAxis, $                       ; The Y Axis object.
         zAxis:zAxis, $                       ; The Z Axis object.
         staticLight:staticLight, $           ; The non-rotating light object.
         rotatingLight:rotatingLight, $       ; The rotating light object.
         fillLight:fillLight, $               ; The fill light object.
         ambientLight:ambientLight, $         ; The ambient light object.
         thisPalette:thisPalette, $           ; The surface color palette.
         thisColorbar:thisColorbar, $         ; The surface colorbar.
         colorbarLocation:colorbarLocation, $ ; The location of the colorbar
         filesPtr:filesPtr, $                 ; The file list pointer
         dataPtr:dataPtr, $                   ; The data pointer.
         header:header, $                     ; The data header
         colortable:colortable, $             ; The current color table.
         r:r, $                               ; The R values of the current color table.
         g:g, $                               ; The G values of the current color table.
         b:b, $                               ; The B values of the current color table.
         buttons:buttons, $                   ; The structure of button IDs
         drawID:drawID, $                     ; The widget identifier of the draw widget.
         dragQuality:2, $                     ; The current drag quality.
         surfIndex:!D.Table_Size-22, $        ; The surface color index.
         surfColor:[255,255,255], $           ; The surface color.
         lastDirectory : lastDirectory }      ; The last Directory selected
   ; Store the info structure in the UValue of the TLB.

Widget_Control, tlb, Set_UValue=info, /No_Copy

   ; Call XManager. Set a cleanup routine so the objects
   ; can be freed upon exit from this program.

XManager, 'Viz_surface', tlb, Cleanup='Viz_Surface_BCAL_Cleanup', No_Block=1, $
   Event_Handler='Viz_Resize_BCAL', Group_Leader=groupLeader

END
;-------------------------------------------------------------------