# Vetting and validation of monitoring data
# Hummingbird Monitoring Network 
# Gaby Samaniego gaby@savehummingbirds.org
# Updated 2022-06-27

library(tidyverse)
library(pointblank)
library(lubridate)
library(stringr)

##### Data wrangling and cleaning #####

# Adding in a comment to test pr

# Bring in data for monitoring session 
data <- read.csv("data/SWRS_0423_HMNBandingData_2022.csv", 
                    na.strings = c("",NA))

# Replace <NA> values created by KoBoToolbox electronic form when reading csv 
# file with NA values
data <- data %>% 
  mutate(across(.fns = ~replace(., .x == "<NA>", NA)))

# If Molt information is F (fresh) for all the rows in a molt column, R will treat 
# it as a logical vector and will replace all Fs with FALSE. We need to change any 
# logical column to a character column

# First, check for logical columns 
class(data$Head.Gorget.Molt)
class(data$Body.Molt)
class(data$Primaries.Molt)
class(data$Secondaries.Molt)
class(data$Tail.Molt)

# Second, apply the following code for each logical column 

# For Head Gorget Molt 
if(is.logical(data$Head.Gorget.Molt)){
  data <- data %>% 
    mutate(head2 = ifelse(Head.Gorget.Molt == FALSE, "F", NA)) %>% 
    mutate(Head.Gorget.Molt = head2) %>% 
    select(-head2)
}

# For Body Molt 
if(is.logical(data$Body.Molt)){
  data <- data %>% 
    mutate(body2 = ifelse(Body.Molt == FALSE, "F", NA)) %>% 
    mutate(Body.Molt = body2) %>% 
    select(-body2)
}

# For Primaries Molt 
if(is.logical(data$Primaries.Molt)){
  data <- data %>% 
    mutate(prim2 = ifelse(Primaries.Molt == FALSE, "F", NA)) %>% 
    mutate(Primaries.Molt = prim2) %>% 
    select(-prim2)
}

# For Secondaries Molt 
if(is.logical(data$Secondaries.Molt)){
  data <- data %>% 
    mutate(sec2 = ifelse(Secondaries.Molt == FALSE, "F", NA)) %>% 
    mutate(Secondaries.Molt = sec2) %>% 
    select(-sec2)
} 

# For Tail Molt 
if(is.logical(data$Tail.Molt)){
  data <- data %>% 
    mutate(tail2 = ifelse(Tail.Molt == FALSE, "F", NA)) %>% 
    mutate(Tail.Molt = tail2) %>% 
    select(-tail2)
}

# Capitalize all characters and factors across data frame 
data <- mutate_all(data, .funs=toupper)

# Remove all leading and trailing white spaces across data frame
data <- mutate_all(data,str_trim, side=c("both"))

# Change Date column from character to date
class(data$Date)
data <- data %>% 
  mutate(Date = mdy(Date))
class(data$Date)

# Split column Date by year, month, and day
data <- mutate(data, Year = year(Date), 
               Month = month(Date),
               Day = day(Date))  

# Create columns to indicate if the data will be used for capture mark recapture
# analysis (CMR) and to add the protocol used to collect it. For training data
# change 'HMN' with TRAIN in line 96. If data was not collected with HMN's protocol
# change "Y" with "N" in same line
data <- mutate(data, CMR = "Y", Protocol = "HMN")

# Change multiple values required on the electronic KoBoToolbox form to NA  
data$Wing.Chord[data$Wing.Chord == "0"] <- NA
data$Culmen[data$Culmen == "0"] <- NA
data$CP.Breed[data$CP.Breed == "NOT TAKEN"] <- NA
data$Buffy[data$Buffy == "% GREEN"] <- NA

# Duplicate Band Status column to match columns' names in main database when 
# merging data frames  
data <- data %>% 
  mutate(Old.Band.Status = Band.Status)

# If any 'XXXXXX' in Band.Number, replace it with NA 
unique(data$Band.Number)
data <- data %>% 
  mutate(Band.Number = na_if(Band.Number, "XXXXXX"))

# Find duplicate band numbers
any(duplicated(data$Band.Number)) # Are there duplicate band numbers?
which(duplicated(data$Band.Number))  # Which one is duplicated? 

# If duplicates are found, resolve the issue manually in session's csv file 
# and run the code again before continuing with the data validation and 
# summarizing data for reports 

#### Data validation with pointblank package ####

# Set thresholds for report 
al <- action_levels(warn_at = 1, stop_at = 1) 

# Create pattern (regex) to validate if Band.Number is a letter and five numbers
pattern <- "[A-Z]{1}[0-9]{5}"

# Data validation. Most columns in the data frame will be validated in the agent    

validation <- 
  create_agent(
    tbl = data,
    tbl_name = "Vetted_data",
    label = "Data Validation",
    actions = al) %>% 
  col_is_date(vars(Date)) %>% 
  col_vals_in_set(vars(Bander), set = c("GS","ML","SMW","BJ","KO","TT","LY",
                                        "ER","AS")) %>%    
  col_vals_in_set(vars(Location), set = c("ML","HC","SWRS","PA","FH","DGS","MV",
                                          "MPGF","HSR","CFCK","ESC","WCAT")) %>%  
  col_vals_in_set(vars(Species), set = c("ANHU","ALHU","BBLH","BCHU","BADE",
                                         "BEHU","BTMG","BTLH","BUFH","BALO",
                                         "CAHU","COHU","LUHU","RIHU","HYHU",
                                         "RTHU","RUHU","VCHU","WEHU","UNHU")) %>%
  col_vals_in_set(vars(Sex), set = c("M","F","U",NA)) %>% 
  col_vals_in_set(vars(Age), set = c("0","1","2","5",NA)) %>% 
  col_vals_in_set(vars(Band.Status), set = c("1","R","F","4","5","6","8",NA)) %>%  
  col_vals_in_set(vars(Tarsus.Measurement), set = c("B","C","D","E","F","G","H",
                                                    "I","J","K","L","M","N","O",NA)) %>% 
  col_vals_in_set(vars(Band.Size), set = c("B","C","D","E","F","G","H","I","J",
                                           "K","L","M","N","O",NA)) %>% 
  col_vals_regex(vars(Band.Number), regex = pattern, na_pass = TRUE) %>% 
  col_vals_in_set(vars(Leg.Condition), set = c("1","2","3","4","5","6","7",NA)) %>%
  col_vals_regex(vars(Replaced.Band.Number), regex = pattern, na_pass = TRUE) %>%
  col_vals_in_set(vars(Gorget.Color), set = c("O","R","V","P","B","G","GP","NS",
                                              "LS","MS","HS",NA)) %>% 
  col_vals_between(vars(Gorget.Count),0, 99, na_pass = TRUE) %>% 
  col_vals_between(vars(Head.Count),0, 99, na_pass = TRUE) %>% 
  col_vals_in_set(vars(Grooves), set = c("0","1","2","3",NA)) %>% 
  col_vals_in_set(vars(Buffy), set = c("Y","N","S",NA)) %>%
  col_vals_in_set(vars(Bill.Trait), set = c("R", "D",NA)) %>% 
  col_vals_between(vars(Green.on.back),0, 99, na_pass = TRUE) %>%
  col_vals_between(vars(Wing.Chord),35.0, 79.0, na_pass = TRUE) %>%
  col_vals_between(vars(Culmen),12.0,34.0, na_pass = TRUE) %>%
  col_vals_in_set(vars(Fat), set = c("0","1","2","3","P","T",NA)) %>%
  col_vals_in_set(vars(CP.Breed), set = c("9","8","7","5","2",NA)) %>%
  col_vals_in_set(vars(Head.Gorget.Molt), set = c("1","2","3","F","L","M","R",NA)) %>%
  col_vals_in_set(vars(Body.Molt), set = c("1","2","3","F","L","M","R",NA)) %>%
  col_vals_in_set(vars(Primaries.Molt), set = c("1","2","3","4","5","6","7","8","9",
                                           "0","F","L","M","R",NA)) %>%
  col_vals_in_set(vars(Secondaries.Molt), set = c("1","2","3","4","5","6","F","L","M","R",NA)) %>%
  col_vals_in_set(vars(Tail.Molt), set = c("1","2","3","4","5","F","L","M","R",NA)) %>% 
  col_vals_between(vars(Weight), 2, 9, na_pass = TRUE)
  
# Interrogate creates a report after validation  
interrogate(validation)

# If report shows columns that didn't pass the validation (fail), get_sundered
# shows failed values by rows
interrogate(validation) %>% 
  get_sundered_data(type = "fail")

# If inconsistencies are found, for Band.Status, Band.Number and Species, resolve
# the issue manually in session's csv file and run the code again before continuing 
# with updating letter code in band number and summarizing data for reports.
# If inconsistencies with other columns are found, they can be resolved in final 
# csv created with this code and the end of script 

#### Replace letters in band numbers with Bird Banding Laboratory (BBL) codes ####

# Bring in BBL letter codes
letter_codes <- read.csv("data/BBL_letter_codes.csv")

# Separate letter from numbers in Band.Number column. Band numbers have six 
# digits, they are always 1 letter (A-Z) followed by five numbers (0-9)
data$band_letter <-substr(data$Band.Number,
                               start = 1, 
                               stop = 1)

data$band_number <- substr(data$Band.Number,
                                start = 2,
                                stop = 6)

# Create new column in data with band number containing BBL codes
BBL <- data %>% 
  left_join(letter_codes, 
             by = c("band_letter" = "letter"))

# Merge BBL code with numbers from Band.Number 
data <- BBL %>% 
  mutate(Band.Number.New = paste0(letter_number, band_number))

# Delete unnecessary columns created to assigned the BBL codes to band numbers
# Replace name in column Band.Number
data <- data %>% 
  select(-band_letter, 
         -band_number, 
         -letter_number, 
         -Band.Number) %>%
  relocate(Protocol, CMR, Bander, Location, Date, Year, Month, Day, Time, 
           Old.Band.Status, Band.Status, Band.Number.New, Leg.Condition, 
           Tarsus.Measurement, Band.Size, Species, Sex, Age, Replaced.Band.Number) %>%
  rename(Band.Number = Band.Number.New)

# Check new band numbers with BBL code 
unique(data$Band.Number)

#### Compare if recaptured birds coincide with band number, species, and sex to 
#### their first capture  #### 

# Bring in all band numbers used by HMN's monitoring program 
all_bands <- read.csv("data/updated_raw_data.csv",
                      na.strings = c("",NA))

# Change band number from character to numeric before sorting the data
all_bands$Band.Number <- as.numeric(as.character((all_bands$Band.Number)))
class(all_bands$Band.Number)

# Sort data by band number, species, age and sex
all_bands <- all_bands %>% 
  arrange(Band.Number, Species, Age, Sex)

# Extract recaptures from session's data
session_recaps <- data %>% 
  filter(Band.Status == "R") %>% 
  select(Band.Number, Species, Sex, Age, Location, Year)
  
# Check for inconsistencies with Band Numbers, species, age and sex for the 
# session's recaptures
for (BN in session_recaps$Band.Number) {
  original_caps <- all_bands %>% 
    filter(Band.Number == BN) %>% 
    select(Species, Sex, Age, Location) 
  if(nrow(original_caps) == 0){
    print(paste0("Band Number ", BN, " not in main database")) # Band number provably 
    next                    # applied in previous sessions of current monitoring year
  }
  if(original_caps$Species[1] != session_recaps$Species[session_recaps$Band.Number == BN]){
    print(paste0("Species code inconsistent for ", BN))
    message("Original species for ", BN , " was ",  original_caps$Species)
  }
  if(original_caps$Sex[1] != session_recaps$Sex[session_recaps$Band.Number == BN]){
    print(paste0("Sex code inconsistent for ", BN))
    message("Original sex for ", BN , " was ",  original_caps$Sex)
  }
  if(original_caps$Age[1] != session_recaps$Age[session_recaps$Band.Number == BN]){
    print(paste0("Age code inconsistent for ", BN))
    message("Original Age for ", BN , " was ", original_caps$Age )
  }
  if(original_caps$Location[1] != session_recaps$Location[session_recaps$Band.Number == BN]){
    print(paste0("Location code inconsistent for ", BN))
    message("Original location for ", BN , " was ",  original_caps$Location)
  }
}

# If inconsistencies are found, resolve them manually in final csv file created with this code 

#### Check for session's recaps Age ####

# Find first capture year for all bands   
first_capture <- all_bands %>% 
  group_by(Band.Number) %>% 
  summarize(spp = Species[1],
            sex = Sex[1],
            age = Age[1],
            location = Location[1],
            first_year_captured = min(year))

# Check for session's recaptures Age 
for (BN in session_recaps$Band.Number) {
  first_cap <- first_capture %>% 
    filter(Band.Number == BN) %>% 
    select(spp, sex, age, location, first_year_captured) 
  if(nrow(first_cap) == 0){
    print(paste0("Band Number ", BN, " not in main database"))
    next
  }
  if(first_cap$first_year_captured[1] != session_recaps$Year[session_recaps$Band.Number == BN]){
    message(first_cap$spp," ", first_cap$sex," ", BN , " banded in ", first_cap$first_year_captured)
  }
}

#### Get summarized data for reports #### 

# Number of individuals by Band Status, new birds=1, recaptures=R
data %>% 
  count(Band.Status)

# Number of individuals by species
data %>% 
  count(Species)  

# Number of recaptures multiple times a day
data %>% 
  count(Day.Recaptures)

#### Create new csv with the validated data ####

# Create csv with vetted data. Make sure to update the location code and date in 
# the output name  
write.csv(vetted_data,"output/vetted_HC_data.csv", row.names = FALSE)




