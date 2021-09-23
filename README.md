# Biofilm Analysis Fiji macro
The macro works with single slice image, e.g. single focal planes, maximum intensity projections or single slices of a z-stack. The expected order of the channels is Ch1: live, Ch2: dead. 

The macro will analyse all files within a specific input folder and write the following results files: 
1. filename_area-results.txt which contains 
    * the total area of objects of the green stain mask
    * the total area of objects of the red stain mask
    * the boolean sum total area of objects of the green and red stain masks
    * the area of green stain objects left after subtraction of the  red stain mask   
2. filename_live-results.txt which contains the measurements of the area (Area), integrated density (IntDen) median intensity (Median) and raw integrated density (RawIntDen) of the combined ROIs of the green channel. 
3. filename_dead-results.txt which contains the measurements of the area (Area), integrated density (IntDen) median intensity (Median) and raw integrated density (RawIntDen) of the combined ROIs of the red channel.
4. filename_overlay.tif an overlay of the live and dead cell outlines over the original data 

Further output files can be produced by uncommenting some lines of code in the plugin.
