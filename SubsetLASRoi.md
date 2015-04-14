# Using "Subset LAS File(s) via Image/ROI" #

This tool is meant to subset LAS format LiDAR data using a reference image and/or regions of interest (ROIs).

## Usage: ##

  * Select the input file(s) to subset. Multiple files can be selected if the subset area covers more than a single file.
  * Select a reference image from the list of open files. (If necessary, open the reference image file.) Click "OK".
  * Click the "Spatial Subset" button.
  * Use the ENVI subset window to define a subset area. This can be done using the reference image, map coordinates, or a pre-determined ROI.
  * Select the output file.

## Notes: ##

  * This tool requires data that are in the LAS format.
  * The subset data are saved to a single file, even if multiple input files are selected.
  * Because the data are saved to a single file, this tool can also be used to combine multiple LAS files. Simply leave the geographic extents as the default values.
  * If you want to subset by EVF or other vector files, you have to first import the vector file into ENVI and export it as ROI.

![http://bcal.geology.isu.edu/envihelp/images/SubsetImageScreen.jpg](http://bcal.geology.isu.edu/envihelp/images/SubsetImageScreen.jpg)