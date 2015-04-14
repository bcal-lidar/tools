# Using "Topographic Products (Bare)" #

This tool is meant to convert LiDAR point data into various raster topographic bare-earth products.

# Usage: #

  * Select the input LAS file(s) to rasterize. Multiple files may be selected to combine into a single raster or separate rasters. Input LAS files must be [height filtered](HeightFiltering.md) before rasterization.
  * Select whether to use the first return, last return, or both.
  * Input the raster pixel resolution. The units of this parameter are the same as the horizontal coordinates of the data.
  * Enter the value for pixels where no data exists.
  * If the "Interpolate data?" box is checked, the tool will interpolate gaps within the raster. However, the tool does not extrapolate outside the edges of the data.
  * If the "Use vector mask(s)?" box is checked, the tool will prompt the user to select one or more EVF files. Pixels within these areas will not be processed.
  * If the "Mosaic multiple files?" box is checked, then multiple input files will be combined into a single raster. If this box is not checked, and multiple input files are selected, a raster will be created for each input file.
  * If the "Ignore outliers?" box is checked, then lidar points whose elevation is five or more standard deviations from the median will be ignored.
  * Set the desired geographic extents of the output raster. The default values are the overall extents of the selected input file(s).
  * If necessary, set the projection associated with the data.
  * Select which products to display. These include:
    * **Bare Earth Elevation Minimum** - The minimum bare earth elevation (data elevation minus vegetation height) point within each pixel
    * **Bare Earth Elevation Mean** - The mean bare earth elevation (data elevation minus vegetation height) of all points within each pixel
    * **Bare Earth Elevation Maximum** - The maximum bare earth elevation (data elevation minus vegetation height) point within each pixel
    * **Bare Earth Absolute Roughness** - The roughness (standard deviation) of all bare earth elevation points (data elevation minus vegetation height) within each pixel
    * **Bare Earth Local Roughness** - The roughness (standard deviation) of all bare earth elevation points (data elevation minus vegetation height) within each pixel after the local slope has been removed (de-trended)
    * **Bare Earth Slope** - The average slope of all bare earth points within each pixel in degrees
    * **Bare Earth Aspect** - The aspect of the average slope of all bare earth points within each pixel in degrees from North.
    * **Bare Earth Topographic Solar Radiation Index (TRASP)**: Transformation of Aspect (TRASP), used by Roberts and Cooper (1989), is defined as (1 - cosine(aspect - 30))/2. TRASP assigns the lowest value to coolest and wettest north-northeastern aspect, and the highest to the hotter, dryer south-southwesterly slopes.
    * **Bare Earth Slope Cosine Aspect (Slpcosasp)** - Slpcosasp is calculated as slope x cosine(aspect) (Stage, 1976). This is based on [transformation script](http://arcscripts.esri.com/details.asp?dbid=11866) by Jeffrey Evans.
    * **Bare Earth Slope Sine Aspect (Slpsinasp)** - Slpsinasp is calculated as slope x sine(aspect) (Stage, 1976). This is based on [transformation script](http://arcscripts.esri.com/details.asp?dbid=11866) by Jeffrey Evans.
    * **Ground Point Density** - The density of ground points within each pixel
  * Click "OK"
  * Select the output file, or save to memory. (If multiple files are selected and the "Mosaic multiple files?" box is unchecked, the user will be prompted for an output directory instead.)

## Notes: ##

  * This tool requires data that are in the LAS format.
  * The raster products are saved as one or more ENVI data files, with each product as an individual band. If a single file is processed, or multiple files mosaicked, the output file is immediately opened in an ENVI display window.
  * If multiple input files are selected, this tool may leave artifacts along the seams of the input files. This is due to processing the input files individually and the resulting lack of points near at the seams.
  * Tip: If the input files overlap, then the output raster should be seamless. Use the [buffering tool](BufferLAS.md) to create overlapping LAS files.
  * This tool currently uses simple nearest neighbor-type interpolation, which may not be optimal in some cases.
  * References:
    * Stage, A.R., 1976. [An Expression for the Effect of Aspect, Slope, and Habitat Type on Tree Growth](http://www.ingentaconnect.com/content/saf/fs/1976/00000022/00000004/art00020). Forest Science, 22: 457-460.
    * Roberts. D. W. and Cooper, S. V. (1989). Concepts and techniques of vegetation mapping. In: Land Classifications Based on Vegetation - Applications for Resource Management. USDA Forest Service GTR INT-257, Ogden, UT, pp 90-96.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/TopoBare.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/TopoBare.jpg)