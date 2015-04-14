# Using "Create Bare-earth DEM" #

This tool is meant to create bare-earth raster digital terrain model from [height-filtered](HeightFiltering.md) LAS file(s).

# Usage: #

  * Select the input file(s). Multiple files may be selected to combine into a single DEM or separate DEMs.
  * Select whether to use the first return, last return, or both.
  * Input the raster pixel resolution. The units of this parameter are the same as the horizontal coordinates of the data.
  * Enter the value for pixels where no data exists.
  * If the "Interpolate data?" box is checked, the tool will interpolate gaps within the raster. However, the tool does not extrapolate outside the edges of the data.
  * If the "Use vector mask(s)?" box is checked, the tool will prompt the user to select one or more EVF files. Pixels within these areas will not be processed.
  * If the "Mosaic multiple files?" box is checked, then multiple input files will be combined into a single raster. If this box is not checked, and multiple input files are selected, a raster will be created for each input file.
  * If the "Ignore outliers?" box is checked, then lidar points whose elevation is five or more standard deviations from the median will be ignored.
  * Set the desired geographic extents of the output raster. The default values are the overall extents of the selected input file(s).
  * If necessary, set the projection associated with the data.
  * Click "OK"
  * Select the output file, or save to memory. (If multiple files are selected and the "Mosaic multiple files?" box is unchecked, the user will be prompted for an output directory instead.)

## Notes: ##

  * This tool requires data that are in the LAS format.
  * The DEM is saved as one or more ENVI data files. If a single file is processed, or multiple files mosaicked, the output file is immediately opened in an ENVI display window.
  * If multiple input files are selected, this tool may leave artifacts along the seams of the input files. This is due to processing the input files individually and the resulting lack of points near at the seams.
  * Tip: If the input files overlap, then the output raster should be seamless. Use the [buffering tool](BufferLAS.md) to create overlapping LAS files.
  * This tool currently uses simple nearest neighbor-type interpolation, which may not be optimal in some cases.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/DEMLAS.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/DEMLAS.jpg)