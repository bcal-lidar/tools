;+
; NAME:
;
;       ReadHeaderLAS_BCAL
;
; PURPOSE:
;
;       This program reads the header from the specified .las file.
;
;       For more information on the .las lidar data format, see http://www.lasformat.org
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
;       ReadHeaderLAS, inputFile, header
;
;       InputFile is the name of the requested .las file.
;
; RETURN VALUE:
;
;       The program returns a structure containing the header information from the
;       specified .las file.
;
; KNOWN ISSUES:
;
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
;       Changed CLOSE command to FREE_LUN, April 2006 (DRS)
;       Replaced by NODATA keyword in ReadLAS_BCAL.pro, June 2007
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

pro ReadHeaderLAS_BCAL, inputFile, header

compile_opt idl2, logical_predicate

    ; Create the header structure

header = InitHeaderLAS_BCAL()

    ; Open the file and read the header from it

openr, inputLun, inputFile, /get_lun, /swap_if_big_endian
readu, inputLun, header
free_lun, inputLun



end