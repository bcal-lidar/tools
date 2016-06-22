;+
; NAME:
;
;       InitHeaderLAS_BCAL
;
; PURPOSE:
;
;       This function initializes a structure to read the header of a .las
;       lidar file.
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
;       header = InitHeaderLAS_BCAL()
;
; RETURN VALUE:
;
;       The function returns a structure corresponding to the header of a .las file.
;
; KNOWN ISSUES:
;
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, March 2006.
;       Converted from a procedure to a function, July 2007
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

function InitHeaderLAS_BCAL

compile_opt idl2, logical_predicate

    ; Define the public header structure

header = { $
    signature       : byte('LASF'), $               ; File signature
    fileSource      : 0US,  $                       ; File source ID
    reserved        : 0US,  $                       ; Reserved
    guid1           : 0UL, $                        ; Project ID - GUID data 1
    guid2           : 0US,  $                       ; Project ID - GUID data 2
    guid3           : 0US,  $                       ; Project ID - GUID data 3
    guid4           : bytarr(8), $                  ; Project ID - GUID data 4
    versionMajor    : 1B, $                         ; Version major
    versionMinor    : 1B, $                         ; Version minor
    systemID        : bytarr(32), $                 ; System identifier
    softwareID      : bytarr(32), $                 ; Generating software
    day             : 0US,    $                     ; File creation day of year
    year            : 0US,    $                     ; File creation year
    headerSize      : 227US,  $                     ; Header size
    dataOffset      : 227UL, $                      ; Offset to point data
    nRecords        : 0UL,   $                      ; Number of variable length records
    pointFormat     : 0B,    $                      ; Point data format ID
    pointLength     : 20US,   $                     ; Point data record length
    nPoints         : 0UL,   $                      ; Number of point records
    nReturns        : ulonarr(5), $                 ; Number of points by return
    xScale          : 0D, $                         ; X scale factor
    yScale          : 0D, $                         ; Y scale factor
    zScale          : 0D, $                         ; Z scale factor
    xOffset         : 0D, $                         ; X offset
    yOffset         : 0D, $                         ; Y offset
    zOffset         : 0D, $                         ; Z offset
    xMax            : 0D, $                         ; Max X
    xMin            : 0D, $                         ; Min X
    yMax            : 0D, $                         ; Max Y
    yMin            : 0D, $                         ; Min Y
    zMax            : 0D, $                         ; Max Z
    zMin            : 0D  $                         ; Min Z
}

    ; Set the software ID

header.softwareID = byte('LidarTools, IDL ' + !version.release)

    ; Set the creation date

date = bin_date(systime(/utc))
day  = julday(date[1],date[2],date[0]) - julday(1,1,date[0]) + 1
header.day  = uint(day)
header.year = uint(date[0])

return, header

end