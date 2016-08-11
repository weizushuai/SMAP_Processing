# SMAP_Processing
Processing soil_moisture rasters from SMAP

SMAP_Code_Single_File processes one file from SMAP and includes code for reading HDF5 files and their attributes.
This was used as a beginning point before processing multiple SMAP files at the same time.  

SMAP_Code_v4 processes multiple files, based off of a sequence of dates, in the form on a raster brick.
It then unstacks the raster brick and writes the individual rasters as GEOTiffs.
