# Processing Guide for LiDAR Tools #

This page is a basic guideline to processing LiDAR data using the BCAL LiDAR Tools software package for ENVI. More detailed information on the individual steps can be found on the information pages for the respective tools.

## Step 1: Convert your data to the .las format (if necessary) ##

The BCAL LiDAR Tools package requires that all data be in the .las data format. If your data are not in this format, you will need to convert them before any processing can take place. The BCAL LiDAR Tools package contains a [conversion tool](AsciiToLAS.md) for converting your data from ascii to las.

## Step 2: Tile your data (if necessary) ##

In order to accomplish many of the functions in the BCAL LiDAR Tools package, the software must be able to read the individual files into the computer's memory. If the files are too large (or if the computer's memory is limited), they can be broken into smaller files using the [tiling feature](TileLAS.md). Alternatively, large files may also be [subset](SubsetLAS.md) or [decimated](DecimateLAS.md).

## Step 3: Explore your data ##

Use the [file info tool](LASFileInfo.md) to explore your data files. Things to look for include projection information (or lack thereof), point density, number of returns available, and the spatial extents of the data. Also of use is the [boundary tool](BoundaryLAS.md), with which you can display the geographic footprints of the individual files.

## Step 4: Buffer your data (optional) ##

When filtering and/or rasterizing multiple files at once (for a single project), the software often has problems at the seams between the data tiles. These problems can be overcome by [buffering the data](BufferLAS.md), which creates areas of overlap between the files. The buffer distance (and thus distance of overlap) should be several times the value of the canopy spacing ([filtering](HeightFiltering.md)) or pixel size ([rasterizing](RasterizeLAS.md)).

## Step 5: Filter your data ##

If you are interested in calculating the heights of vegetation in your data or determining bare ground elevations, use the [height filtering tool](HeightFiltering.md).

## Step 6: Rasterize your data ##

Use the [raster tool](RasterizeLAS.md) to create various raster products from your data. Remember that the raster products related to vegetation and/or bare ground cannot be created unless the data have been filtered first.


# Data Processing Workflow #

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/LiDARWorkflow.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/LiDARWorkflow.jpg)

<a href='http://www.youtube.com/watch?feature=player_embedded&v=1djbk3Gx2m0' target='_blank'><img src='http://img.youtube.com/vi/1djbk3Gx2m0/0.jpg' width='425' height=344 /></a>