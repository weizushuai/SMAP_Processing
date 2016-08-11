#Aaron Kamoske -- kamoskea@msu.edu
#8/10/2016
#----------------------------------------------------------------------------------------
#THIS IS A TEST...SINGLE FILE MANIPULATION
#----------------------------------------------------------------------------------------

#install SMAPr package (if not already installed), load necessary libraries
#according to SMAPr github page, and set workspace
#devtools::install_github("earthlab/smapr")
library("smapr")
library("curl")
library("httr")
library("rappdirs")
library("raster")
library("rgdal")
library("rhdf5")
library("utils")
setwd("C:/Users/kamoskea/Desktop/SMAP_Testing")

#find SMAP files to make sure that they exist
#SPL3SMP = Radiometer Global Soil Moisture - 36km
files <- find_smap(id = "SPL3SMP", date = "2015-05-01", version = 3)
files

#download SMAP data in hdf5 format
downloads <- download_smap(files, 
                           directory = "C:/Users/kamoskea/Desktop/SMAP_Testing/Raw_Data/Downloads", 
                           overwrite = FALSE)
downloads

#list smap info from HDF5 file
list_smap(downloads, all = TRUE)

#extract soil_moisture layer from hdf5 file and return it as a Raster object and plot it
#NOTE: some files appear to already have "fill gap" values removed...
#mask "fill gap" values (-9999) and plot raster
soilMoisture <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/soil_moisture')
plot(soilMoisture, main = "Soil Moisture: 05.01.2015")
soilMoisture[soilMoisture == -9999] <- NA
plot(soilMoisture, main = "Soil Moisture: 05.01.2015 -- No Fill Gap Values (-9999)")

#read hdf5 file for retrieval_qual_flag information
f <- "C:/Users/kamoskea/Desktop/SMAP_Testing/Raw_Data/Downloads/SMAP_L3_SM_P_20150501_R13080_001.h5"
h5ls(f, all = TRUE)
h5read(f, "Soil_Moisture_Retrieval_Data/retrieval_qual_flag", read.attributes = TRUE)

#extract retrieval_qual_flag layer from hdf5 file and return it as a Raster object and plot it
#find frequency of retrieval_qual_flag values to compare to retrieval_qual_flag codes
qualFlag<- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/retrieval_qual_flag')
plot(qualFlag, main = "Retrieval Quality Flag: 05.01.2015")
freq(qualFlag)

#mask all retrieval_qual_flag values that are > 0 (pixels that are in "Retrieval Successful" category)
#plot raster
#for documentation of retrieval_qual_flags error values see
#http://nsidc.org/data/docs/daac/smap/sp_l3_smp/data-fields.html#retrieve
qualFlag[qualFlag > 0] <- NA
plot(qualFlag, main = "Retrieval Quality Flag: 05.01.2015\n--No Retrieval Quality Flags (> 0)--")

#read hdf5 file for surface_flags information
f <- "C:/Users/kamoskea/Desktop/SMAP_Testing/Raw_Data/Downloads/SMAP_L3_SM_P_20150501_R13080_001.h5"
h5ls(f, all = TRUE)
h5read(f, "Soil_Moisture_Retrieval_Data/surface_flag", read.attributes = TRUE)

#extract surface_flag layer from hdf5 file and return it as a Raster object and plot it
#find frequency of surface_flag values to compare to surface_flag codes
surfaceFlag <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/surface_flag')
plot(surfaceFlag, main = "Surface Flag: 05.01.2015")
freq(surfaceFlag)

#mask all surface_flag values that are > 0 (pixels that did not fall into a surface_flag category)
#plot raster
#for documentation of surface_flag error values see
#http://nsidc.org/data/docs/daac/smap/sp_l3_smp/data-fields.html#surf
surfaceFlag[surfaceFlag > 0] <- NA
plot(surfaceFlag, main = "Surface Flag: 05.01.2015 -- No Surface Flags (> 0)")

#mask the surface_flag raster and the retrieval_qual_flag raster
#so that only the overlapping pixels are returned
#plot raster
sfQf <- mask(surfaceFlag, qualFlag)
plot(sfQf, main = "surface_flag and retrieval_qual_flag intersect\n--05.01.2015")

#mask all data that does not have a value of 0 in surface_flag and
#has a value of -9999 in soil_moisture
#plot raster
finalRaster <- mask(soilMoisture, sfQf)
plot(finalRaster, main = "Soil Moisture: 05.01.2015\n--No Fill Gap Values, No Surface Flags, 
     No Retrievel Quality Flags--")

#create variable for final output path
#create variable for final output name
#save final raster as a GeoTIFF
outPath <- "C:/Users/kamoskea/Desktop/SMAP_Testing/Final_Tiffs/"
outName <- paste0(downloads[,1], "_SOIL_MOISTURE")
writeRaster(finalRaster, filename = paste(outPath, outName), format = "GTiff", overwrite = TRUE)