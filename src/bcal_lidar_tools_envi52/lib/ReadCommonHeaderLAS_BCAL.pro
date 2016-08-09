;+
; NAME:
;
;       ReadCommonHeaderLAS
;
; PURPOSE:
;
;       This function initializes a structure to read some begining part in the header of a .las
;       lidar file, which is in a common format for versions 1.2 and up.
;
;       For more information on the .las lidar data format, see http://www.lasformat.org
;
; AUTHOR:
;
;       Exelis VIS
;
; CALLING SEQUENCE:
;
;       commonHeader = ReadCommonHeaderLAS(lasFile)
;
; RETURN VALUE:
;
;       The function returns a structure corresponding to items from File Signature to Header Size in the header of a .las file.
;
; KNOWN ISSUES:
;
;       None.
;
; MODIFICATION HISTORY:
;
;       Written by Exelis VIS, April, 2016.
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

function ReadCommonHeaderLAS_BCAL, inputFile

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
    headerSize      : 227US  $                     ; Header size
  }

    ; Open the file and read the common header parts from it

  openr, inputLun, inputFile, /get_lun, /swap_if_big_endian
  readu, inputLun, header
  free_lun, inputLun
  return, header

end