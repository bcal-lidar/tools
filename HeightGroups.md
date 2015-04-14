# Using "Create Vegetation Height Groups" #

This tool is meant to separate input LAS file into user-specified vegetation height groups.  This kind of separation can be useful for performing analysis in voxel space.

Input LAS file must be [height filtered](HeightFiltering.md). If the LAS file is height filtered outside BCAL LiDAR tools, LAS file should be [pre-processed](PrepareLAS.md) before running through this tool.

## Usage: ##

  * Select the input LAS file.
  * Add vegetation height groups you want to create.
  * Select the output directory.
  * Click 'Run' button. The output LAS files, one for each vegetation height group, will be saved in the new output directory.

## Notes: ##

  * This tool requires data that are in the LAS format.
  * Vegetation height values should be multiplied by the Z scale factor to calculate heights in the map projection units.
  * For more information on this tool, please refer to:
    * Ehinger, S. 2010. [Design, development, and application of LiDAR data processing tools](http://bcal.geology.isu.edu/docs/Ehinger_thesis_0629_Final.pdf). Masters Thesis. Idaho State University, Department of Geosciences.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/VegGroups.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/VegGroups.jpg)