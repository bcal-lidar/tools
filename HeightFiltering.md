# Using "Perform Height Filtering" #

This tool is meant to filter LiDAR data into ground and vegetation classes, and to calculate the heights of the vegetation points above the ground.


## Usage: ##

  * Select the input file(s) to filter. If multiple files are selected, they are processed sequentially.
  * Select whether to use the 1<sup>st</sup> return, 2<sup>nd</sup> return, or all returns.
  * Input an estimated canopy spacing. This parameter reflects how "open" the canopy is, and is in the units of the horizontal coordinates of the data. Generally, 4-5 m seems to work fairly well. (Note: this is not the same as the LiDAR point spacing.)
  * Input a threshold value. The default value of 0 is fine for most cases. When you want to generate more ground returns, for example, to preserve features like ridges, or rock outcrops, you may want to increase the threshold value.
  * Select the interpolation method to be used. The method chosen may have a significant effect on processing speed, with "Linear" being the fastest. ("Natural Neighbor" has also been found to work quite well.)
  * Input the maximum allowed height, in units of the elevation data.   Any computed height values greater than this will be assumed in error.
  * Input the maximum iteration value. By default, height filtering runs for maximum of 15 iterations, which is fine if your threshold value is 0. If you increase your threshold value, you will have to also increase the iteration number. Otherwise, some LiDAR points will remain unclassified.
  * Select the output directory. The output files will be saved in the new directory with the same name as the input files.

## Notes: ##

  * This tool requires data that files are in the LAS format.
  * This tool was developed to filter rangeland vegetation (sagebrush, etc.) which has a fairly open canopy. It seems to work fairly well in some forestry applications, but has not been evaluated for dense canopies (i.e. rainforests). Ultimately, the effectiveness probably relies on the LiDAR point spacing more than anything else.
  * This tool is not intended to filter buildings or other large structures.
  * The tool may not do very well calculating height values near the edges of the data files. This is due to processing files individually and the resulting lack of points near the edges.
  * For more information on the filtering algorithm, see:
    * [Streutker, D. and Glenn, N., 2006. LiDAR measurement of sagebrush steppe vegetation heights. Remote Sensing of Environment, 102, 135-145.](http://bcal.geology.isu.edu/manuscripts/Streutker_2006_RSE.pdf)

<a href='http://www.youtube.com/watch?feature=player_embedded&v=CdQszsR8vfo' target='_blank'><img src='http://img.youtube.com/vi/CdQszsR8vfo/0.jpg' width='425' height=344 /></a>![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/FilterScreen.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/FilterScreen.jpg)