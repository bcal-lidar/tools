;+
; NAME:
;
;       GetIndex_BCAL
;
; PURPOSE:
;
;       This function is used for "index chunking", in combination with the output of
;       the REVERSE_INDICES keyword of the HISTOGRAM function.  For a given array element
;       and search radius, the function returns all indices within those elements.
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
;       index = GetIndex_BCAL(I,J,xDim,yDim,ArrayIndex,Factor)
;
;       I and J are the coordinates within the array, xDim and yDim are the dimensions of
;       the array, ArrayIndex is the output of the REVERSE_INDICES keyword of the HISTOGRAM
;       function, and Factor is the search radius.  (Factor = 0 searches the single element,
;       Factor = 1 searches the nine-element neighborhood, and so on.)
;
; RETURN VALUE:
;
;       The function returns the indices corresponding to the specified element and the
;       elements within the radius specified by the value of Factor.
;
;       If no indices are found, the function returns a value of -1.
;
; KNOWN ISSUES:
;
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
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

function GetIndex_BCAL, i, j, xDim, yDim, arrayIndex, factor

compile_opt idl2, logical_predicate

    ; Convert the two-dimensional array coordinates to a one-dimensional coordinate.

k = j * xDim + i

    ; Set initial return value

index = -1

if ((factor eq 0) and (arrayIndex[k] ne arrayIndex[k+1])) then $

        ; If no expansion is needed, simply get the indices

    index = arrayIndex[arrayIndex[k]:arrayIndex[k+1]-1] $

else begin

    doInd = 0

        ; If an expansion is needed, get the expanded coordinates.

    iStart = (i - factor) > 0
    iEnd   = (i + factor) < (xDim - 1)
    iEnd  += 1

    jStart = (j - factor) > 0
    jEnd   = (j + factor) < (yDim - 1)

        ; Convert the 2D coordiates to 1D coordinates.

    jRange = jEnd - jStart
    kStart = (jStart + lindgen(jRange + 1)) * xDim

    kEnd   = kStart + iEnd
    kStart = kStart + iStart

    for a=0,jRange do begin

            ; If they exist, get all the corresponding indices.

        if arrayIndex[kStart[a]] ne arrayIndex[kEnd[a]] then begin

            index = [index,arrayIndex[arrayIndex[kStart[a]]:arrayIndex[kEnd[a]]-1]]
            doInd = 1

        endif

    endfor

        ; If indices were found, remove the first, '-1' element.

    if doInd then index = index[1:*]

endelse

return, index

end