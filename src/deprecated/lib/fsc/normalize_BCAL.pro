;+
; NAME:
;       NORMALIZE
;
; PURPOSE:
;
;       This is a utility routine to calculate the scaling vector
;       required to position a graphics primitive of specified range
;       at a specific position in an arbitray coordinate system. The
;       scaling vector is given as a two-element array like this:
;
;          scalingVector = [translationFactor, scalingFactor]
;
;       The scaling vector should be used with the [XYZ]COORD_CONV
;       keywords of a graphics object or model. For example, if you
;       wanted to scale an X axis into the coordinate range of -0.5 to 0.5,
;       you might type something like this:
;
;          xAxis->GetProperty, Range=xRange
;          xScale = Normalize(xRange, Position=[-0.5, 0.5])
;          xAxis, XCoord_Conv=xScale
;
; AUTHOR:
;
;       FANNING SOFTWARE CONSULTING
;       David Fanning, Ph.D.
;       1645 Sheely Drive
;       Fort Collins, CO 80526 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:

;       Object Graphics
;
; CALLING SEQUENCE:
;       xscaling = NORMALIZE(xrange, POSITION=position)
;
; INPUTS:
;       XRANGE: A two-element vector specifying the data range.
;
; KEYWORD PARAMETERS:
;       POSITION: A two-element vector specifying the location
;       in the coordinate system you are scaling into. The vector [0,1]
;       is used by default if POSITION is not specified.
;
; COMMON BLOCKS:
;       None.
;
; EXAMPLE:
;       See above.
;
; MODIFICATION HISTORY:
;       Written by:  David W. Fanning, OCT 1997.
;       Fixed a problem with illegal divide by zero. 21 April 2005. DWF.
;-

FUNCTION Normalize_BCAL, range, Position=position
compile_opt idl2

On_Error, 1
IF N_Params() EQ 0 THEN Message, 'Please pass range vector as argument.'

IF (N_Elements(position) EQ 0) THEN position = [0.0D, 1.0D] ELSE $
    position=Double(position)
range = Double(range)

scale = [((position[0]*range[1])-(position[1]*range[0])) / $
    ((range[1]-range[0]) > 1e-12), (position[1]-position[0])/((range[1]-range[0]) > 1e-12)]

RETURN, scale
END
;-------------------------------------------------------------------------
