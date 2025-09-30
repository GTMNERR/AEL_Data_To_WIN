# load libraries and data files 
# uncomment below if necessary
# source('R/00_loadpackages_AEL.R')

# 01 load data --------------------------------------------------
## load Lab data file
## this file should be in the 'data/2025' folder
## file needs to be renamed to AEL lab file name
## EDIT and/or REVIEW file prior to loading it
## if new parameters are added or removed the code will need to be edited
## code is currently based on the 2025 lab file format
## DO NOT include field data. Field data are input into WIN using the DEP WIN files
win <- readxl::read_xlsx(here::here('data', 
                                     '2025',
                                     'J2500684(WIN-Results).xlsx'), # this is where you'd want to rename the file
                          sheet = "J2500684(WIN-Results)")

# inspect the data
dplyr::glimpse(win)

# 02 wrangle-tidy data ------------------------------------------------------
## use `` around each column name to preserve WIN format (includes spaces)
## modifying project ID to include no spaces
## populated a bunch of columns with "blanket" information
## replacing analysis method for Orthophosphate to match WIN
win2 <- win %>%
          dplyr::mutate(`Project ID` = toupper(`Project ID`),
                        (across(.cols = 1, str_remove_all, pattern = fixed(" "))),
                        `Sampling Agency Name` = "FDEP GUANA TOLOMATO MATANZAS NATIONAL ESTUARINE RESEARCH RESERVE",
                        `Sample Collection Type` = "Intermediate Grab",
                        `Sample Collection Equip Name` = "Water Bottle",
                        `Activity Depth` = 0.3,
                        `Activity Depth Unit` = "m",
                        `Relative Depth` = "Surface",
                        `Total Depth Unit` = "m",
                        `Activity Representative Ind` = "Representative",
                        (across(`Analysis Method`, str_replace, "SM 4500PE", "SM 4500-P E (48 hour hold time)")))

## filter data to only output sample data
## additional filter to filter out mistakes in sample column
## Monitoring Location ID has to include an actual station name
## remove NAs from dataset

win3 <- win2 %>%
        dplyr::filter(`Activity Type` == "SAMPLE") %>%
                filter(`Monitoring Location ID` == "GTMGL2NUT" | 
                         `Monitoring Location ID` == "GTMGLMNUT" | 
                         `Monitoring Location ID` == "GTMGRNUT" | 
                         `Monitoring Location ID` == "GTMLMNUT" | 
                         `Monitoring Location ID` == "GTMLSNUT" | 
                         `Monitoring Location ID` == "GTMMKNUT" | 
                         `Monitoring Location ID` == "GTMRNNUT")            

# Check data type for datetimestamp and monitoring location ID
dplyr::glimpse(win3)

#Create a second Prep Date Column
#Populate Prep Date/Time. Chlorophyll Suite and Bacteria samples require a prep time
win3 <- win3 %>%
  dplyr::mutate(`Prep Date Time2` = case_when(`Org Analyte Name` == "Chlorophyll a- uncorrected" ~ `Analysis Date Time`,
                                           `Org Analyte Name` == "Chlorophyll a- corrected" ~ `Analysis Date Time`,
                                           `Org Analyte Name` == "Pheophytin-a" ~ `Analysis Date Time`,
                                           `Org Analyte Name` == "Enterococci (MPN)" ~ `Analysis Date Time`,
                                           ))
#Create final dataframe
win_final <- win3

#Remove NAs before merging columns otherwise NAs will be included
win_final <- sapply(win_final, as.character)
win_final[is.na(win_final)] <- ""
win_final <- as.data.frame(win_final)  

#Merge Prep Date Time and Prep Date Time 2
win_final <- win_final %>%
  tidyr::unite(`Preparation Date Time`, c(`Preparation Date Time`, `Prep Date Time2`), sep = "") %>%
  dplyr::mutate(`Preparation Time Zone` = "EST")

# Populate prep time zone column
win_final <- win_final %>%
  dplyr::mutate(`Preparation Time Zone` = "EST")

# 03 export data ------------------------------------------------------
#WIN requires file that is pipe delimited
#Export as pipe delimited .csv and .txt file without field data
#You will use the final .txt file for WIN upload
#Remember to rename file prior to export
write.table(win_final, here::here('output', 'data', 'guanaNUT_0125.csv'), row.names = FALSE,
                              quote = FALSE,
                              sep = "|")
write.table(win_final, here::here('output', 'data', 'guanaNUT_0125.txt'), row.names = FALSE,
            quote = FALSE,
            sep = "|")