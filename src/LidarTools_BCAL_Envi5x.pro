; Add the extension to the toolbox. Called automatically on ENVI startup.
pro LidarTools_BCAL_Envi5x_extensions_init

  ; Set compile options
  compile_opt IDL2
  
  ; Get ENVI session
  e = ENVI(/CURRENT)
  
  ; Add the extension to a subfolder
  e.AddExtension, 'Get LAS Header Info', 'FileInfoLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='LASinfo'
  e.AddExtension, 'Single File', 'DataInfoLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Get LAS Data Info', uvalue='DataInfoSingle'
  e.AddExtension, 'Multiple Files', 'DataInfoBatchLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Get LAS Data Info', uvalue='DataInfoMulti'
  e.AddExtension, 'Add Projection to LAS File(s)', 'AddProjectionLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='addProject'
  e.AddExtension, 'Reproject LAS File(s)', 'ReprojectLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='reproject'
  e.AddExtension, 'Convert ASCII Data to LAS', 'AsciiToLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='asciiLAS'
  e.AddExtension, 'Convert LAS Data to ASCII, Shapefile', 'LASToAscii_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='lasascii'
  e.AddExtension, 'Create Boundary EVF, SHP, KML', 'BoundLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='boundLAS'
  e.AddExtension, 'Buffer LAS Files', 'BufferLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='bufferLAS'
  e.AddExtension, 'Tile LAS File(s)', 'TileLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='tileLAS'
  e.AddExtension, 'Reclassify LAS File(s)', 'ReclassifyLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='reclassLAS'
  e.AddExtension, 'Decimate by Number', 'DecimateLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Decimate LAS File(s)', uvalue='decimateNo'  
  e.AddExtension, 'Decimate by Percent', 'DecimateLASper_BCAL', PATH='BCAL LiDAR Tools/LAS File/Decimate LAS File(s)', uvalue='decimatePer'  
  e.AddExtension, 'Subset via Coordinates', 'SubsetLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Subset LAS File(s)', uvalue='subsetCoords'  
  e.AddExtension, 'Subset via Image or ROI', 'SubsetLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Subset LAS File(s)', uvalue='subsetROI'
  e.AddExtension, 'Export by returns', 'ExportLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Export LAS File(s)', uvalue='exportReturn'
  e.AddExtension, 'Export by number of returns', 'ExportLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Export LAS File(s)', uvalue='exportReturnNo'
  e.AddExtension, 'Export by classification', 'ExportLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Export LAS File(s)', uvalue='exportClass'
  e.AddExtension, 'Export by elevation', 'ExportLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Export LAS File(s)', uvalue='exportElev'
  e.AddExtension, 'Export by scan angle', 'ExportLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Export LAS File(s)', uvalue='exportScan'
  e.AddExtension, 'Export by intensity', 'ExportLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Export LAS File(s)', uvalue='exportInten'
  e.AddExtension, 'Assign from orthoimagery', 'AssignColorLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Assign RGB Data (LAS 1.2)', uvalue='RGBLasOrtho'
  e.AddExtension, 'Assign from elevation', 'AssignColorLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Assign RGB Data (LAS 1.2)', uvalue='RGBLasElev'
  e.AddExtension, 'Assign from vegetation height', 'AssignColorLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File/Assign RGB Data (LAS 1.2)', uvalue='RGBLasVegHt'
  e.AddExtension, 'Extract flight lines from LAS file(s)', 'FlightlineLAS_BCAL', PATH='BCAL LiDAR Tools/LAS File', uvalue='FlightlineLAS'
 
  e.AddExtension, 'Perform Height Filtering', 'HeightLAS_BCAL', PATH='BCAL LiDAR Tools', uvalue='height'
  e.AddExtension, 'Create Bare-earth DEM', 'DEMLAS_BCAL', PATH='BCAL LiDAR Tools', uvalue='raster'
  
  e.AddExtension, 'Topographic Products (Bare-earth)', 'TopoRasterBare_BCAL', PATH='BCAL LiDAR Tools/Create Raster Products', uvalue='tbmetric'
  e.AddExtension, 'Topographic Products (All returns)', 'TopoRasterAll_BCAL', PATH='BCAL LiDAR Tools/Create Raster Products', uvalue='tametric'
  e.AddExtension, 'Vegetation Products', 'VegMetrics_BCAL', PATH='BCAL LiDAR Tools/Create Raster Products', uvalue='vmetric'
  e.AddExtension, 'Intensity Products', 'IntensityMetrics_BCAL', PATH='BCAL LiDAR Tools/Create Raster Products', uvalue='imetric'
  e.AddExtension, 'Prepare LAS file(s)', 'PrepareLAS_BCAL', PATH='BCAL LiDAR Tools/Create Raster Products', uvalue='prepareLAS'
  e.AddExtension, 'Create Raster Layer (legacy)', 'LidarRasterLAS_BCAL', PATH='BCAL LiDAR Tools/Create Raster Products', uvalue='raster_legacy'
  
  e.AddExtension, 'Create Vegetation Height Groups', 'HeightGroupsLAS_BCAL', PATH='BCAL LiDAR Tools', uvalue='heightgroups'
  e.AddExtension, 'Create Elevation Profile(s)', 'TransectLAS_BCAL', PATH='BCAL LiDAR Tools', uvalue='transect'
  e.AddExtension, '3D Lidar Viewer', 'Visualize3D_BCAL', PATH='BCAL LiDAR Tools', uvalue='visualize'
  e.AddExtension, 'LiDAR Processing Wizard', 'Wizard_BCAL', PATH='BCAL LiDAR Tools', uvalue='wizard'
  
  e.AddExtension, 'Start Help', 'LiDARToolsHelp_BCAL', PATH='BCAL LiDAR Tools/Help', uvalue='LiDARToolsHelp'
  e.AddExtension, 'Check for Updates...', 'LiDARToolsHelp_BCAL', PATH='BCAL LiDAR Tools/Help', uvalue='LiDARToolsUpdates'
  e.AddExtension, 'About BCAL LiDAR Tools', 'LiDARToolsHelp_BCAL', PATH='BCAL LiDAR Tools/Help', uvalue='AboutLiDARTools'

end

; ENVI Extension code. Called when the toolbox item is chosen.
pro LidarTools_BCAL_Envi5x

  
end
