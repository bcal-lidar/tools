
pro LidarTools_BCAL_define_buttons, buttonInfo

compile_opt idl2

    ; Main 'BCAL LiDAR' Menu
    
envi_define_menu_button, buttonInfo, value='BCAL LiDAR', /menu, ref_value='Topographic', $
    /sibling, position='after'

    ; 0. LAS File Menu
    
envi_define_menu_button, buttonInfo, value='LAS File', /menu, ref_value='BCAL LiDAR', $
    position=0, separator=-1
    
envi_define_menu_button, buttonInfo, value='Get LAS File Info', event_pro='FileInfoLAS_BCAL', $
    position= 0, ref_value='LAS File', separator=-1, uvalue='info'
    
envi_define_menu_button, buttonInfo, value='Add Projection to LAS File(s)', event_pro='AddProjectionLAS_BCAL', $
    position= 1, ref_value='LAS File', uvalue='addProject'

envi_define_menu_button, buttonInfo, value='Reproject LAS File(s)', event_pro='ReprojectLAS_BCAL', $
    position= 2, separator=-1, ref_value='LAS File', uvalue='reproject'
  
envi_define_menu_button, buttonInfo, value='Convert Ascii Data to LAS', event_pro='AsciiToLAS_BCAL', $
    position= 3, ref_value='LAS File', uvalue='ascii'

envi_define_menu_button, buttonInfo, value='Convert LAS Data to ASCII', event_pro='LAS2ASCII_BCAL', $
    position= 4, separator=-1, ref_value='LAS File', uvalue='lasascii'
    
envi_define_menu_button, buttonInfo, value='Buffer LAS Files', event_pro='BufferLAS_BCAL', $
    position= 5, ref_value='LAS File', uvalue='buffer'

envi_define_menu_button, buttonInfo, value='Tile LAS File(s)', event_pro='TileLAS_BCAL', $
    position= 6, ref_value='LAS File', uvalue='tile'
    
envi_define_menu_button, buttonInfo, value='Decimate LAS File(s)', event_pro='DecimateLAS_BCAL', $
    position= 7, ref_value='LAS File', uvalue='decimate', separator=-1

envi_define_menu_button, buttonInfo, value='Subset LAS File(s)', /menu, $
    position= 8, ref_value='LAS File'

envi_define_menu_button, buttonInfo, value='Subset via Coordinates', event_pro='SubsetLAS_BCAL', $
    ref_value='Subset LAS File(s)', uvalue='subsetCoords'

envi_define_menu_button, buttonInfo, value='Subset via Image/ROI', event_pro='SubsetLAS_BCAL', $
    ref_value='Subset LAS File(s)', uvalue='subsetROI'
    
      
    ; Main Menu

envi_define_menu_button, buttonInfo, value='Perform Height Filtering', event_pro='HeightLAS_BCAL', $
    position=2, ref_value='BCAL LiDAR', uvalue='height'

envi_define_menu_button, buttonInfo, value='Rasterize Lidar Data', event_pro='LidarRasterLAS_BCAL', $
    position=3, separator=-1, ref_value='BCAL LiDAR', uvalue='raster'

envi_define_menu_button, buttonInfo, value='Create Boundary EVF/SHP/KML', event_pro='BoundLAS_BCAL', $
    position=5, ref_value='BCAL LiDAR', uvalue='bound'

envi_define_menu_button, buttonInfo, value='Create Elevation Profile(s)', event_pro='TransectLAS_BCAL', $
    position=6, ref_value='BCAL LiDAR', uvalue='transect'
      
envi_define_menu_button, buttonInfo, value='Export Ground Points Only (LAS)', event_pro='GroundPointsLAS_BCAL', $
    position=8, ref_value='BCAL LiDAR', separator=-1, uvalue='groundonly' 
  
envi_define_menu_button, buttonInfo, value='3D Lidar Viewer', event_pro='Visualize3D_BCAL', $
    position=10, ref_value='BCAL LiDAR', separator=-1, uvalue='visualize'

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