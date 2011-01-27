;+
; NAME:
;
;       BoundLAS_BCAL
;
; PURPOSE:
;
;       The purpose of this program is to create an EVF file which shows the boundary
;       the lidar data set or sets input by the user.  Input files are expected in
;       LAS format.
;
; PRODUCTS:
;
;       The output are an EVF file showing the boundary and a DBF which contains
;       attributes for the boundary file.  When multiple lidar data files are input,
;       the boundaries of each individual input file are contained in the EVF file.  The
;       attributes contained in the DBF file include the name of the corresponding lidar
;       file, the number of points it contains, and the point density (in meters) of the
;       data.  The DBF file is saved with the same root name as the EVF file.
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
; DEPENDENCIES:
;
;       ReadLAS_BCAL.pro
;       GetBounds_BCAL.pro
;
; KNOWN ISSUES:
;
;       When creating the associated DBF file, will overwrite any existing file
;       of the same name without warning.
;
; MODIFICATION HISTORY:
;
;       Written by David Streutker, April 2006.
;       Added individual return point counts to DBF file, May 2006
;       Added status window, August 2006
;       Added support for embedded projections, June 2007
;       Added ability to export all 5 returns from LAS file and minor fixes, April 2010 (Rupesh Shrestha)
;       Added ability to export to ArcGIS shapefile and KML file, April 2010 (Rupesh Shrestha)
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


    ; Begin main program
pro BoundLAS_BCAL, event

compile_opt idl2, logical_predicate

    ; Establish error handler.  The most likely problem is that the user will open a data
    ; file that is too large to process.
  
catch, theError
if theError ne 0 then begin
    catch, /cancel
    help, /last_message, output=errText
    errMsg = dialog_message(errText, /error, title='Error processing request')
    return
endif

    ; Get the input file(s)

inputFiles = dialog_pickfile(title='Select LAS file(s)', filter='*.las', /fix_filter, /must_exist, /multiple)
if (inputFiles[0] eq '') then return

    ; Establish default name and projection for the EVF file

nFiles = n_elements(inputFiles)
if nFiles eq 1 then defName = file_basename(inputFiles[0], 'las') + 'evf' $
               else defName = 'Boundary.evf'

ReadLAS_BCAL, inputFiles[0], header, projection=defProj, /nodata
if n_tags(defProj) eq 0 then defProj = envi_proj_create(/utm, datum='WGS-84', zone=12)

    ; Query the user for the projection and name of the output file

outBase = widget_auto_base(title='Save EVF File')

    dummy = widget_map(outBase, default_map=[1,1], default_proj=defProj, uvalue='proj', /auto_manage)

    precBase = widget_base(outBase, /row)
    dummy = widget_param(precBase, default=1, dt=4, floor=0, prompt='Set precision length:', uvalue='prec', /auto)
    dummy = widget_outf(outBase, default=defName, prompt='Enter name of boundary EVF:', $
                        uvalue='evfName', /auto_manage)
    dummy = widget_menu(outBase, default_array=[1], list=['Export as shapefile'],   uvalue='shpfile',  /auto)                  
    dummy = widget_menu(outBase, default_array=[0], list=['Export as KML'],   uvalue='kmlfile',  /auto)
    
result = auto_wid_mng(outBase)

if (result.accept eq 0) then return
precision = result.prec
projInfo  = result.proj.proj
evfFile   = result.evfName
dbfFile   = file_basename(evfFile, '.evf') + '.dbf'

if (result.shpfile eq 1) then shpFile = file_basename(evfFile, '.evf') + '_shp'
if (result.kmlfile eq 1) then kmlFile = file_basename(evfFile, '.evf') + '.kml'

    ; Establish the layer name

if nFiles eq 1 then layerName = 'Boundary of ' + file_basename(inputFiles[0]) $
               else layerName = 'Boundary'

    ; Initialize the attribute structure for the DBF file

dbfAttributes = replicate({Name        : '', $
                           Points      : 0L, $
                           Density     : 0E, $
                           FirstPts : 0L, $
                           SecondPts: 0L, $
                           ThirdPts : 0L, $
                           FourthPts: 0L, $
                           FifthPts : 0L}, nFiles)

    ; Intitialize the EVF file

evfPtr = envi_evf_define_init(evfFile, data_type=5, layer_name=layerName, projection=projInfo)
if (ptr_valid(evfPtr) eq 0) then return

    ; Set up status message window

statText  = 'Initializing'
statBase  = widget_auto_base(title='Boundary Status')
statField = widget_text(statBase, /scroll, value=statText, xsize=80, ysize=4)
widget_control, statBase, /realize

    ; Convert to KML file 
    
if (result.kmlfile eq 1) then begin
 
    ; Create output KML file for writing
    
    openw,  kmlout, kmlFile, /get_lun
    printf, kmlout, '<?xml version="1.0" encoding="UTF-8"?>'
    printf, kmlout, '<kml xmlns="http://www.opengis.net/kml/2.2">'
    printf, kmlout, '<Document>'
    printf, kmlout, '<Style id="transBluePoly">'
    printf, kmlout, '<LineStyle>'
    printf, kmlout, '<width>1.5</width>'
    printf, kmlout, '</LineStyle>'  
    printf, kmlout, '<PolyStyle>'  
    printf, kmlout, '<color>7dff0000</color>' 
    printf, kmlout, '</PolyStyle>'   
    printf, kmlout, '</Style>' 
    
    ; define output coordinates
       
    oProj = envi_proj_create(/geographic)
    
endif

    ; Process each input file individually

for a=0, nFiles-1 do begin

        ; Update the status window

    statText = ['Bounding ' + inputFiles[a] + ' (' + strcompress(a+1,/remove) $
                                            + '/'  + strcompress(nFiles,/remove) + ')', statText]
    widget_control, statField, set_value=statText

        ; Read the input file and determine the boundary points, the overall area, and the number
        ; of returns

    ReadLAS_BCAL, inputFiles[a], header, data

;    bPoints  = GetBounds_BCAL(data.east, data.north)
    bPoints  = GetBounds_BCAL(data.east * header.xScale, data.north * header.yScale, precision=precision)
    bArea    = poly_area(data[bPoints].east  * header.xScale + header.xOffset, $
                         data[bPoints].north * header.yScale + header.yOffset)

    nReturns = histogram(data.nReturn mod 8, min=1, max=5)

        ; Record the boundary of each input file as a record in the EVF file

    envi_evf_define_add_record, evfPtr, transpose([[data[bPoints].east  * header.xScale + header.xOffset], $
                                                   [data[bPoints].north * header.yScale + header.yOffset]])
   
   
        ; Record the DBF attributes for the input file

    dbfAttributes[a].Name        = file_basename(inputFiles[a])
    dbfAttributes[a].Points      = header.nPoints
    dbfAttributes[a].Density     = header.nPoints / bArea
    dbfAttributes[a].FirstPts = nReturns[0]
    dbfAttributes[a].SecondPts = nReturns[1]
    dbfAttributes[a].ThirdPts  = nReturns[2]
    dbfAttributes[a].FourthPts  = nReturns[3]
    dbfAttributes[a].FifthPts  = nReturns[4]
    
        ; Process each record for KML file
        
    if (result.kmlfile eq 1) then begin

      xCoords = data[bPoints].east  * header.xScale + header.xOffset
      yCoords = data[bPoints].north * header.yScale + header.yOffset

        ; Convert the coordinates from UTM to lat/lon

      envi_convert_projection_coordinates, xCoords, yCoords, projInfo, xOut, yOut, oProj

      printf, kmlout, '<Placemark>'
      printf, kmlout, '<name>' + file_basename(inputFiles[a]) + '</name>'
      printf, kmlout, '<styleUrl>#transBluePoly</styleUrl>'
      printf, kmlout, '<MultiGeometry>'
      printf, kmlout, '<Polygon>'
      printf, kmlout, '<outerBoundaryIs>'
      printf, kmlout, '<LinearRing>'
      printf, kmlout, '<coordinates>'

      for j=0, n_elements(xOut)-1 do printf, $
        kmlout, strcompress(xOut[j], /remove) + ',' + strcompress(yOut[j], /remove)

      printf, kmlout, '</coordinates>'
      printf, kmlout, '</LinearRing>'
      printf, kmlout, '</outerBoundaryIs>'
      printf, kmlout, '</Polygon>'
      printf, kmlout, '</MultiGeometry>'
      printf, kmlout, '</Placemark>'
    
    endif
        
        ; Set data to 0 to clear up memory

    data = [0]

endfor

  ; Finish writing to KML file 
    
if (result.kmlfile eq 1) then begin
 
  printf, kmlout, '</Document>'
  printf, kmlout, '</kml>'
  close, kmlout
    
endif
    
    ; Write the corresponding DBF file

envi_write_dbf_file, dbfFile, dbfAttributes

    ; Get ID of the EVF file

evfID = envi_evf_define_close(evfPtr, /return_id)

    ; Convert to shapefile
    
if (result.shpfile eq 1) then envi_evf_to_shapefile, evfID, shpfile 

    ; Close the EVF file
    
envi_evf_close, evfID


    ; Destroy the status window

widget_control, statBase, /destroy


end
