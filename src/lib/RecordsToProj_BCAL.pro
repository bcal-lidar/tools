;+
; NAME:
;
;       RecordsToProj_BCAL
;
; PURPOSE:
;
;       The purpose of this function is to convert from geographic information contained in an LAS
;       file's variable length records to a standard ENVI projection structure, or vice-versa.  The
;       variable length records use the GeoTiff standard for tags and keys.  See www.lasformat.org
;       and www.remotesensing.org/geotiff/geotiff.html for more information regarding the specifications.
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
;       projection = RecordsToProj_BCAL(records, reverse=reverse)
;
;       Records are a structure or array of structures containing the variable length records
;       of an LAS file.
;
; RETURN VALUE:
;
;       The function returns a standard ENVI projection structure corresponding to the
;       geographic parameters contained in the variable length records.  If no geographic
;       parameters are found, the function returns a value of -1.
;
;       Set the REVERSE keyword to return an array of variable length records corresponding to
;       a given ENVI projection structure, i.e.:
;
;           records = RecordsToProj(projection, /reverse)
;
;       Again, if no geographic parameters are found, the function returns a value of -1.
; DEPENDENCIES:
;
;       InitRecordLAS_BCAL
;       
; MODIFICATION HISTORY:
;
;       Written by David Streutker, June 2007.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright � 2007 David Streutker, Idaho State University.
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


    ; Begin main program

function RecordsToProj_BCAL, input, reverse=reverse

compile_opt idl2, logical_predicate

    ; A temporary GeoTiff file will be created to convert between geotiff tags and
    ; ENVI projections.

tempFile = getenv('IDL_TMPDIR') + 'tempGeoTiff.tif'

    ; Initialize a GeoTiff keys structure

geoTiff = { $

        ; tags

    MODELPIXELSCALETAG              : double([1,1,1]), $
    MODELTRANSFORMATIONTAG          : dblarr(4,4),     $
    MODELTIEPOINTTAG                : dblarr(6,1),     $

        ; configuration geokeys

    GTMODELTYPEGEOKEY               : 0,    $
    GTRASTERTYPEGEOKEY              : 0,    $
    GTCITATIONGEOKEY                : '',   $

        ; geographic parameter geokeys

    GEOGRAPHICTYPEGEOKEY            : 0,    $
    GEOGCITATIONGEOKEY              : '',   $
    GEOGGEODETICDATUMGEOKEY         : 0,    $
    GEOGPRIMEMERIDIANGEOKEY         : 0,    $
    GEOGLINEARUNITSGEOKEY           : 0,    $
    GEOGLINEARUNITSIZEGEOKEY        : 0D,   $
    GEOGANGULARUNITSGEOKEY          : 0,    $
    GEOGANGULARUNITSIZEGEOKEY       : 0D,   $
    GEOGELLIPSOIDGEOKEY             : 0,    $
    GEOGSEMIMAJORAXISGEOKEY         : 0D,   $
    GEOGSEMIMINORAXISGEOKEY         : 0D,   $
    GEOGINVFLATTENINGGEOKEY         : 0D,   $
    GEOGAZIMUTHUNITSGEOKEY          : 0,    $
    GEOGPRIMEMERIDIANLONGGEOKEY     : 0D,   $
    PROJECTEDCSTYPEGEOKEY           : 0,    $
    PCSCITATIONGEOKEY               : '',   $

        ; projection definition geokeys

    PROJECTIONGEOKEY                : 0,    $
    PROJCOORDTRANSGEOKEY            : 0,    $
    PROJLINEARUNITSGEOKEY           : 0,    $
    PROJLINEARUNITSIZEGEOKEY        : 0D,   $
    PROJSTDPARALLEL1GEOKEY          : 0D,   $
    PROJSTDPARALLEL2GEOKEY          : 0D,   $
    PROJNATORIGINLONGGEOKEY         : 0D,   $
    PROJNATORIGINLATGEOKEY          : 0D,   $
    PROJFALSEEASTINGGEOKEY          : 0D,   $
    PROJFALSENORTHINGGEOKEY         : 0D,   $
    PROJFALSEORIGINLONGGEOKEY       : 0D,   $
    PROJFALSEORIGINLATGEOKEY        : 0D,   $
    PROJFALSEORIGINEASTINGGEOKEY    : 0D,   $
    PROJFALSEORIGINNORTHINGGEOKEY   : 0D,   $
    PROJCENTERLONGGEOKEY            : 0D,   $
    PROJCENTERLATGEOKEY             : 0D,   $
    PROJCENTEREASTINGGEOKEY         : 0D,   $
    PROJCENTERNORTHINGGEOKEY        : 0D,   $
    PROJSCALEATNATORIGINGEOKEY      : 0D,   $
    PROJSCALEATCENTERGEOKEY         : 0D,   $
    PROJAZIMUTHANGLEGEOKEY          : 0D,   $
    PROJSTRAIGHTVERTPOLELONGGEOKEY  : 0D,   $

        ; vertical parameter geokeys

    VERTICALCSTYPEGEOKEY            : 0,    $
    VERTICALCITATIONGEOKEY          : '',   $
    VERTICALDATUMGEOKEY             : 0,    $
    VERTICALUNITSGEOKEY             : 0     $

}

    ; Define the geoKey IDs

keyIDs = [33550, $
          34264, $
          33922, $
          1024,  $
          1025,  $
          1026,  $
          2048,  $
          2049,  $
          2050,  $
          2051,  $
          2052,  $
          2053,  $
          2054,  $
          2055,  $
          2056,  $
          2057,  $
          2058,  $
          2059,  $
          2060,  $
          2061,  $
          3072,  $
          3073,  $
          3074,  $
          3075,  $
          3076,  $
          3077,  $
          3078,  $
          3079,  $
          3080,  $
          3081,  $
          3082,  $
          3083,  $
          3084,  $
          3085,  $
          3086,  $
          3087,  $
          3088,  $
          3089,  $
          3090,  $
          3091,  $
          3092,  $
          3093,  $
          3094,  $
          3095,  $
          4096,  $
          4097,  $
          4098,  $
          4099]

geoTagNames = tag_names(geoTiff)

    ; Initialize individual LAS GeoTiff keys

geoKeys = {                                $
            keyDirectoryVersion     : 1US, $
            keyRevision             : 1US, $
            minorRevision           : 0US, $
            numberOfKeys            : 0US  $
          }

tempKey = {                    $
            keyID       : 0US, $
            location    : 0US, $
            count       : 1US, $
            value       : 0US  $
          }

    ; If requested, convert from projection to variable length records

if keyword_set(reverse) then begin

    proj = input

    records = -1

        ; Save a temporary, "dummy" image with the given projection as an ENVI file

    mapInfo  = envi_map_info_create(proj=proj, ps=[1,1], mc=[1,1,10,10])
    envi_write_envi_file, dist(256), r_fid=tempId, nb=1, nl=256, ns=256, map_info=mapInfo, $
        /no_copy, /no_open, data_type=4, interleave=0, /in_memory, /no_realize
    envi_file_query, tempId, data_type=data_type, dims=dims, interleave=interleave, nb=nb

        ; Convert the temporary ENVI file to a temporary GeoTiff file

    envi_output_to_external_format, fid=tempID, dims=dims, pos=bindgen(nb), out_name=tempFile, /tiff
    envi_file_mng, id=tempId, /remove

        ; Query the temporary tiff to get the projection information in a GeoTiff structure.
        ; Delete the temporary files.

    dummy = query_tiff(tempFile, geotiff=inpTags)
    file_delete, [tempFile, file_dirname(tempFile) + '\' + file_basename(tempFile,'.tif') + '.tfw']

        ; Create the records from the GeoTiff structure

    tagNames = tag_names(inpTags)

    dStart = 0
    aStart = 0

    for m=0,n_tags(inpTags)-1 do begin

            ; Search the GeoTiff tag structure for matching names.  When found, save the
            ; corresponding key ID and value to a record.

        tagIndex = where(geoTagNames eq tagNames[m])
        if tagIndex[0] then begin

                ; How the value is recorded depends on its type

            tempValue = (inpTags.(m))[0]

            keyEntry = tempKey

            keyEntry.keyID = keyIDs[tagIndex]

            case size(tempValue,/type) of

                2 : keyEntry.value = tempValue          ; integer

                5 : begin                               ; double

                        keyEntry.location = 34736
                        keyEntry.value    = dStart

                        if dStart then doubleParams = [doubleParams,tempValue] $
                                  else doubleParams = tempValue

                        dStart += 1

                    end

                7 : begin                               ; string

                        keyEntry.location = 34737
                        keyEntry.count    = strlen(tempValue)
                        keyEntry.value    = aStart

                        if aStart then asciiParams = asciiParams + tempValue $
                                  else asciiParams = tempValue

                        aStart += strlen(tempValue)

                    end

                else:

            endcase

            if n_tags(keys) eq 0 then keys = keyEntry else keys = [keys,keyEntry]

            geoKeys.numberOfKeys++

        endif

    endfor

        ; Create the GeoKeyDirectory Tag Record

    if n_tags(keys) then begin

        keys = [geoKeys,keys]

        dataTemp = uintarr(4,geoKeys.numberOfKeys+1)
        nData    = n_elements(dataTemp)

        for n=0,3                    do begin
        for p=0,geoKeys.numberOfKeys do begin

            dataTemp[n,p] = keys[p].(n)

        endfor
        endfor

        records = InitRecordLAS_BCAL()

        records.userID       = byte('LASF_Projection')
        records.recordID     = 34735
        records.recordLength = 2 * nData
        records.description  = byte('GeoKeyDirectoryTag')
       *records.data         = reform(dataTemp,nData)

    endif

        ; Create the GeoDoubleParams Tag Record

    if dStart then begin

        dRecord = InitRecordLAS_BCAL()

        dRecord.userID       = byte('LASF_Projection')
        dRecord.recordID     = 34736
        dRecord.recordLength = 8 * n_elements(doubleParams)
        dRecord.description  = byte('GeoKeyDoubleParamsTag')
       *dRecord.data         = doubleParams

        records = [records, dRecord]

    endif

        ; Create the GeoAsciiParams Tag Record

    if aStart then begin

        aRecord = InitRecordLAS_BCAL()

        aRecord.userID       = byte('LASF_Projection')
        aRecord.recordID     = 34737
        aRecord.recordLength = strlen(asciiParams)
        aRecord.description  = byte('GeoASCIIParamsTag')
       *aRecord.data         = asciiParams

        records = [records, aRecord]

    endif

        ; Return the resulting records.

    return, records

endif else begin

        ; Convert the records to a projection

    records = input

        ; Iterate through the records, looking for GeoTiff tags

    for a=0,n_elements(records)-1 do begin

        case records[a].recordID of

                ; GeoKey Directory Tag

            34735 : begin

                for b=0,3 do geoKeys.(b) = uint((*records[a].data), 2*b)

                keyList = replicate(tempKey, geoKeys.numberOfKeys)

                for c=0,geoKeys.numberOfKeys-1 do begin

                    for d=0,3 do keyList[c].(d) = uint((*records[a].data), 2*(4 + 4*c + d))

                endfor

            end

                ; GeoDoubleParams Tag

            34736 : doubleParams = double((*records[a].data), 0, records[a].recordLength/8)

                ; GeoAsciiParams Tag

            34737 : asciiParams = *records[a].data

            else:

        endcase

    endfor

        ; If they exist, iterate through the GeoKeys, reading the codes and updating the geotiff structure

    if geoKeys.numberOfKeys then begin

        for s=0,geoKeys.numberOfKeys-1 do begin

            keyIndex = where(keyIDs eq keyList[s].keyID)

            if keyIndex ne -1 then begin

                vStart = keyList[s].value
                vEnd   = keyList[s].value + (keyList[s].count > 1) - 1

                case keyList[s].location of

                    0     : geoTiff.(keyIndex[0]) = keyList[s].value
                    34736 : geoTiff.(keyIndex[0]) = doubleParams[vStart:vEnd]
                    34737 : geoTiff.(keyIndex[0]) = string(asciiParams[vStart:vEnd])
                    else  :

                endcase

            endif

        endfor

            ; Save a temporary "dummy" geotiff image with the updated geokey structure

        write_tiff, tempFile, bytarr(128,128), geotiff=geotiff

            ; Query the temporary tiff to get the projection information in an ENVI projection structure

        envi_open_file, tempFile, r_fid=tempId, /no_realize
        proj = envi_get_projection(fid=tempId)
        envi_file_mng, id=tempId, /remove, /delete

    endif else proj = -1

        ; Return the resulting projection structure

    return, proj

endelse


end