; $Id: //depot/idl/IDL_71/idldir/lib/idlgrcolorbar__define.pro#1 $
;
; Copyright (c) 1997-2009, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; CLASS_NAME:
;   IDLgrColorbar
;
; PURPOSE:
;   An IDLgrColorbar object consists of a color-ramp with an
;       optional framing box and annotation axis.
;
; CATEGORY:
;   Graphics
;
; SUPERCLASSES:
;       This class inherits from IDLgrModel.
;
; SUBCLASSES:
;       This class has no subclasses.
;
; CREATION:
;       See IDLgrColorbar::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;       IDLgrColorbar::Cleanup
;       IDLgrColorbar::Init
;       IDLgrColorbar::GetProperty
;       IDLgrColorbar::SetProperty
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;-

;+
; =============================================================
;
; METHODNAME:
;       IDLgrColorbar::Init
;
; PURPOSE:
;       The IDLgrColorbar::Init function method initializes the
;       colorbar object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oColorbar = OBJ_NEW('IDLgrColorbar' [,aRed, aGreen, aBlue])
;
;       or
;
;       Result = oColorbar->[IDLgrColorbar::]Init([aRed, aGreen, aBlue])
;
; OPTIONAL INPUTS:
;       aRed:   A vector containing the red values for the colorbar.
;               These values should be within the range of
;               0 <= Value <= 255.  The number of elements comprising
;               the aRed vector must not exceed 256.
;       aGeeen: A vector containing the green values for the colorbar.
;               These values should be within the range of
;               0 <= Value <= 255.  The number of elements comprising
;               the aGreen vector must not exceed 256.
;       aBlue:  A vector containing the blue values for the colorbar.
;               These values should be within the range of
;               0 <= Value <= 255.  The number of elements comprising
;               the aBlue vector must not exceed 256.
;
;       If no data is provided, the color palette will default to a
;       256 entry greyscale ramp.
;
; KEYWORD PARAMETERS:
;       BLUE_VALUES(Get,Set): A vector containing the blue values for
;               the colorbar.  Setting this value is the same as
;               specifying the aBlue argument to the IDLgrColorbar::Init
;               method.
;       COLOR(Get,Set): Set this keyword to the color to be used as
;               the foreground color for the axis and outline box.
;               The color may be specified as a color lookup table index
;               or as an RGB vector.  The default is [0,0,0].
;       DIMENSIONS(Get,Set): Set this keyword to a two element vector
;               [dx,dy] which specifies the size of the ramp display
;               (not the axis) in units.  If dx > dy, the colorbar is
;               drawn horizontally with the axis placed below or above
;               the ramp box depending on the value of the SHOW_AXIS
;               property.  If dx < dy, the colorbar is drawn vertically
;               with the axis placed to the right or left of the ramp
;               box depending on the value of the SHOW_AXIS property.
;               The default value is [16,256].
;       GREEN_VALUES(Get,Set): A vector containing the green values for
;               the colorbar.  Setting this value is the same as
;               specifying the aGreen argument to the IDLgrColorbar::Init
;               method.
;       HIDE(Get,Set): Set this keyword to a boolean value to indicate
;               whether this object should be drawn.  0=Draw (default),
;               1 = Hide.
;       MAJOR(Get,Set): Set this keyword to an integer representing
;               the number of major tick marks.  The default is -1,
;               specifying that IDL will compute the number of tick marks.
;               Setting MAJOR equal to zero suppresses major tick marks
;               entirely.
;       MINOR(Get,Set): Set this keyword to an integer representing
;               the number of minor tick marks.  The default is -1,
;               specifying that IDL will compute the number of tick marks.
;               Setting MINOR equal to zero suppresses minor tick marks
;               entirely.
;       NAME(Get,Set): Set this keyword to a string representing the
;               name to be associated with this object.  The default is
;               the null string, ''.
;       PALETTE(Get,Set): Set this keyword to an IDLgrPalette object
;               to define the color table for the colorbar.
;       RED_VALUES(Get,Set): A vector containing the red values for
;               the colorbar.  Setting this value is the same as
;               specifying the aRed argument to the IDLgrColorbar::Init
;               method.
;       SHOW_AXIS(Get,Set): Set this keyword to an integer value
;               indicating whether the axis should be drawn.  0 = Do
;               not display axis (the default).  1 = Display axis on
;               left side or below the color ramp.  2 = Display axis on
;               right side or above the color ramp.
;       SHOW_OUTLINE(Get,Set): Set this keyword to a boolean value indicating
;               whether the colorbar bounds should be outlined.
;               0 = Do not display outline (the default).  1 = Display
;               outline.
;       SUBTICKLEN(Get,Set): Set this keyword to a scale ratio specifying
;               the length of minor tick marks relative to the length
;               of major tick marks.  The default is 0.5, specifying
;               that the minor tick mark is one-half the length of the
;               major tick mark.
;       THICK(Get,Set): Set this keyword to an float value between 1
;               and 10, specifying the line thickness used to draw the
;               axis and outline box, in points.  The default is 1.
;       THREED(Get): Set this keyword to indicate that the colorbar image
;               is to be implemented as a vertex colored surface to
;               allow the colorbar to be viewed in a true 3
;               dimensional space.
;       TICKFORMAT(Get,Set): Set this keyword to either a standard IDL
;               format string or a string containing the name of a user
;               supplied function that returns a string to be used to
;               format the axis tick mark labels.  The function should
;               accept integer arguments for the direction of the axis,
;               the index of the tick mark, and the value of the tick
;               mark, and hsould return a string to be used as the tick
;               mark's label.  The default is '', the null string, which
;               indicated that IDL will determine the appropriate format
;               for each value.
;       TICKFRMTDATA(Get,Set): Set this keyword to a value of any type.
;       If present, this value is passed via the keyword DATA to
;       any TICKFORMAT function the user may have set.
;       TICKLEN(Get,Set): Set this keyword to the length of each major
;               tick mark, measured in dimension units.  The default
;               tick mark length is 8.
;       TICKTEXT(Get,Set): Set this keyword to either a single instance
;               of the IDLgrText object class (with multiple strings)
;               of to a vector of instances of the IDLgrText object
;               class (one per major tick) to specify the annotations
;               to be assigned to the tickmarks.  By default, with
;               TICKTEXT set equal to a null object, IDL computes the
;               tick labels based on major tick values.  The positions
;               of the provided text objects may be overwritten;
;               position is determined according to tick mark location.
;       TICKVALUES(Get,Set): Set this keyword to a vector of data values
;               representing the values at each tick mark.
;       TITLE(Get,Set): Set this keyword to an instance of the IDLgrText
;               object class to specify the title for the axis.  The
;               default is the null object, specifying that no title is
;               drawn.  The title will be centered along the axis, even
;               if the text object itself has an associated location.
;       UVALUE(Get,Set): Set this keyword to a value of any type.  You
;               may use this value to contain any information you wish.
;       XCOORD_CONV(Get,Set): Set this keyword to a vector, [t,s],
;               indicating the translation and scaling to be applied
;               to convert the X coordinates to an alternate data space.
;               The formula for the conversion is as follows: converted
;               X = t+s*X.  The default is [0,1].
;       YCOORD_CONV(Get,Set): Set this keyword to a vector, [t,s],
;               indicating the translation and scaling to be applied
;               to convert the Y coordinates to an alternate data space.
;               The formula for the conversion is as follows: converted
;               Y = t+s*Y.  The default is [0,1].
;       ZCOORD_CONV(Get,Set): Set this keyword to a vector, [t,s],
;               indicating the translation and scaling to be applied
;               to convert the Z coordinates to an alternate data space.
;               The formula for the conversion is as follows: converted
;               Z = t+s*Z.  The default is [0,1].
;
; OUTPUTS:
;       1: successful, 0: unsuccessful.
;
; EXAMPLE:
;       oColorbar = OBJ_NEW('IDLgrColorbar')
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;                       Scott J. Lasica, 5/8/98
;                        - Added the THREED keyword.
;                        - Added the PALETTE keyword.
;   Modified: C. Torrence, 9/7/00:
;                        - Disable LIGHTING for model.
;                        - Fix position of box outline
;-

FUNCTION IDLgrColorbar::Init, aRed, aGreen, aBlue, BLUE_VALUES = Blue_Values,$
                      COLOR = Color, DIMENSIONS = Dimensions, $
                      GREEN_VALUES = Green_Values, RED_VALUES = Red_Values, $
                      HIDE = Hide, MAJOR = Major, MINOR = Minor, $
                      NAME = Name, SHOW_AXIS = Show_Axis, $
                      SHOW_OUTLINE = Show_Outline,$
                      SUBTICKLEN = Subticklen, THICK = Thick, $
                      TICKFORMAT = Tickformat, TICKFRMTDATA = TickFrmtData, $
              TICKLEN = Ticklen, TICKTEXT = TickText, $
              TICKVALUES = TickValues, TITLE = Title, UVALUE = Uvalue,$
                      XCOORD_CONV = Xcoord_Conv, YCOORD_CONV = Ycoord_Conv, $
                      ZCOORD_CONV = Zcoord_Conv, THREED = threeD, $
                      PALETTE = palette, _EXTRA = e

    CATCH, Error_Status
    if (Error_Status ne 0) then begin
        if (OBJ_VALID(self.oCoordConvNode)) then $
        OBJ_DESTROY, self.oCoordConvNode
        if (OBJ_VALID(self.oScaleNode)) then $
        OBJ_DESTROY, self.oScaleNode
        if (OBJ_VALID(self.oAxis)) then $
        OBJ_DESTROY, self.oAxis
        if (OBJ_VALID(self.oPoly)) then $
        OBJ_DESTROY, self.oPoly
        if (OBJ_VALID(self.oSurf)) then $
        OBJ_DESTROY, self.oSurf
        if (OBJ_VALID(self.oImage)) then $
        OBJ_DESTROY, self.oImage
        if (self.Free_Palette AND (OBJ_VALID(self.oPalette))) then $
            OBJ_DESTROY, self.oPalette
        return, 0
    endif

    if (self->IDLgrModel::Init(_EXTRA=e) ne 1) then RETURN, 0
    self->IDLgrModel::SetProperty, /SELECT_TARGET
    if (KEYWORD_SET(Hide)) then self->IDLgrModel::SetProperty, Hide=1

    if (N_ELEMENTS(Name) gt 0) then $
      self->IDLgrModel::SetProperty, Name = Name

    if (N_ELEMENTS(Uvalue) gt 0) then $
      self->IDLgrModel::SetProperty, Uvalue = UValue

    GreyScale = 0

    ; see if the keywords for the color values were set
    if (N_ELEMENTS(Blue_Values) gt 0) then $
      aBlue = Blue_Values
    if (N_ELEMENTS(Green_Values) gt 0) then $
      aGreen = Green_Values
    if (N_ELEMENTS(Red_Values) gt 0) then $
      aRed = Red_Values

    ; See if a palette was provided.  If so, ensure validity.
    if (N_ELEMENTS(palette) gt 0) then begin
      if (size(palette,/type) ne 11) then begin
          MESSAGE,'Not a valid IDLgrPalette object.', /CONTINUE
          return, 0
      endif
      if (NOT (OBJ_VALID(palette))) then begin
           MESSAGE,'Not a valid IDLgrPalette object.', /CONTINUE
           return, 0
      endif
      if (NOT (OBJ_ISA(palette,'IDLgrPalette'))) then begin
           MESSAGE,'Not a valid IDLgrPalette object.', /CONTINUE
           return, 0
      endif
    endif

    ; check to see if they passed in the RGB args
    case (N_PARAMS()) of
        0: begin ;No args - default to greyscale.
            if (N_ELEMENTS(palette) gt 0) then begin
                palette->GetProperty, RED_VALUES=aRed, GREEN_VALUES=aGreen, $
                                      BLUE_VALUES=aBlue
            endif else begin
                GreyScale = 1
                aRed = indgen(256)
                aGreen = aRed
                aBlue = aRed
            endelse
        end
        1: begin ; Red only.
           ; Verify that the argument is defined.
            if (N_ELEMENTS(aRed) eq 0) then begin
               MESSAGE,'Undefined argument.', /CONTINUE
               return, 0
            endif

            ; Clone to green and blue.
            aGreen = aRed
            aBlue = aRed
        end
        2: begin ; Error condition.
            MESSAGE,'Incorrect number of arguments.', /CONTINUE
        return, 0
        end
        3: begin ; Red, Green, and Blue.
           ; Verify that the arguments are defined.
           if ((N_ELEMENTS(aRed) eq 0) or $
               (N_ELEMENTS(aGreen) eq 0) or $
               (N_ELEMENTS(aBlue) eq 0)) then begin
               MESSAGE,'Undefined argument.', /CONTINUE
               return, 0
           endif
        end
    endcase

    ; Create the palette if one is not already available
    if (N_ELEMENTS(palette) eq 0) then begin
      self.oPalette = OBJ_NEW('IDLgrPalette', aRed, aGreen, aBlue)
      self.Free_Palette = 1
    endif else begin
      self.oPalette = palette
      self.Free_Palette = 0 ; Do not free a palette we do not own.
    endelse

    ; need this to calculate the size of the image later
    self.maxDim=max([N_ELEMENTS(aRed),N_ELEMENTS(aGreen),N_ELEMENTS(aBlue)])
    self.maxDim = self.maxDim < 256

    if (N_ELEMENTS(Color) le 0) then $
      Color = [0,0,0]
    if (N_ELEMENTS(Dimensions) eq 2) then $
      self.dimensions = Dimensions $
    else $
      self.dimensions = [16,self.maxDim]
    if (N_ELEMENTS(Show_Axis) le 0) then begin
      self.Show_Axis = 0
    endif else if ((Show_Axis gt 2) or (Show_Axis lt 0)) then begin
        MESSAGE,'Invalid value for SHOW_AXIS, using default.', /CONTINUE
        self.Show_Axis = 0
    endif else self.Show_Axis = Show_Axis
    if (self.Show_Axis eq 0) then $
        Hide_Axis = 1

    if (not KEYWORD_SET(Show_Outline)) then $
      Show_Outline = 0
    if (N_ELEMENTS(Thick) le 0) then $
      Thick = 1

    if (N_ELEMENTS(Title) le 0) then $
      Title = OBJ_NEW()
    if (N_ELEMENTS(Major) le 0) then $
      Major = -1
    if (N_ELEMENTS(Minor) le 0) then $
      Minor = -1
    if (N_ELEMENTS(Subticklen) le 0) then $
      Subticklen = 0.5
    if (N_ELEMENTS(Ticklen) le 0) then $
      Ticklen = 8
    if (N_ELEMENTS(TickText) le 0) then $
      TickText = OBJ_NEW()
    if (N_ELEMENTS(TickValues) le 0) then $
      TickValues = 0


    transform = [[1.0,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
    if(N_ELEMENTS(Xcoord_Conv) gt 0) then begin
        transform[0,0] = Xcoord_Conv[1]
        transform[3,0] = Xcoord_Conv[0]
    endif
    if(N_ELEMENTS(Ycoord_Conv) gt 0) then begin
        transform[1,1] = Ycoord_Conv[1]
        transform[3,1] = Ycoord_Conv[0]
    endif
    if(N_ELEMENTS(Zcoord_Conv) gt 0) then begin
        transform[2,2] = Zcoord_Conv[1]
        transform[3,2] = Zcoord_Conv[0]
    endif

    ; This node will handle coordinate conversion.
    self.oCoordConvNode = OBJ_NEW('IDLgrModel')

    ; This node will allow scaling of all the sub objects
    ; turn off lighting so the colorbar is always lit (make keyword?)
    self.oScaleNode = OBJ_NEW('IDLgrModel',LIGHTING=0)

    self.oCoordConvNode->SetProperty, TRANSFORM = transform

    ; Create the polyline (Outline)
    self.oPoly = OBJ_NEW('IDLgrPolyline', HIDE = (1-Show_Outline), $
                         COLOR = Color)

    ; Do we need to make it 3D?
    if (KEYWORD_SET(threeD)) then begin
        self.oSurf = OBJ_NEW('IDLgrSurface', STYLE=2, /DEPTH_TEST_DISABLE)

        vertex_colors = BYTARR(3,self.maxDim)
        vertex_colors[0,*] = aRed
        vertex_colors[1,*] = aGreen
        vertex_colors[2,*] = aBlue
        if (self.dimensions[1] gt self.dimensions[0]) then begin  ; vertical...
            ;; Since the vertex colors map in the X direction first, I
            ;; need to duplicate all of my colors so that the 2 X
            ;; points at each Y are the same.  I don't have to do this
            ;; for the horizontal because the "upper" points simply
            ;; cycle the colors and it works out right
            vertex_colors = congrid(vertex_colors,3,2*self.maxDim)
        endif
        self.oSurf->SetProperty, VERT_COLORS = vertex_colors
    endif else begin

        self.oImage = OBJ_NEW('IDLgrImage', PALETTE = self.oPalette, $
                              GREYSCALE = GreyScale) ; Create the image
    endelse

    self.oAxis = OBJ_NEW('IDLgrAxis',HIDE = Hide_Axis, $
                         TICKLEN = Ticklen, $
                         SUBTICKLEN = Subticklen, $
                         MAJOR = Major, $
                         MINOR = Minor, $
                         TITLE = Title, $
                         TICKTEXT = TickText, $
                         TICKVALUES = TickValues, $
                         COLOR = Color, /EXACT)

    if (N_ELEMENTS(TickFrmtData) gt 0) then $
        self.oAxis->SetProperty, TICKFRMTDATA = TickFrmtData
    if (N_ELEMENTS(Tickformat) GT 0) then $
        self.oAxis->SetProperty, TICKFORMAT = Tickformat

    self.oAxis->GetProperty, TICKTEXT = temporaryText
    temporaryText->SetProperty, RECOMPUTE_DIMENSIONS=2

    ; Get the sizes
    self->CalcSize, DIMENSIONS = self.dimensions, THICK = Thick, $
      SHOW_AXIS = self.Show_Axis

    ; Add everything needed to the state
    self.oCoordConvNode->Add,self.oScaleNode
    if (KEYWORD_SET(threeD)) then $
      self.oScaleNode->Add,self.oSurf $
    else $
      self.oScaleNode->Add,self.oImage
    self.oScaleNode->Add,self.oPoly
    self.oScaleNode->Add,self.oAxis
    self->Add, self.oCoordConvNode

    RETURN, 1
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrColorbar::ComputeDimensions
;
; PURPOSE:
;       The IDLgrColorbar::ComputeDimensions method function
;       computes and returns the dimensions of the colorbar
;       for a given destination.
;
; CALLING SEQUENCE:
;       Result = oColorbar->[IDLgrColorbar::]ComputeDimensions(SrcDest)
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 3/5/98
;   Modified: CT, RSI, Oct 2000
;               - Add support for colorbar-only
;               - Fix calc for long titles or ticktext
;-

function IDLgrColorbar::ComputeDimensions, oSrcDest, PATH=aliasPath

    self->GetProperty, THICK = thick, DIMENSIONS = dims
    self->CalcSize, DIMENSIONS=dims, THICK=thick, SHOW_AXIS=self.show_axis
    self->GetProperty, XRANGE=xRange, YRANGE=yRange

    self.oScaleNode->GetProperty, TRANSFORM = transform
    xRange = xRange / transform[0,0]  ; convert back to normalized
    yRange = yRange / transform[1,1]  ; convert back to normalized

    if (self.Show_Axis gt 0) then begin
        self.oAxis->GetProperty, TICKTEXT = oText, TITLE = oTitle
        ;; If we have a title, include it
        if (OBJ_VALID(oTitle)) then begin
            ; call GetTextDimensions to force dimensions to be recomputed
            textDims = oSrcDest->GetTextDimensions(oTitle, PATH=aliasPath)
            ; these are already in normalized units
            oTitle->GetProperty, XRANGE=xrTitle, YRANGE=yrTitle
            xRange[0] = xRange[0] < xrTitle[0]
            xRange[1] = xRange[1] > xrTitle[1]
            yRange[0] = yRange[0] < yrTitle[0]
            yRange[1] = yRange[1] > yrTitle[1]
        endif
        if (OBJ_VALID(oText)) then begin
            ; call GetTextDimensions to force dimensions to be recomputed
            textDims = oSrcDest->GetTextDimensions(oText,PATH=aliasPath)
            ; these are already in normalized units
            oText->GetProperty, XRANGE=xrText, YRANGE=yrText
            xRange[0] = xRange[0] < xrText[0]
            xRange[1] = xRange[1] > xrText[1]
            yRange[0] = yRange[0] < yrText[0]
            yRange[1] = yRange[1] > yrText[1]
        endif
    endif

    xDim = (xRange[1] - xRange[0]) * transform[0,0]
    yDim = (yRange[1] - yRange[0]) * transform[1,1]
    return, [xDim, yDim, 0.0]
end

;+
; =============================================================
;
; METHODNAME:
;       IDLgrColorbar::CalcSize
;
; PURPOSE:
;       This method is intended to be private, and should never be called
;       directly.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;-

PRO IDLgrColorbar::CalcSize, DIMENSIONS = Dimensions, THICK = Thick, $
                 SHOW_AXIS = Show_Axis

    self.dimensions = Dimensions

    if(Show_Axis gt 0)then begin
        self.oAxis->SetProperty, HIDE = 0
    endif $
    else $
      self.oAxis->SetProperty, HIDE = 1

    ; Create the ramp of indexed integers for the IDLgrImage

    ; horizontal
    if (Dimensions[0] gt Dimensions[1]) then begin
        if (OBJ_VALID(self.oImage)) then begin
            myRamp = intarr(self.maxDim, 16)
            myRampVector = indgen(self.maxDim)
            for index = 0,15 do $
              myRamp[*,index] = myRampVector
        endif
        Direction = 0
        if (Show_Axis eq 2) then begin
            Location = [0,0,0]
            Tickdir = 1
        endif else begin
            Location = [0,16,0]
            Tickdir = 0
        endelse
        Range = [0,self.maxDim]
        polyData = [[0, 0],$
                    [self.maxDim,0],$
                    [self.maxDim, 16],$
                    [0, 16],$
                    [0, 0]]
        ; scaling calculation
        Sx = float(Dimensions[0])/float(self.maxDim)
        Sy = float(Dimensions[1]/16.0)

        if (OBJ_VALID(self.oSurf)) then $
          self.oSurf->SetProperty, DATAX=indgen(self.maxDim+1), $
          DATAY=[0,16],DATAZ=intarr(self.maxDim+1,2)
    ; vertical
    endif else begin
        if (OBJ_VALID(self.oImage)) then begin
            myRamp = intarr(16, self.maxDim)
            myRampVector = indgen(self.maxDim)
            for index = 0,15 do $
              myRamp[index,*] = myRampVector
        endif
        Direction = 1
        if (Show_Axis eq 2) then begin
            Location = [16,0,0]
            Tickdir = 0
        endif else begin
            Location = [0,0,0]
            Tickdir = 1
        endelse
        Range = [0,self.maxDim]
        polyData = [[0, 0],[16, 0],$
                    [16, self.maxDim],$
                    [0, self.maxDim],$
                    [0, 0]]
        ; scaling calculation
        Sx = float(Dimensions[0]/16.0)
        Sy = float(Dimensions[1])/float(self.maxDim)

        if (OBJ_VALID(self.oSurf)) then $
            self.oSurf->SetProperty, DATAX=[0,16], $
              DATAY=indgen(self.maxDim+1),DATAZ=intarr(2,self.maxDim+1)
    endelse

    if (OBJ_VALID(self.oImage)) then $
      self.oImage->SetProperty, DATA = myRamp

    self.oAxis->SetProperty, LOCATION = Location, TICKDIR = Tickdir, $
      RANGE = Range, DIRECTION = Direction, THICK = Thick, $
      TEXTPOS = (1 - Tickdir)

    self.oPoly->SetProperty, DATA = polyData, THICK = Thick

    ;scaling needed from the dimensions
    self.oScaleNode->Reset
    self.oScaleNode->Scale, Sx, Sy, 1

    ;need to tell the text on the axis to recalculate its font size
    self.oAxis->GetProperty,TICKTEXT = oTicktext
    oTicktext->SetProperty,CHAR_DIMENSIONS = [0,0]

END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrColorbar::Cleanup
;
; PURPOSE:
;       The IDLgrColorbar::Cleanup procedure method preforms all cleanup
;       on the object.
;
;       NOTE: Cleanup methods are special lifecycle methods, and as such
;       cannot be called outside the context of object destruction.  This
;       means that in most cases, you cannot call the Cleanup method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Cleanup method
;       from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;       OBJ_DESTROY, oColorbar
;
;       or
;
;       oColorbar->[IDLgrColorbar::]Cleanup
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       There are no keywords for this method.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;-

PRO IDLgrColorbar::Cleanup

    OBJ_DESTROY,self.oAxis
    OBJ_DESTROY,self.oPoly
    if (OBJ_VALID(self.oSurf)) then OBJ_DESTROY, self.oSurf
    ; The original colorbar object did not include a palette property.
    ; In this case, the palette on the image should be freed.
    if (NOT (OBJ_VALID(self.oPalette))) then begin
        self.oImage->GetProperty, PALETTE = palette
        OBJ_DESTROY, palette
    endif
    if (OBJ_VALID(self.oImage)) then OBJ_DESTROY,self.oImage
    if (self.Free_Palette AND (OBJ_VALID(self.oPalette))) then $
        OBJ_DESTROY,self.oPalette
    OBJ_DESTROY,self.oCoordConvNode
    OBJ_DESTROY,self.oScaleNode

    ; Cleanup the superclass.
    self->IDLgrModel::Cleanup
END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrColorbar::SetProperty
;
; PURPOSE:
;       The IDLgrColorbar::SetProperty procedure method sets the value
;       of a property or group of properties for the colorbar.
;
; CALLING SEQUENCE:
;       oColorbar->[IDLgrColorbar::]SetProperty
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       Any keyword to IDLgrColorbar::Init followed by the word "Set"
;       can be set using IDLgrColorbar::SetProperty.
;
; EXAMPLE:
;       oColorbar->SetProperty, THICK = 1
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;-

PRO IDLgrColorbar::SetProperty, BLUE_VALUES = Blue_Values,$
                 COLOR = Color, DIMENSIONS = Dimensions, $
                 GREEN_VALUES = Green_Values, RED_VALUES = Red_Values, $
                 HIDE = Hide, MAJOR = Major, MINOR = Minor, $
                 NAME = Name, SHOW_AXIS = Show_Axis, $
                 SHOW_OUTLINE = Show_Outline, $
                 SUBTICKLEN = Subticklen, THICK = Thick, $
                 THREED = threeD, $
                 TICKFORMAT = Tickformat, TICKFRMTDATA = TickFrmtData, $
         TICKLEN = Ticklen, TICKTEXT = TickText, $
         TICKVALUES = TickValues, TITLE = Title, UVALUE = Uvalue, $
                 XCOORD_CONV = Xcoord_Conv, YCOORD_CONV = Ycoord_Conv, $
                 ZCOORD_CONV = Zcoord_Conv, PALETTE = palette, _EXTRA=e

    ; NOTE: the THREED keyword is only accepted here to catch the fact that a
    ; user attempted to set it, in which case a warning message can be printed.
    ; If THREED was not explicitly included here, it would be handled
    ; quietly via the _EXTRA keyword, and the user would never be notified
    ; that it had no effect on the IDLgrColorbar.

    ; Pass along extraneous keywords to the superclass
    self->IDLgrModel::SetProperty, _EXTRA=e

    ; NOTE: dimensions must be processed before palette changes.
    if (N_ELEMENTS(Dimensions) EQ 2) then begin
      self.dimensions = Dimensions
      reCalc = 1
    endif else $
      reCalc = 0

    GreyScale = 1

    ; See if a palette was provided.  If so, ensure validity.
    if (N_ELEMENTS(palette) gt 0) then begin
      if (size(palette,/type) ne 11) then begin
          MESSAGE,'Not a valid IDLgrPalette object.',/info
          RETURN
      endif
      if (NOT (OBJ_VALID(palette))) then begin
           MESSAGE,'Not a valid IDLgrPalette object.',/info
           RETURN
      endif
      if (NOT (OBJ_ISA(palette,'IDLgrPalette'))) then begin
           MESSAGE,'Not a valid IDLgrPalette object.',/info
           RETURN
      endif

      ; Modify colorbar palette only if palette object changed.
      if (self.oPalette NE palette) then begin
          ; Free old palette if appropriate.
          if (self.Free_Palette AND (OBJ_VALID(self.oPalette))) then $
              OBJ_DESTROY, self.oPalette
          self.oPalette = palette
          self.Free_Palette = 0

          ; Update image.
          if (OBJ_VALID(self.oImage)) then $
              self.oImage->SetProperty, PALETTE = palette
      endif
      GreyScale = 0
    endif

    ; Ensure a palette is present.  The original colorbar object did not
    ; include a palette property; account for that possibility.
    IF (NOT (OBJ_VALID(self.oPalette))) THEN BEGIN
        self.oImage->GetProperty, PALETTE = palette
        self.oPalette = palette
        self.Free_Palette = 1
    ENDIF

    ; Override palette colors with keyword settings if available.
    if (N_ELEMENTS(Blue_Values) gt 0) then begin
        self.oPalette->SetProperty, BLUE_VALUES = Blue_Values
        GreyScale = 0
    endif
    if (N_ELEMENTS(Green_Values) gt 0) then begin
        self.oPalette->SetProperty, GREEN_VALUES = Green_Values
        GreyScale = 0
    endif
    if (N_ELEMENTS(Red_Values) gt 0) then begin
        self.oPalette->SetProperty, RED_VALUES = Red_Values
        GreyScale = 0
    endif

    if (OBJ_VALID(self.oImage)) then $
        if (not GreyScale) then self.oImage->SetProperty, GREYSCALE = 0

    ; Update the surface vertex colors according to the palette entries.
    if (OBJ_VALID(self.oSurf)) then begin
        self.oPalette->GetProperty, RED_VALUES=aRed, GREEN_VALUES=aGreen, $
            BLUE_VALUES=aBlue
        vertex_colors = BYTARR(3,self.maxDim)
        vertex_colors[0,*] = aRed
        vertex_colors[1,*] = aGreen
        vertex_colors[2,*] = aBlue

        if (self.dimensions[1] gt self.dimensions[0]) then begin  ; vertical...
            ;; Since the vertex colors map in the X direction first, I
            ;; need to duplicate all of my colors so that the 2 X
            ;; points at each Y are the same.  I don't have to do this
            ;; for the horizontal because the "upper" points simply
            ;; cycle the colors and it works out right
            vertex_colors = congrid(vertex_colors,3,2*self.maxDim)
        endif
        self.oSurf->SetProperty, VERT_COLORS = vertex_colors
    endif

    if (N_ELEMENTS(Name) gt 0) then $
      self->IDLgrModel::SetProperty, NAME = Name[0]

    if (N_ELEMENTS(Color) eq 3) then begin
        self.oPoly->SetProperty, COLOR = Color
        self.oAxis->SetProperty, COLOR = Color
    endif
    if (N_ELEMENTS(Thick) le 0) then $
      self.oPoly->GetProperty, Thick=Thick else reCalc = 1
    if (N_ELEMENTS(threeD) gt 0) then $
      MESSAGE,'Keyword THREED can only be set in ::Init method.', /CONTINUE
    if (N_ELEMENTS(Show_Axis) le 0) then $
      Show_Axis = self.Show_Axis $
    else begin
        reCalc = 1
        self.Show_Axis = Show_Axis
    endelse
    if (N_ELEMENTS(Hide) gt 0) then $
      self->IDLgrModel::SetProperty, HIDE = Hide
    if (N_ELEMENTS(Subticklen) gt 0) then $
      self.oAxis->SetProperty, SUBTICKLEN = Subticklen
    if (N_ELEMENTS(Ticklen) gt 0) then $
      self.oAxis->SetProperty, TICKLEN = Ticklen
    if (N_ELEMENTS(TickFrmtData) gt 0) then $
        self.oAxis->SetProperty, TICKFRMTDATA = TickFrmtData
    if (N_ELEMENTS(Tickformat) GT 0) then $
        self.oAxis->SetProperty, TICKFORMAT = Tickformat

    ; The number of major tickmarks, tickvalues, and ticktext must match,
    ; so set all three simultaneously if any are present.
    bSetMajor = 0
    if (N_ELEMENTS(Major) le 0) then $
      self.oAxis->GetProperty, MAJOR = Major $
    else $
      bSetMajor = 1
    if (N_ELEMENTS(TickText) le 0) then $
      self.oAxis->GetProperty, TICKTEXT = TickText $
    else $
      bSetMajor = 1
    if (N_ELEMENTS(TickValues) le 0) then $
      self.oAxis->GetProperty, TICKVALUES = TickValues $
    else $
      bSetMajor = 1

    if (bSetMajor NE 0) then $
      self.oAxis->SetProperty, MAJOR = Major, TICKTEXT = TickText, $
                               TICKVALUES = TickValues
    if (N_ELEMENTS(Minor) gt 0) then $
      self.oAxis->SetProperty, MINOR = Minor

    if (N_ELEMENTS(Show_Outline) gt 0) then $
      self.oPoly->SetProperty, HIDE = (1-Show_Outline)
    if (N_ELEMENTS(Title) gt 0) then begin
        self.oAxis->SetProperty, TITLE = Title
    endif
    if (N_ELEMENTS(Uvalue) gt 0) then $
      self->IDLgrModel::SetProperty, Uvalue = UValue

    ; Recalc
    if(reCalc) then $
      self->CalcSize, DIMENSIONS = self.dimensions, THICK = Thick, $
        SHOW_AXIS = Show_Axis

    ;coordinate conversion
    self.oCoordConvNode->GetProperty, TRANSFORM = transform
    if(N_ELEMENTS(Xcoord_Conv) gt 0) then begin
        transform[0,0] = Xcoord_Conv[1]
        transform[3,0] = Xcoord_Conv[0]
    endif
    if(N_ELEMENTS(Ycoord_Conv) gt 0) then begin
        transform[1,1] = Ycoord_Conv[1]
        transform[3,1] = Ycoord_Conv[0]
    endif
    if(N_ELEMENTS(Zcoord_Conv) gt 0) then begin
        transform[2,2] = Zcoord_Conv[1]
        transform[3,2] = Zcoord_Conv[0]
    endif
    self.oCoordConvNode->SetProperty, TRANSFORM = transform

END

;+
; =============================================================
;
; METHODNAME:
;       IDLgrColorbar::GetProperty
;
; PURPOSE:
;       The IDLgrColorbar::GetProperty procedure method retrieves the
;       value of a property or group of properties for the colorbar.
;
; CALLING SEQUENCE:
;       oColorbar->[IDLgrColorbar::]GetProperty
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       Any keyword to IDLgrColorbar::Init followed by the word "Get"
;       can be retrieved using IDLgrColorbar::GetProperty.  In addition
;       the following keywords are available:
;
;       ALL:    Set this keyword to a named variable that will contain
;               an anonymous structure containing the values of all the
;               retrievable properties associated with this object.
;               NOTE: UVALUE is not returned in this struct.
;       PARENT: Set this keyword to a named variable that will contain
;               an object reference to the object that contains this colorbar.
;       XRANGE: Set this keyword to a named variable that will contain
;               a two-element vector of the form [xmin,xmax] specifying
;               the range of the x data coordinates covered by the colorbar.
;       YRANGE: Set this keyword to a named variable that will contain
;               a two-element vector of the form [ymin,ymax] specifying
;               the range of the y data coordinates covered by the colorbar.
;       ZRANGE: Set this keyword to a named variable that will contain
;               a two-element vector of the form [zmin,zmax] specifying
;               the range of the z data coordinates covered by the colorbar.
;
; EXAMPLE:
;       myColorbar->GetProperty, PARENT = parent
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;-

PRO IDLgrColorbar::GetProperty, BLUE_VALUES = Blue_Values, $
                 COLOR = Color, DIMENSIONS = Dimensions, $
                 GREEN_VALUES = Green_Values, RED_VALUES = Red_Values, $
                 HIDE = Hide, MAJOR = Major, MINOR = Minor, $
                 NAME = Name, SHOW_AXIS = Show_Axis, $
                 SHOW_OUTLINE = Show_Outline, $
                 SUBTICKLEN = Subticklen, THICK = Thick, $
                 TICKFORMAT = Tickformat, TICKFRMTDATA = TickFrmtData, $
                 TICKLEN = Ticklen, TICKTEXT = TickText, $
                 TICKVALUES = TickValues, TITLE = Title, TRANSFORM=modelTransform, $
                 UVALUE = Uvalue, $
                 XCOORD_CONV = Xcoord_Conv, YCOORD_CONV = Ycoord_Conv, $
                 ZCOORD_CONV = Zcoord_Conv, ALL = All, PARENT = Parent, $
                 XRANGE = Xrange, YRANGE = Yrange, ZRANGE = Zrange, $
                 THREED = threeD, PALETTE = palette, _REF_EXTRA=_extra

    ; Ensure a palette is present.  The original colorbar object did not
    ; include a palette property; account for that possibility.
    IF (NOT (OBJ_VALID(self.oPalette))) THEN BEGIN
        self.oImage->GetProperty, PALETTE = palette
        self.oPalette = palette
        self.Free_Palette = 1
    ENDIF

    palette = self.oPalette
    self.oPalette->GetProperty, BLUE_VALUES = Blue_Values, $
      RED_VALUES = Red_Values,GREEN_VALUES = Green_Values

    if (OBJ_VALID(self.oImage)) then begin
        self.oImage->GetProperty, XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange
        threeD = 0
    endif else begin
        self.oSurf->GetProperty, XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange
        threeD = 1
    endelse

    self.oPoly->GetProperty, COLOR = Color, HIDE = Show_Outline
    Show_Outline = 1 - Show_Outline

    Dimensions = self.dimensions

    self->IDLgrModel::GetProperty, HIDE = Hide, NAME = Name, $
        TRANSFORM=modelTransform, UVALUE = Uvalue
    Show_Axis = self.Show_Axis
    self.oAxis->GetProperty, MAJOR = Major, MINOR = Minor, $
      SUBTICKLEN = Subticklen, THICK = Thick, TICKFORMAT = Tickformat, $
      TICKFRMTDATA = TickFrmtData, TICKLEN = Ticklen, TICKTEXT = TickText, $
      TICKVALUES = TickValues, TITLE = Title

    if (Show_Outline) then begin
        self.oPoly->GetProperty, XRANGE = xRange
        self.oPoly->GetProperty, YRANGE = yRange
    endif

    ;; Need to add the axis range into the picture
    if (Show_Axis gt 0) then begin
        if (Dimensions[0] gt Dimensions[1]) then begin
            self.oAxis->GetProperty, YRANGE = axisYrange
            yRange[0] = min([yRange[0],axisYrange[0]])
            yRange[1] = max([yRange[1],axisYrange[1]])
        endif else begin
            self.oAxis->GetProperty, XRANGE = axisXrange
            xRange[0] = min([xRange[0],axisXrange[0]])
            xRange[1] = max([xRange[1],axisXrange[1]])
        endelse
    endif

    self.oScaleNode->GetProperty, TRANSFORM = transform
    xRange = xRange * transform[0,0]
    yRange = yRange * transform[1,1]

    ;; Get the transform matrix
    self.oCoordConvNode->GetProperty, TRANSFORM = transform
    Xcoord_Conv = [transform[3,0],transform[0,0]]
    Ycoord_Conv = [transform[3,1],transform[1,1]]
    Zcoord_Conv = [transform[3,2],transform[2,2]]

    self->IDLgrModel::GetProperty, Parent = Parent, _EXTRA=_EXTRA

    All = { Blue_Values: Blue_Values, $
            Green_Values: Green_Values, $
            Red_Values: Red_Values, $
            Color: Color, $
            Dimensions: Dimensions, $
            Hide: Hide, $
            Name: Name, $
            Parent: Parent, $
            Show_Axis: Show_Axis, $
            Show_Outline: Show_Outline, $
            Major: Major, $
            Minor: Minor, $
            Subticklen: Subticklen, $
            Thick: Thick, $
            Tickformat: Tickformat, $
            Ticklen: Ticklen, $
            TickText: TickText, $
            TickValues: TickValues, $
            Title: Title, $
            Transform: modelTransform, $
            xRange: xRange, $
            yRange: yRange, $
            zRange: zRange, $
            Xcoord_Conv: Xcoord_Conv, $
            Ycoord_Conv: Ycoord_Conv, $
            Zcoord_Conv: Zcoord_Conv $
          }

END

;+
;----------------------------------------------------------------------------
; IDLgrColorbar__Define
;
; Purpose:
;  Defines the object structure for an IDLgrColorbar object.
;
; MODIFICATION HISTORY:
;   Written by: Scott J. Lasica, 9/22/97
;-

PRO IDLgrColorbar__Define

    COMPILE_OPT hidden

    struct = { IDLgrColorbar, $
               INHERITS IDLgrModel, $
               oCoordConvNode: OBJ_NEW(), $
               oScaleNode: OBJ_NEW(), $
               maxDim: 0, $
               dimensions: [0.0,0.0], $
               oAxis: OBJ_NEW(), $
               oPoly: OBJ_NEW(), $
               oSurf: OBJ_NEW(), $
               oImage: OBJ_NEW(), $
               oPalette: OBJ_NEW(), $
               Free_Palette: 0, $
               Show_Axis: 0, $
               IDLgrColorbarVersion: 3 $
             }
END







