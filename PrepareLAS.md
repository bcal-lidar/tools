# Using "Prepare LAS file(s)" #

This tool is meant to add vegetation height information to the LAS file(s) from existing bare-earth digital terrain model. This tool is useful to compute different raster vegetation and bare-earth products, if height filtering is performed using tools other than [BCAL Height Filtering](HeightFiltering.md).

# Usage: #

  * Select the input LAS file(s).
  * Select the bare-earth digital terrain model. This could be the models delivered by the data vendor, or computed using different height filtering algorithms.
  * Select the output folder. The output LAS file(s) will be stored in this folder with the same name as input LAS file(s). Vegetation height information is stored in 'Point Source ID' field of LAS file.

## Notes: ##

  * This tool requires data that are in the LAS format, and a bare-earth digital terrain model of the area is already computed.
  * This tool computes the vegetation height by subtracting the bare-earth model elevation from the elevation of LiDAR points.