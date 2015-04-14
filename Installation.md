# Installation Instructions #
## version 2.x.x ##
  1. If you already have ENVI 4.8 or IDL 8.0 installed, go to Step 2. Otherwise, download and install latest version of [IDL Virtual Machine (VM)](http://www.exelisvis.com/Support/HelpArticlesDetail/TabId/219/ArtMID/900/ArticleID/12395/The-IDL-Virtual-Machine.aspx).  IDL VM is free, but you will need to register at Exelis website to download the software. It might take about one business day before your account gets approved by Exelis, and you are able to download IDL VM. When you install evaluation version of IDL, IDL VM is also installed.
  1. [Download](http://bcal.boisestate.edu/tools/lidar/) the Lidar Tools Zip (version 2.x.x) file. Unzip the file you have downloaded. Make sure 'resources' folder and 'lidartools.sav' are in same directory.
  1. BCAL LiDAR Tools work on Windows, Mac or Unix.
    * In Windows, double-clicking 'lidartools.sav' will start the program.
    * In Mac, double-click the IDL Virtual Machine icon to start the IDL Virtual Machine, and open the 'lidartools.sav' from the file selection menu.
    * In Unix, issuing following command in the terminal will start the program. Replace 'Path-to-lidartools' with your path, e.g., usr/local/lidartools/
> > > ```
idl -vm=Path-to-lidartools/lidartools.sav```

## version 1.x.x for ENVI 4.x and ENVI 5.x Classic ##
  1. You will need ENVI 4.7 or above pre-installed in your computer. These tools have not been tested for other versions of ENVI.
  1. [Download](http://bcal.boisestate.edu/tools/lidar/) the Lidar Tools Zip (version 1.x.x) file. Unzip the file into the "save\_add" folder of your ENVI installation. On my computer, this folder is located at: "C:\Program Files\ITT\IDL71\products\envi4X\save\_add\" for ENVI 4.x and "C:\Program Files\Exelis\ENVI5x\classic\save\_add" for ENVI 5.x Classic.
  1. Start ENVI
  1. BCAL LiDAR tools will be located under a new "BCAL LiDAR" button in the ENVI display between the "Topographic" and "Radar" menus


## version 1.x.x for ENVI 5.x ##
  1. [Download](http://bcal.boisestate.edu/tools/lidar/) the Lidar Tools Zip file. Unzip the file into the "extensions" folder of your ENVI installation. On my computer, this folder is located at: "C:\Program Files\Exelis\ENVI50\extensions\". If you have previous versions installed, remove the previous versions.
  1. Start ENVI
  1. The tools will appear within the 'Extensions' menu.

Note: The tools have been tested to work for ENVI 4.7, 4.8 and ENVI 5.0. If it is not working for your version of ENVI, the best option would be to [download the source codes](http://code.google.com/p/bcal-lidar-tools/source), and recompile the program in your machine.

![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/MenuBarScreen.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/MenuBarScreen.jpg)
![http://bcal-lidar-tools.googlecode.com/svn/wiki/images/bcal_tools_envi5.jpg](http://bcal-lidar-tools.googlecode.com/svn/wiki/images/bcal_tools_envi5.jpg)