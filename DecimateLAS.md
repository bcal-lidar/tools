# Using "Decimate LAS File(s)" #

This tool is meant to decimate (or reduce number of lidar points from) one or more LAS files. LAS files can be decimated by number of points or by percentage of the total points.

## Usage: ##

  * Select the input file(s) to decimate.
  * Input the desired number or percentage of points in the output file.
  * Select the output file. If multiple input files are selected, they will be combined into a single output file with the desired number of points. The number of points contributed by each input file is proportional to the individual sizes of the input files.


## Notes: ##

  * This tool requires data that are in the LAS format.

### Decimate by number ###
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/DecimateScreen.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/DecimateScreen.jpg)
### Decimate by percent ###
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/DecimateScreenPercent.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/DecimateScreenPercent.jpg)