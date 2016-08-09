;+
; NAME:
;
;       GetUniqLAS_BCAL
;
; PURPOSE:
;
;       This function is used to remove points in the LAS file that have same 
;       coordinates.
;
; AUTHOR:
;
;       David Streutker
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://bcal.geology.isu.edu
;
; CALLING SEQUENCE:
;
;       index = GetUniqLAS_BCAL(header, data)
;
;       'header' are the LAS file header obtained using ReadHeaderLAS_BCAL, and 'data' 
;       are LAS file data obtained by ReadLAS_BCAL procedures. 
;
; RETURN VALUE:
;
;       The function returns the LAS header and data for points with only unique
;       coordinates 
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
; Copyright @ 2006 David Streutker, Idaho State University.
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

pro GetUniqLAS_BCAL, header, data

compile_opt idl2, logical_predicate

xMax = max(data.east,  min=xMin)
yMax = max(data.north, min=yMin)
zMin = min(data.elev)

eastRange  = ulong64(xMax - xMin)
northRange = ulong64(yMax - yMin)

uniqCoords = eastRange * northRange * (data.elev  - zMin) $
           + eastRange *              (data.north - yMin) $
           +                          (data.east  - xMin)

uniqCoords = uniq(uniqCoords, sort(uniqCoords))

nUniq = n_elements(uniqCoords)

if nUniq ne header.nPoints then begin

    data = data[uniqCoords]

    header.nPoints = nUniq

endif


end