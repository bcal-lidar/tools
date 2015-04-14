# Using "3D Lidar Viewer" #

This viewer is used to display lidar point data.

## Usage: ##

  * Open one or more lidar files using the "File" pulldown menu.
  * Manipulate the lidar data in three dimensions using the mouse:
    * Drag while holding down the left mouse button to rotate the data.
    * Drag while holding down the right mouse button to translate the data.
    * Use the mouse scroll wheel to zoom the data in and out.
  * The data can be viewed as points, a wire mesh, or a surface.
  * The data colors can be set to correspond to elevation, intensity, vegetation height (if the data has been [filtered](HeightFiltering.md)), return number, scan angle, classification, or an image.
  * The colors of the data, background, and optional axes are all customizable.
  * The viewer also includes the capability to save a screen capture.

## Notes: ##

  * This viewer requires data that are in the LAS format.
  * This viewer is based on [FSC\_SURFACE](http://www.idlcoyote.com/programs/retired/fsc_surface.pro) by [David Fanning](http://www.dfanning.com/).
  * Because most data sets contain far too many points for the viewer to adequately display, a random subset of points are utilized. The number of subset points can be adjusted by the user under "Properties".
  * If the colors are set corresponding to an image ("Style->Surface Color Type->From Image"), the source image must be in the same projection as the lidar data and must completely cover the the geographical extent of the lidar data.

## Visualization Options: ##
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/BCAL_Visualization.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/BCAL_Visualization.jpg)
http://bcal-lidar-tools.googlecode.com/svn/wiki/images/BCAL_Viz_Options.JPG