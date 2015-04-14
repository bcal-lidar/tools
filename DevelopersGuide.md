# Developers' Guide #

## Subversion in IDL ##
Maintaining a subversion (SVN) system from IDL Workbench is not very straightforward. This guide is for beginner developers who want to help in the BCAL LiDAR Tools development. This guide is written for IDL 8.0. The process should be similar to other versions of IDL.

  1. Download and install a [Subversion Binary Package](http://subversion.apache.org/packages.html) for your operating system.
  1. If you are using Windows, also download and install [TortoiseSVN](http://tortoisesvn.net/downloads.html) which will provide a nice GUI front-end for your SVN.
  1. IDL comes pre-installed with [Eclipse plugin](http://www.eclipse.org/). You will only need to install Subclipse subversion plugin.
    * [Download](http://subclipse.tigris.org/servlets/ProjectDocumentList?folderID=2240) a suitable version of Subclipse that matches your Eclipse version. It is 3.x for IDL 8.0.
    * Unzip and copy the content of features and plugins folder to IDL installation in your computer. In Windows, it is C:\Program Files\ITT\IDL\IDL80\bin\bin.x86\plugins & \features, and in 64-bit system it is C:\Program Files\ITT\IDL\IDL80\bin\bin.x86\_64\plugins & \features.
  1. Start your IDL Workbench, create a new project, and right-click and select "Import...". A wizard will pop-up.
    * Select "SVN-->Checkout Projects from SVN" and click "Next".
    * Select "Create new repository location" and click "Next".
    * Type "https://bcal-lidar-tools.googlecode.com/svn/trunk/" in Url field and follow the wizard instructions.
  1. Once you have imported source files, you should be able to do other subversion tasks by right-clicking on project folder, and selecting "Team".

## Creating patches online ##
If you do not have commit privileges, you can [create patches online](http://googlecode.blogspot.com/2011/01/make-quick-fixes-quicker-on-google.html), and submit them for review.

## Current version and Branches ##
There are currently two branches 1.x.x and 2.x.x. Branch 2.x.x will be a major rehaul of the tools, removing dependencies on ENVI altogether.