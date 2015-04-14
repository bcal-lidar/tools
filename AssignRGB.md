# Using "Assign RGB Channel Data (LAS 1.2)" #

This tool is meant to assign RGB color data into LAS 1.2 files from multiband images, elevation range, or vegetation height.


## Usage: ##

  * Assigning RGB from orthoimagery:
    * Select the input LAS file(s).
    * Select the reference ortho- or multispectral imagery from the same area.
    * Specify the bands to RGB.
    * Select the output directory. The output files will now have RGB information from the imagery. The files will be saved in the new directory with the same name as the input files.

  * Assigning RGB from elevation:
    * Select the input LAS file(s).
    * Select a color palette.
    * Select the output directory. The output files will now have RGB information from the elevation. The files will be saved in the new directory with the same name as the input files.

  * Assigning RGB from vegetation height:
    * Select the input LAS file(s). The files should be [height filtered](HeightFiltering.md) first.
    * Select a color palette.
    * Select the output directory. The output files will now have RGB information from the vegetation height. The files will be saved in the new directory with the same name as the input files.

## Notes: ##

  * This tool requires data that are in the LAS format.

### RGB from orthoimagery ###
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/RGB_ortho.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/RGB_ortho.jpg)

### Color palette ###
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/shadingcolors.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/shadingcolors.jpg)