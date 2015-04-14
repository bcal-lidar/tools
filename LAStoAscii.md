# Using "Convert LAS Data to Ascii/Shapefile" #

This tool is meant to convert one or more LAS format data files to text (ascii) and/or ESRI shapefile (PointZ).

## Usage: ##

  * Select the input LAS file(s) to convert.
  * Select the fields from the LAS format lidar data to be included in the output file ('X Y Z', 'Time X Y Z Intensity', or 'All available fields’)
  * Select output type ('Ascii', and/or 'Shapefile')
  * If you selected 'Ascii' output option:
    * Select the text file delimiter (comma, semicolon, or tab).
    * If the “Include header row?” box is checked, then the first row of the output text file will contain field names separated by the chosen delimiter.
  * Select the output directory. The output file(s) will be saved in the new directory with the same name as the input files.

## Notes: ##

  * ‘All available fields’ includes the following items from the [LAS Version 1.2 Specification](http://www.asprs.org/society/committees/standards/lidar_exchange_format.html): X (X\_Easting), Y (Y\_Northing), Z (Z\_Elevation), Intensity (Intensity), Return Number (nReturn), Classification (Class), Scan Angle Rank (Angle), User Data (User), Point Source ID (Source), Red, Green, Blue, and GPS Time (GPS\_Time)
  * If the LiDAR data have been processed through the BCAL height filtering algorithm, these results will be stored in the Classification and Point Source ID fields. The Classification field will distinguish ground and vegetation returns (0 = never classified, 1 = unclassified (errors), 2 = ground and 3 = vegetation). The Point Source ID field will contain the vegetation heights (usually in cm). Errors and unclassified points will have a height value of 65535.
  * For more information on this tool, please refer to:
    * Ehinger, S. 2010. [Design, development, and application of LiDAR data processing tools](http://bcal.geology.isu.edu/docs/Ehinger_thesis_0629_Final.pdf). Masters Thesis. Idaho State University, Department of Geosciences.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/LASScreen.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/LASScreen.jpg)