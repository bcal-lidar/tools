# Update Log #
## ver 1.x.x (ENVI add-on) ##
  * ver 1.5.0 (12/20/2012)
    * Added new data processing wizard tool.
    * Added ability to manually specify header offsets and scaling in [Ascii to LAS](AsciiToLAS.md) tools.
  * ver 1.4.0 (5/1/2012)
    * Added new tool to [reclassify LAS files](ReclassifyLAS.md)
  * ver 1.3.0 (6/17/2011)
    * Added new metrics to compute [vegetation cover](VegProducts.md)
  * ver 1.2.0 (3/4/2011)
    * Added ability to [convert LAS files](LAStoAscii.md) into ESRI PointZ Shapefiles
    * Added 'check update' help menu
  * ver 1.1.2 (3/2/2011)
    * Fixed bug related [reprojecting](ReprojectLAS.md) already projected LAS files
  * ver 1.1.1 (2/21/2011)
    * Compiled for ENVI 4.7 compatibility
  * ver 1.1.0 (02/02/2011)
    * Added new tool to:
      * [quickly view LAS data summary](LASDataInfo.md)
      * [export LAS files](ExportLAS.md) by return numbers, classes, elevation, height, scan angle
      * [assign RGB colors](AssignRGB.md) to LAS file from multispectral images
      * [extract flight lines](FlightLines.md) from GPS time information
      * [create vegetation height groups](HeightGroups.md)
      * [compute vegetation height](PrepareLAS.md) from existing DEM
      * create different raster value-added products: topographic ([all returns](TopoAll.md)/[bare-earth returns](TopoBare.md)), [intensity](IntensityProducts.md), and [vegetation](VegProducts.md).
    * Also added more fields for [KML display](BoundaryLAS.md), options to [decimate by percent](DecimateLAS.md), added threshold measure for [height filtering](HeightFiltering.md)
  * ver 1.0.0 (04/31/2010)
    * Added Help, ability to [export boundary as KML/Shapefiles](BoundaryLAS.md), ability to work alongside ITTVis Lidar Tools, and several other bug fixes
  * 04/16/2010 - Added [LAS to Ascii conversion tool](LAStoAscii.md), [export ground points tool](ExportLAS.md), made minor bug fixes
  * 10/09/2007 - Added the [processing guide](ProcessingGuide.md) to website
  * 07/19/2007 - Added [file information tool](LASFileInfo.md), support for embedded projections, made minor tweaks and fixes
  * 03/15/2007 - Added [ascii conversion](AsciiToLAS.md) and [reprojection](ReprojectLAS.md) tools, made minor tweaks and fixes
  * 11/10/2006 - Added [profiling](ProfileLAS.md) tool, made minor tweaks and fixes
  * 08/09/2006 - Added the [3D visualization module](3DViewer.md)
  * 08/07/2006 - Added [buffering](BufferLAS.md), [decimation](DecimateLAS.md), and [tiling](TileLAS.md) tools
## ver 2.x.x (IDL Virtual Machine Application) ##
  * 06/21/2011 - Developmental version released