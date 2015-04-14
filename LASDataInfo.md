# Using "Get LAS Data Info" #

This tool is used to display information and descriptive statistics about a single LAS file or multiple LAS files quickly. These information are normally not available in LAS header file.

## Usage: ##

  * 'Single file' option:
    * Select LAS file of interest.
    * A new window will display information about the selected file. Following information is displayed:
      * File name, total area covered (in same unit as the LAS file), point density per unit area, number of flight lines in the LAS file, start and end time
      * Number of points in each classes.
      * Histogram of points by elevation, return numbers, classes, scan angle, vegetation height (only for Height filtered data) and time

  * 'Multiple files' option:
    * Select LAS file(s) of interest
    * Select the output text file.
    * Descriptive statistics about the LAS file would be stored in comma-separated format

## Notes: ##

This tool requires data that are in the LAS format.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/LASDataInfo.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/LASDataInfo.jpg)