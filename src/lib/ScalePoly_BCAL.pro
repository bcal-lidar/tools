;+
; NAME:
;
;       ScalePoly_BCAL
;
; PURPOSE:
;
;       This function scales a polygon by the requested amount.
;
; AUTHOR:
;
;       David Streutker
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://geology.isu.edu/BCAL
;
; CALLING SEQUENCE:
;
;       result = ScalePoly(Coordinates,Factor)
;
; RETURN VALUE:
;
;       The function returns the coordinates scaled by the factor amount.
;
;       Coordinates is a [2,n] array of polygon coordinates.  Factor is the value by which
;       the coordinates are scaled.  Factor can be vector to scale the polygon differently in
;       each direction.  Positive values of Factor increase the size of the polygon, while
;       negative values decrease it.
;
; DEPENDENCIES:
;
;       GetBounds_BCAL.pro
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, June 2006.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2006 David Streutker, Idaho State University.
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


function ScalePoly_BCAL, coords, d

compile_opt idl2, logical_predicate

    ; Check whether the scale factor is one or two elements.

if n_elements(d) eq 1 then d = [d,d]

    ; Get the x and y values of the coordinates and determine the mid-points and the ranges.

x = coords[0,*]
y = coords[1,*]

xRange = max(x) - min(x)
yRange = max(y) - min(y)

xMid = (max(x) + min(x)) / 2
yMid = (max(y) + min(y)) / 2

    ; Determine if the points are on the positive or negative side of the mid-points.

xPos = where(x gt xMid, complement=xNeg)
yPos = where(y gt yMid, complement=yNeg)

    ; Make sure the polygon is larger than the amount by which it is to be scaled.  (This
    ; only applies for a negative scaling.)

if xRange gt (-2)*d[0] then begin

        ; Scale the x coordinates

    x[xPos] = x[xPos] + d[0]
    x[xNeg] = x[xNeg] - d[0]

endif

if yRange gt (-2)*d[1] then begin

        ; Scale the y coordinates

    y[yPos] = y[yPos] + d[1]
    y[yNeg] = y[yNeg] - d[1]

endif

    ; Call GetBounds_BCAL to eliminate any redundant points.

bounds = GetBounds_BCAL(x,y)
bounds = transpose(bounds)

    ; Return the new coordinates.

return, [x[bounds],y[bounds]]

end
