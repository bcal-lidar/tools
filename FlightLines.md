# Using "Extract Flight Lines from LAS file(s)" #

This tool is meant to extract separate LAS files for each flight line from time information of input LAS file(s).


## Usage: ##

  * Select the input LAS file(s).
  * Select the output directory. One LAS file will be saved for each flight lines.  The output files are stored in the specified output directory with file names as Line\_1, Line\_2, and so on.


## Notes: ##

  * This tool requires data that are in the LAS format, and the LAS file has GPS time field stored for each points.

### Flight Lines Extraction ###
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/FlightLAS.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/FlightLAS.jpg)