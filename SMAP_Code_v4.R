#Aaron Kamoske -- kamoskea@msu.edu
#8/11/2016
#----------------------------------------------------------------------------------------------
#THIS R SCRIPT WILL DOWNLOAD SMAP HDF5 DATA FROM A SET DATE RANGE,
#EXTRACT SOIL_MOISTURE, RETRIEVAL_QUAL_FLAG, AND SURFACE_FLAG RASTERS,
#MASK "FILL GAP" VALUES AND MODELED VALUES (BASED OFF OF RETRIEVAL_QUAL_FLAG
#AND SURFACE_FLAG BINARY VALUES), AND WRITE ALL PROCESSED RASTERS AS GEOTIFFS
#THE SMAPr PACKAGE PROCESSES MULTIPLE FILES AS A RASTERBRICK, THUS ALLOWING
#FOR EASY FILE MANIPULATION AND UNSTACKING AT THE END OR PROCESSING TO WRITE AS GEOTIFFs
#----------------------------------------------------------------------------------------------
#USEFUL DOCUMENTATION CAN BE FOUND HERE:
#https://github.com/earthlab/smapr
#http://nsidc.org/data/docs/daac/smap/sp_l3_smp/data-fields.html#Soil_Moisture_Retrieval_Data
#http://smap.jpl.nasa.gov/
#----------------------------------------------------------------------------------------------

#install SMAPr package (if not already installed), load necessary libraries
#according to SMAPr github page, and set workspace and other directory variables
#devtools::install_github("earthlab/smapr")
library("smapr")
library("curl")
library("httr")
library("rappdirs")
library("raster")
library("rgdal")
library("rhdf5")
library("utils")
library("zoo")
workspace <- setwd("Y:/shared_data/SMAP")
dlDir <- "Y:/shared_data/SMAP/raw_data"
rasterOptions(tmpdir = "C:/Temp")

#SOME DATES DO NOT HAVE DATA AND AND ERROR IS THROWN WHEN ATTEMPTING DOWNLOAD
#THUS NEED TO BREAK UP DATE RANGE TO EXCLUDE THESE NON-EXISTANT DATES...
#create objects for date range
#generate date sequences to exlude missing SMAP dates so error is not thrown
#convert date sequence to format that is required by SMAP
#create object that combines all date sequences into one varuavke
print("BEGINNING DATE SEQUENCING...")
startDate <- as.Date("2015-04-01")
endDate <- as.Date("2016-03-31")
dateSeq <- seq(startDate, endDate, by = 1)
exDates <- as.Date(c("2015-05-13", "2015-06-16", "2015-12-16", "2016-01-01", "2016-01-02", "2016-01-03"))
availDates <- setdiff(dateSeq, exDates)
finalDates <- as.Date(availDates)
print("DATE SEQUENCING COMPLETE!!!")

#find SMAP files to make sure that they exist
#SPL3SMP = Radiometer Global Soil Moisture - 36km
print("FINDING SMAP FILES...")
smapFiles <- find_smap(id = "SPL3SMP", dates = finalDates, version = 3)
print("SMAP FILES FOUND!!!")

#download SMAP data in hdf5 format
print("DOWNLOADING SMAP FILES...")
downloads <- download_smap(smapFiles, directory = dlDir, overwrite = FALSE)
print("SMAP FILES DOWNLOADED!!!")

#extract soil_moisture layer from hdf5 file and return it as a Raster object
#NOTE: some files appear to already have "fill gap" values removed and some do not..
#mask "fill gap" values (-9999) and plot raster
print("EXTRACTING SOIL_MOISTURE RASTERS...")
soilMoisture <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/soil_moisture')
print("SOIL_MOISTURE RASTERS EXTRACTED!!!")

print("MASKING FILL GAP VALUES...")
soilMoisture[soilMoisture == -9999] <- NA
print("FILL GAP VALUES MASKED!!!")

#extract retrieval_qual_flag layer from hdf5 file and return it as a Raster object
#mask all retrieval_qual_flag values that are > 0 (0 == pixels that are in "Retrieval Successful" category)
#for documentation of retrieval_qual_flags error values see
#http://nsidc.org/data/docs/daac/smap/sp_l3_smp/data-fields.html#retrieve
print("EXTRACTING RETRIEVAL_QUAL_FLAG RASTERS...")
qualFlag<- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/retrieval_qual_flag')
print("RETRIEVAL_QUAL_FLAG RASTERS EXTRACTED!!!")

print("MASKING RETRIEVAL_QUAL_FLAG VALUES...")
qualFlag[qualFlag > 0] <- NA
print("RETRIEVAL_QUAL_FLAG VALUES MASKED!!!")

#extract surface_flag layer from hdf5 file and return it as a Raster object
#find frequency of surface_flag values to compare to surface_flag codes
#mask all surface_flag values that are > 0 (pixels that did not fall into a surface_flag category)
#plot raster
#for documentation of surface_flag error values see
#http://nsidc.org/data/docs/daac/smap/sp_l3_smp/data-fields.html#surf
print("EXTRACTING SURFACE_FLAG RASTERS...")
surfaceFlag <- extract_smap(downloads, name = 'Soil_Moisture_Retrieval_Data/surface_flag')
print("SURFACE_FLAG RASTERS EXTRACTED!!!")

print("MASKING SURFACE_FLAG VALUES...")
surfaceFlag[surfaceFlag > 0] <- NA
print("SURFACE_FLAG VALUES MASKED!!!")

#mask the surface_flag raster and the retrieval_qual_flag raster
#so that only the overlapping pixels are returned
#mask the soil_moisture raster (that has had fill gap values removed)
#with the surface_flag and retrieval_qual_flag mask
print("MASKING SURFACE_FLAG AND RETRIEVAL_QUAL_FLAG VALUES...")
sfQf <- mask(surfaceFlag, qualFlag)
print("SURFACE_FLAG AND RETRIEVAL_QUAL_FLAG VALUES MASKED!!!")

print("SOIL_MOISTURE MASKING RASTER...")
smRaster <- mask(soilMoisture, sfQf)
print("SOIL_MOISTURE RASTER MASKED!!!")

#unstack raster brick
print("UNSTACKING RASTER BRICK...")
usRaster <- unstack(smRaster)
print("RASTER BRICK UNSTACKED!!!")

#create for loop to write all rasters
#create variable for final output path
#create variable for final output name
#save final raster as a GeoTIFF
print("WRITING RASTERS AS GEOTIFF...")
for (i in usRaster) {
  outPath <- "Y:/shared_data/SMAP/clean_data"
  outName <- paste0(names(i), "_SOIL_MOISTURE")
  writeRaster(i, filename = paste(outPath, outName), format = "GTiff", overwrite = TRUE)
}
print("ALL RASTERS SAVED!!!")

#delete all files from temporary directory
#reset the working directory to the original working directory
setwd("C:/Temp")

temp.files <- normalizePath(list.files(pattern=glob2rx("*tmp*"),full.names =TRUE))
if (length(temp.files) > 0) {
  do.call(file.remove, as.list(temp.files))
}

workspace
print("CODE IS FINISHED RUNNING!!!")