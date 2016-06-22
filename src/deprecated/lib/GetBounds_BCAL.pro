;+
; NAME:
;
;       GetBounds_BCAL
;
; PURPOSE:
;
;       Given two vectors of X and Y coordinates, this function selects the points
;       that form a boundary around the data.  The boundary points are determined by
;       creating a convex hull for the data.
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
;       points = GetBounds(X, Y, PRECISION=PRECISION)
;
;       X and Y are vectors that contain the x and y coordinates, respectively.
;
;       Set the PRECISION keyword to a distance value of how precise the border vector will be
;
; RETURN VALUE:
;
;       The function returns the indices corresponding to the points in the arrays
;       that form a boundary polygon.
;
; KNOWN ISSUES:
;
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, April 2006.
;       Added PRECISION keyword, September 2006
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

function GetBounds_BCAL, x, y, precision=precision

compile_opt idl2, logical_predicate

    ; If the precision keyword is set, then begin.  Otherwise, use the convex hull method

if keyword_set(precision) then begin

        ; Get some of the data properties

    xMax = max(x, min=xMin)
    yMax = max(y, min=yMin)

    xRange = xMax - xMin
    yRange = yMax - yMin

        ; Determine which dimension is the longer of the two

    if yRange gt xRange then begin

        sCoord = x
        lCoord = y

        lMin = yMin
        lMax = yMax

    endif else begin

        lCoord = x
        sCoord = y

        lMin = xMin
        lMax = xMax

    endelse

    dim = ceil((xRange > yRange) / precision)

        ; Set up the array to record the boundary points

    bPoints = lonarr(2 * dim) - 1

        ; Histogram the data by y value

    hist = histogram(lCoord, min=lMin, max=lMax, binsize=precision, reverse_indices=index)

        ; Iterate through the y values

    for a=0,dim-1 do begin

            ; For each y value, record the index of the minimum and maximum x values.  These
            ; will form the boundary values (up one side of the data, down the other).

        if hist[a] then begin

            tempIndex = index[index[a]:index[a+1]-1]
            dummy = max(sCoord[tempIndex], maxTemp, subscript_min=minTemp)

            bPoints[            a] = tempIndex[minTemp]
            bPoints[2*dim - 1 - a] = tempIndex[maxTemp]

        endif

    endfor

        ; Remove any remaining -1 values

    bPoints = bPoints[where(bPoints ne -1)]

endif else begin

        ; Determine number of points in the file.  Boundary points will be determined by
        ; breaking data into subsets.  Determine how many subsets are needed.

    nPoints = n_elements(x)
    nHull   = ceil(nPoints / 1e6)

        ; Iterate the process through all of the subsets

    for a=0L,nHull-1 do begin

            ; Determine the starting and ending indices for each subset, using 1e6 points
            ; per subset

        hullStart = long(1e6 *  a)
        hullEnd   = long(1e6 * (a+1)) < nPoints

            ; Determine and record the boundary points for each subset

        qhull, x[hullStart:hullEnd-1], y[hullStart:hullEnd-1], hullPairs

        if a eq 0 then hullPoints = long(reform(hullPairs[0,*])) $
                  else hullPoints = [hullPoints, reform(hullPairs[0,*]) + hullStart]

    endfor

        ; Determine the points which bound the entire set of subset boundaries.

    qhull, x[hullPoints], y[hullPoints], bPairs

    bPairs  = hullPoints[bPairs]
    nBounds = size(bPairs, /dim)

        ; The boundary points are ordered

    bTemp1 = reform(bPairs[0,*])
    bTemp2 = reform(bPairs[1,*])

    bPoints    = lonarr(nBounds[1])
    bPoints[0] = bPairs[0,0]

    for b=1,nBounds[1]-1 do bPoints[b] = bTemp2[where(bTemp1 eq bPoints[b-1])]

endelse

    ; Close the set of boundary points

bPoints = [bPoints,bPoints[0]]

return, bPoints

end

