# Using "Vegetation Products" #

This tool is meant to convert LiDAR point data into various raster vegetation products. This tool requires the LiDAR data to have been processed through the [height filtering](HeightFiltering.md).

# Usage: #

  * Select the input LAS file(s) to rasterize. Multiple files may be selected to combine into a single raster or separate rasters.
  * Select whether to use the first return, last return, or both.
  * Input the raster pixel resolution. The units of this parameter are the same as the horizontal coordinates of the data.
  * Enter the value for pixels where no data exists.
  * Enter the ground threshold value (GT). If you specify a threshold value of 0.15 m, all the points that have above-ground height of 0.15 m or less will be considered as ground returns. GT are used for calculation of canopy density and height distribution products.
  * Enter the crown threshold value (CT). If you specify a threshold value of 1.37 m, all the points that have above-ground height greater than 1.37 m will be considered as crown returns. CT are used for calculation of canopy density and height distribution products.
  * If the "Interpolate data?" box is checked, the tool will interpolate gaps within the raster. However, the tool does not extrapolate outside the edges of the data.
  * If the "Use vector mask(s)?" box is checked, the tool will prompt the user to select one or more EVF files. Pixels within these areas will not be processed.
  * If the "Mosaic multiple files?" box is checked, then multiple input files will be combined into a single raster. If this box is not checked, and multiple input files are selected, a raster will be created for each input file.
  * If the "Ignore outliers?" box is checked, then lidar points whose elevation is five or more standard deviations from the median will be ignored.
  * Set the desired geographic extents of the output raster. The default values are the overall extents of the selected input file(s).
  * If necessary, set the projection associated with the data.
  * Select which products to display. These include:
    * **Minimum Height** - The minimum of all height points within each pixel.
    * **Maximum Height** - The maximum of all height points within each pixel.
    * **Height Range** - The difference of maximum and minimum of all height points within each pixel.
    * **Mean Height** - The average of all height points within each pixel.
    * **Median Absolute Deviation (MAD) from Median Height** -  The MAD value of all height points within each pixel. MAD = 1.4826 x median(|height - median height|)
    * **Mean Absolute Deviation (AAD) from Mean Height** -  The AAD value of all height points within each pixel. AAD = mean(|height - mean height|)
    * **Height Variance** - The variance of all height points within each pixel.
    * **Height St. Deviation** - The standard deviation of all height points within each pixel. This is also called 'absolute vegetation roughness'
    * **Height Skewness** - The skewness of all height points within each pixel.
    * **Height Kurtosis** - The kurtosis of all height points within each pixel.
    * **Interquartile Range (IQR) of Height** - The IQR of all height points within each pixel.  IQR = Q75-Q25, where Qxx is xxth percentile.
    * **Height Coefficient of Variation** - The coefficient of variation of all height points within each pixel.
    * **Height Percentiles** - The 5th, 10th, 25th, 50th, 75th, 90th, and 95th percentiles of all height points within each pixel.
    * **Number of LiDAR Returns** - The total number of all points within each pixel.
    * **Number of LiDAR Vegetation Returns (nV)** - The total number of all the points within each pixel that are above the specified crown threshold value (CT).
    * **Number of LiDAR Ground Returns (nG)** - The total number of all the points within each pixel that are below the specified ground threshold value (GT).
    * **Total Vegetation Density** - The percent ratio of vegetation returns and ground returns within each pixel. Density = nV/nG\*100.
    * **Vegetation Cover** - The percent ratio of vegetation returns (nV) and total returns within each pixel.
    * **Percent of Vegetation in Height Range** - Percent of vegetation in height ranges 0-1m, 1-2.5m, 2.5-10m, 10-20m, 20-30m, and >30m within each pixel. Percent of Vegetation = Number of vegetation returns in the range/Total vegetation returns
    * **Canopy Relief Ratio** - Canopy relief ratio of points within each pixel. Canopy relief ratio = ((HMEAN - HMIN))/((HMAX - HMIN))
    * **Texture of Heights** - Texture of height of points within each pixel. Texture = St. Dev. (Height > Ground Threshold and Height < Crown Threshold).
  * Click "OK"
  * Select the output file, or save to memory. (If multiple files are selected and the "Mosaic multiple files?" box is unchecked, the user will be prompted for an output directory instead.)

## Notes: ##

  * This tool requires data that are in the LAS format.
  * The raster products are saved as one or more ENVI data files, with each product as an individual band. If a single file is processed, or multiple files mosaicked, the output file is immediately opened in an ENVI display window.
  * If multiple input files are selected, this tool may leave artifacts along the seams of the input files. This is due to processing the input files individually and the resulting lack of points near at the seams.
  * Tip: If the input files overlap, then the output raster should be seamless. Use the [buffering tool](BufferLAS.md) to create overlapping LAS files.
  * This tool currently uses simple nearest neighbor-type interpolation, which may not be optimal in some cases.
  * For detailed description of these vegetation products, refer to:
    * Evans, J., Hudak, A., Faux, R. and Smith, A.M., 2009. [Discrete Return Lidar in Natural Resources: Recommendations for Project Planning, Data Processing, and Deliverables](http://dx.doi.org/10.3390/rs1040776). Remote Sensing, 1(4): 776-794.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/VegProd.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/VegProd.jpg)