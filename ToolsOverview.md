# Tools Overview #

## ver 1.x.x (ENVI add-on) ##
| LAS File Utilities | Process/Manipulate LAS files |
|:-------------------|:-----------------------------|
| -  [Get LAS Header Info](LASFileInfo.md) | Displays header and projection information for an LAS file |
| -  [Get LAS Data Info](LASFileInfo.md) | Displays descriptive data statistics for LAS file(s) |
| -  [Add Projection to LAS File(s)](AddProject.md) | Adds embedded projection information to LAS files |
| -  [Reproject LAS File(s)](ReprojectLAS.md) | Converts existing LAS files into a new map projection |
| -  [Convert Ascii Data to LAS](AsciiToLAS.md) | Converts text point data into LAS format lidar files |
| -  [Convert LAS Data to Ascii/Shapefile](LAStoAscii.md) | Converts LAS format lidar files into delimited text or ESRI Shapefile point data |
| -  [Create Boundary EVF/SHP/KML](BoundaryLAS.md) | Creates an vector file (EVF, shape or KML) that shows the boundaries of the data |
| -  [Buffer LAS Files](BufferLAS.md) | Geographically buffers the data using neighboring files |
| -  [Tile LAS File(s)](TileLAS.md) | Divides one or more files into multiple tiles |
| -  [Reclassify LAS File(s)](ReclassifyLAS.md) | Reassigns new classification to old classes of LAS files |
| -  [Decimate LAS File(s)](DecimateLAS.md) | Decimates the points the data file |
| -  [Subset LAS File(s)](SubsetLAS.md) | Subset LAS files by coordinates or image/ROI |
| - -  [Subset via Coordinates](SubsetLASCoord.md) | Subsets data files according to user coordinates |
| - -  [Subset via Image/ROI](SubsetLASRoi.md) | Subsets data files using a reference image and/or regions of interest |
| -  [Export LAS File(s)](ExportLAS.md) | Export LiDAR returns by return number, number of returns, classes, elevation, intensity, and scan angle |
| -  [Assign RGB Channel Data](AssignRGB.md) | Assigns RGB channel data from multi-band images, elevation color, or vegetation height color, to LAS 1.2 files |
| -  [Extract Flight Lines](FlightLines.md) | Extract flight lines from LAS file(s) using GPS time information |
| [Perform Height Filtering](HeightFiltering.md) | Performs vegetation filtering on the data |
| [Create Bare-earth DEM](BareDEM.md) | Creates bare-earth digital terrain model from height-filtered LAS file(s) |
| Create Raster Products | Create various topographic, intensity and vegetation raster products |
| -  [Create Topographic Products (Bare-earth)](TopoBare.md) | Creates various raster topographic bare-earth products |
| -  [Create Topographic Products (All returns)](TopoAll.md) | Creates various raster topographic products from all point data|
| -  [Create Vegetation Products](VegProducts.md) | Creates various raster vegetation products  |
| -  [Create Intensity Products](IntensityProducts.md) | Creates various raster intensity products  |
| -  [Prepare LAS file(s)](PrepareLAS.md) | Add vegetation height information to the LAS file(s) from existing bare-earth digital terrain model |
| [Rasterize Lidar Data (Legacy)](RasterizeLAS.md) | Converts raw point data into various raster products|
| [Create Vegetation Height Groups](HeightGroups.md) | Separate input LAS file into user-specified vegetation height groups |
| [Create Elevation Profile(s)](ProfileLAS.md) | Creates one or more elevation profiles along a user-defined transect |
| [3D Lidar Viewer](3DViewer.md) | An interactive viewer for displaying lidar point data |