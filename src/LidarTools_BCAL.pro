;+
; NAME:
;
;       LidarTools_BCAL
;
; PURPOSE:
;
;       The purpose of this program is create menu system in ENVI
;
; PRODUCTS:
;
;
; AUTHOR:
;
;       Rupesh Shrestha
;       Boise Center Aerospace Laboratory
;       Idaho State University
;       322 E. Front St., Ste. 240
;       Boise, ID  83702
;       http://bcal.geology.isu.edu/
;
; DEPENDENCIES:
;
;
; MODIFICATION HISTORY:
;
;       Written by Rupesh Shrestha, April 2010.
;
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright @ 2010 Rupesh Shrestha, Idaho State University.
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
    
pro LidarTools_BCAL_define_buttons, buttonInfo

compile_opt idl2

    ; Main 'BCAL LiDAR' Menu
    
envi_define_menu_button, buttonInfo, value='BCAL LiDAR', /menu, ref_value='Topographic', $
    /sibling, position='after'

    ; LAS File Menu
    
envi_define_menu_button, buttonInfo, value='LAS File', /menu, ref_value='BCAL LiDAR', $
    position=0, separator=-1
    
   ; LAS File Info
   
envi_define_menu_button, buttonInfo, value='Get LAS Header Info', event_pro='FileInfoLAS_BCAL', $
    position= 0, ref_value='LAS File', uvalue='info'
    
envi_define_menu_button, buttonInfo, value='Get LAS Data Info', /menu, $
    position= 1, ref_value='LAS File', separator=-1
    
    envi_define_menu_button, buttonInfo, value='Single File', event_pro='DataInfoLAS_BCAL', $
        position= 1, ref_value='Get LAS Data Info', uvalue='DataInfoSingle'
    
    envi_define_menu_button, buttonInfo, value='Multiple Files', event_pro='DataInfoBatchLAS_BCAL', $
        position= 2, ref_value='Get LAS Data Info', separator=-1, uvalue='DataInfoMulti'
    
    ; LAS Projection
    
envi_define_menu_button, buttonInfo, value='Add Projection to LAS File(s)', event_pro='AddProjectionLAS_BCAL', $
    position= 3, ref_value='LAS File', uvalue='addProject'

envi_define_menu_button, buttonInfo, value='Reproject LAS File(s)', event_pro='ReprojectLAS_BCAL', $
    position= 4, separator=-1, ref_value='LAS File', uvalue='reproject'
  
    ; LAS Conversion

envi_define_menu_button, buttonInfo, value='Convert ASCII Data to LAS', event_pro='AsciiToLAS_BCAL', $
    position= 5, ref_value='LAS File', uvalue='ascii'

envi_define_menu_button, buttonInfo, value='Convert LAS Data to ASCII', event_pro='LASToAscii_BCAL', $
    position= 6, separator=-1, ref_value='LAS File', uvalue='lasascii'
    
   ; LAS Boundary
     
envi_define_menu_button, buttonInfo, value='Create Boundary EVF/SHP/KML', event_pro='BoundLAS_BCAL', $
    position=7, separator=-1, ref_value='LAS File', uvalue='bound'
    
    ; LAS Buffer/Tile

envi_define_menu_button, buttonInfo, value='Buffer LAS Files', event_pro='BufferLAS_BCAL', $
    position= 8, ref_value='LAS File', uvalue='buffer'

envi_define_menu_button, buttonInfo, value='Tile LAS File(s)', event_pro='TileLAS_BCAL', $
    position= 9, ref_value='LAS File', uvalue='tile', separator=-1
    

    ; LAS Decimate/Subset
    
envi_define_menu_button, buttonInfo, value='Decimate LAS File(s)', /menu, $
    position= 10, ref_value='LAS File'

    envi_define_menu_button, buttonInfo, value='Decimate by Number', event_pro='DecimateLAS_BCAL', $
        ref_value='Decimate LAS File(s)', uvalue='decimateNo'
        
    envi_define_menu_button, buttonInfo, value='Decimate by Percent', event_pro='DecimateLASper_BCAL', $
        ref_value='Decimate LAS File(s)', uvalue='decimatePer'
        
    ; LAS Subset/Export

envi_define_menu_button, buttonInfo, value='Subset LAS File(s)', /menu, $
    position= 11, ref_value='LAS File'

    envi_define_menu_button, buttonInfo, value='Subset via Coordinates', event_pro='SubsetLAS_BCAL', $
        ref_value='Subset LAS File(s)', uvalue='subsetCoords'
    
    envi_define_menu_button, buttonInfo, value='Subset via Image/ROI', event_pro='SubsetLAS_BCAL', $
        ref_value='Subset LAS File(s)', uvalue='subsetROI'

envi_define_menu_button, buttonInfo, value='Export LAS File(s)', /menu, $
    position= 12, ref_value='LAS File', separator=-1

    envi_define_menu_button, buttonInfo, value='Export by returns', event_pro='ExportLAS_BCAL', $
        ref_value='Export LAS File(s)', uvalue='exportReturn'
    
    envi_define_menu_button, buttonInfo, value='Export by number of returns', event_pro='ExportLAS_BCAL', $
        ref_value='Export LAS File(s)', uvalue='exportReturnNo'
    
    envi_define_menu_button, buttonInfo, value='Export by classification', event_pro='ExportLAS_BCAL', $
        ref_value='Export LAS File(s)', uvalue='exportClass'
    
    envi_define_menu_button, buttonInfo, value='Export by elevation', event_pro='ExportLAS_BCAL', $
        ref_value='Export LAS File(s)', uvalue='exportElev'
    
    envi_define_menu_button, buttonInfo, value='Export by intensity', event_pro='ExportLAS_BCAL', $
        ref_value='Export LAS File(s)', uvalue='exportInten'
        
    envi_define_menu_button, buttonInfo, value='Export by scan angle', event_pro='ExportLAS_BCAL', $
        ref_value='Export LAS File(s)', uvalue='exportScan'

    ; LAS Assign RGB
    
envi_define_menu_button, buttonInfo, value='Assign RGB Channel Data (LAS 1.2)', /menu, $
    position= 13, ref_value='LAS File', separator=-1
    
    envi_define_menu_button, buttonInfo, value='From orthoimagery', event_pro='AssignColorLAS_BCAL', $
        ref_value='Assign RGB Channel Data (LAS 1.2)', uvalue='RGBLasOrtho'
    
    envi_define_menu_button, buttonInfo, value='From elevation', event_pro='AssignColorLAS_BCAL', $
        ref_value='Assign RGB Channel Data (LAS 1.2)', uvalue='RGBLasElev'
    
    envi_define_menu_button, buttonInfo, value='From vegetation height', event_pro='AssignColorLAS_BCAL', $
        ref_value='Assign RGB Channel Data (LAS 1.2)', uvalue='RGBLasVegHt'
    
   ; LAS Extract Flight Lines

envi_define_menu_button, buttonInfo, value='Extract flight lines from LAS file(s)', event_pro='FlightlineLAS_BCAL', $
    position=14, ref_value='LAS File', uvalue='FlightlineLAS'
          
    ; Main Menu

envi_define_menu_button, buttonInfo, value='Perform Height Filtering', event_pro='HeightLAS_BCAL', $
    position=2, ref_value='BCAL LiDAR', uvalue='height'

envi_define_menu_button, buttonInfo, value='Create Bare-earth DEM', event_pro='DEMLAS_BCAL', $
    position=3, ref_value='BCAL LiDAR', separator=-1, uvalue='raster'

    ; Metrics

envi_define_menu_button, buttonInfo, value='Create Raster Products', /menu, ref_value='BCAL LiDAR', $
    position=5
    
    envi_define_menu_button, buttonInfo, VALUE='Topographic Products (Bare-earth)', event_pro = 'TopoRasterBare_BCAL', $
        position=1, ref_value='Create Raster Products', UVALUE='tbmetric'
        
    envi_define_menu_button, buttonInfo, VALUE='Topographic Products (All returns)', event_pro = 'TopoRasterAll_BCAL', $
        position=2, ref_value='Create Raster Products', UVALUE='tametric'
        
    envi_define_menu_button, buttonInfo, VALUE='Vegetation Products', event_pro = 'VegMetrics_BCAL', $
        position=3, ref_value='Create Raster Products', UVALUE='vmetric'
    
    envi_define_menu_button, buttonInfo, VALUE='Intensity Products', event_pro = 'IntensityMetrics_BCAL', $
        position=4, ref_value='Create Raster Products', UVALUE='imetric', separator=-1
    
    envi_define_menu_button, buttonInfo, VALUE='Prepare LAS file(s)', event_pro = 'PrepareLAS_BCAL', $
        position=5, ref_value='Create Raster Products', UVALUE='imetric'

envi_define_menu_button, buttonInfo, value='Create Raster Layer (legacy)', event_pro='LidarRasterLAS_BCAL', $
    position=6, separator=-1, ref_value='BCAL LiDAR', uvalue='raster_legacy'

envi_define_menu_button, buttonInfo, value='Create Vegetation Height Groups', event_pro='HeightGroupsLAS_BCAL', $
    position=7, ref_value='BCAL LiDAR', uvalue='heightgroups'

envi_define_menu_button, buttonInfo, value='Create Elevation Profile(s)', event_pro='TransectLAS_BCAL', $
    position=10, ref_value='BCAL LiDAR', separator=-1, uvalue='transect'
    
envi_define_menu_button, buttonInfo, value='3D Lidar Viewer', event_pro='Visualize3D_BCAL', $
    position=12, ref_value='BCAL LiDAR', separator=-1, uvalue='visualize'
       
    ; Help Menu
    
envi_define_menu_button, buttonInfo, value='Help', /menu, ref_value='BCAL LiDAR', $
   position=last, separator=-1
   
    envi_define_menu_button, buttonInfo, value='Start Help', EVENT_PRO = 'LiDARToolsHelp_BCAL', $
       ref_value='Help', uvalue='LiDARToolsHelp'
    
    envi_define_menu_button, buttonInfo, value='About BCAL LiDAR Tools', EVENT_PRO = 'LiDARToolsHelp_BCAL', $
       ref_value='Help', position=last, uvalue='AboutLiDARTools'
   
end

  ; main program

pro LidarTools_BCAL, event 

end