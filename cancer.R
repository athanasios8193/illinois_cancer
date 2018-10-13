# THE DATA USED IN THIS ANALYSIS IS TAKEN FROM
# http://www.idph.state.il.us/cancer/statistics.htm
# IN ORDER TO DOWNLOAD THE ZIP CODE DATASET THAT I USE, DOWNLOAD THE 'ZPCD8615.EXE' FILE AND FOLLOW THE PROMPTS

## THESE TWO PACKAGES ARE NECESSARY FOR SOME TABLE OPERATIONS AND GRAPHICS
library(dplyr)
library(ggplot2)
library(leaflet)
library(RColorBrewer)

library(tigris)
library(rgeos)
library(sp)

data <- read.delim("./Data/zpcd8615.dat", sep="\t", header=FALSE, stringsAsFactors = FALSE)

## SEPARATING ON 3 SPACES BECAUSE THAT'S HOW THE DATA IS PRESENTED IN THE .DAT FILE
test <- strsplit(data$V1, "   ")

## USING STRSPLIT PUTS EACH LINE FROM THE ORIGINAL DATA VECTOR INTO A LIST. BY USING THE '[' FUNCTION,
## WITHIN SAPPLY, YOU UNLIST EACH LINE OF THE VECTOR INTO 2 ENTRIES AND THEN TAKE THE TRANSPOSE.
mat <- t(sapply(test, '['))

## THROUGHOUT THE CODE I WILL BE REMOVING OBJECTS THAT ARE NO LONGER NEEDED TO PRESERVE MEMORY.
rm(test)

## THIS SIMPLY TAKES THE MATRIX MADE IN THE STEP ABOVE AND CONVERTS IT TO A DATAFRAME WHICH IS BETTER TO WORK WITH
data <- data.frame(mat,stringsAsFactors = FALSE)

rm(mat)

## THE FOLLOWING FEW COMMANDS SUBSET THE STRING IN THE FIRST COLUMN OF THE DATAFRAME. THE README INCLUDED
## WITH THE DATASET HAS A KEY ON WHAT EACH OF THE DIGITS IN THE STRING MEAN. HERE I TURN EACH ONE INTO ITS OWN
## COLUMN IN THE DATA FRAME.
data$sex <- substr(data[,1], 1,1)
data$years <- substr(data[,1], 2,2)
data$zip <- substr(data[,1], 3,7)
data$age <- substr(data[,1], 11,11)
data$type <- substr(data[,1],9,10)
data$lat <- substr(data[,1], 12,24)
data$long <- data$X2

## HERE I AM REMOVING THE FIRST TWO COLUMNS OF THE DATA FRAME WHICH WERE THE ORIGINAL COLUMNS IN THE DATASET.
## NOW THAT I HAVE EXTRACTED ALL THE RELEVANT INFORMATION FROM THEM, THEY ARE WORTHLESS AND ARE TAKING UP SPACE.
data <- data[,-c(1,2)]

## I AM EXCLUDING THE STAGE OF CANCER AT DIAGNOSIS FOR NOW BECAUSE I DON'T KNOW IF IT HAS THAT MUCH VALUE FOR THIS ANALYSIS.
## FEEL FREE TO INCLUDE IT IF YOU WANT. I HAVE MORE STEPS FURTHER ON FOR DEALING WITH THIS VARIABLE.
# data$stage_at_diagnosis <- substr(data[,1], 8,8)

## CONVERTS EACH OF THESE COLUMNS TO NUMERIC VALUES SO THAT I CAN REPLACE THE VALUES LATER ON IN THE ANALYSIS WITH
## TEXT FOR EASIER READABILITY AND INTERPRETABILITY
data$sex <- as.numeric(data$sex)
data$years <-as.numeric(data$years)
data$zip <- as.numeric(data$zip)
data$age <- as.numeric(data$age)
data$type <- as.numeric(data$type)
data$lat <- as.numeric(data$lat)
data$long <- as.numeric(data$long)
# data$stage_at_diagnosis <-as.numeric(data$stage_at_diagnosis)

# Here I am re-numbering the stage information from the original values to 1-5 so that I can change the names within the
# dataframe easier using an R trick. Since the values are coded anyways, this doesn't affect the data at all.
# data[data$stage_at_diagnosis==9,6] <- 5
# data[data$stage_at_diagnosis==3,6] <- 4
# data[data$stage_at_diagnosis==2,6] <- 3
# data[data$stage_at_diagnosis==1,6] <- 2
# data[data$stage_at_diagnosis==0,6] <- 1

## THESE ARE THE 'CODES' FROM THE README INCLUDED IN THE DATASET.
sexcode <- c('male', 'female')
diagnosisyear <- c('1986-1990', '1991-1995', '1996-2000', '2001-2005', '2006-2010', '2011-2015')
agegroup <- c('0-14', '15-44', '45-64', '65+')
cancertype <- c('oral cavity and pharynx', 'colorectal', 'lung and bronchus',
                'breast invasive-female', 'cervix', 'prostate', 'urinary system',
                'central nervous system', 'lukemias and lymphomas', 'all other cancers',
                'breast in-situ-female')
# stage <- c('in-situ', 'localized', 'regional', 'distant metasteses', 'unknown')

## IN THIS STEP, EACH OF THE COLUMNS IN THE DATA FRAME ARE READING THE 'CODES' ENTERED ABOVE
## AND IF THE VALUE IN THE COLUMN MATCHES THE INDEX OF THE VALUE OF THE 'CODE', IT IS REPLACED BY THAT
## VALUE OF THE 'CODE.' THAT'S WHY IN THE STAGE AT DIAGNOSIS COLUMN I REASSIGNED NUMBERS FROM 1-5.
data[,1] <- sexcode[data[,1]]
data[,2] <- diagnosisyear[data[,2]]
data[,4] <- agegroup[data[,4]]
data[,5] <- cancertype[data[,5]]
# data[,8] <- stage[data[,8]]

rm(sexcode)
rm(diagnosisyear)
rm(agegroup)
rm(cancertype)
# rm(stage)

## HERE I AM SAVING THE CLEANED, READABLE DATA OUTPUT TO A .CSV SO ANYONE CAN USE IT AN FIND WHATEVER THEY CAN
#write.csv(data, file="./Data/il_cancer.csv", row.names=FALSE)

## I AM USING THESE VALUES FOR THE YEARS BECAUSE IN 2000 THE STATE OF ILLINOIS CHANGED ZIP CODE BOUNDARIES
## SO I DON'T WANT TO MISREPRESENT THE FINDINGS TO INCLUDE CANCER CASES OUTSIDE OF THE RADIUS OF INTEREST.
since2000 <- c('2001-2005', '2006-2010', '2011-2015')

## THESE ZIPCODES ARE THE ONES CLOSEST TO THE STERIGENICS PLANTS IN WILLOWBROOK.
zipcodes <- c(60527, 60439, 60561, 60521, 60558, 60514, 60559, 60525, 60480, 60515, 60516, 60517)

## HERE I AM SUBSETTING THE DATA FRAME TO INCLUDE ONLY THOSE CANCER CASES DIAGNOSED AFTER 2000.
datasub <- subset(data, years %in% since2000)

## IN THIS STEP I SUBSET THE DATA FRAME TO INCLUDE ONLY THE ZIP CODES NEAREST TO STERIGENICS
datalocal <- subset(data, zip %in% zipcodes)

## IN THIS STEP I SUBSET THE 'datasub' DATA EVEN FURTHER TO INCLUDE ONLY CASES WITHIN THE AREA OF INTEREST.
datalocalsub <- subset(datasub, zip %in% zipcodes)

## IN THIS STEP I SUBSET THE 'datasub' DATA TO INCLUDE ALL CASES EXCEPT THE ONES WITHIN THE AREA OF INTEREST.
datarestsub <- subset(datasub, !(zip %in% zipcodes))

## THIS VALUE FOR THE POPULATION OF ILLINOIS WAS TAKEN FROM THE 2010 US CENSUS
pop_illinois <- 12830632
num_cases <- nrow(datasub)
num_cases_per_year <- num_cases/15
one_in_every_il <- pop_illinois/num_cases_per_year
per_100000_il_per_year <- num_cases_per_year*100000/pop_illinois

## THIS CSV WITH ILLINOIS POPULATION DATA PER ZIP CODE WAS FOUND ON THE US CENSUS 'FACT FINDER' SITE
## GO TO https://factfinder.census.gov THEN SELECT THE 'DOWNLOAD CENTER' TAB
## SELECT 'I KNOW THE DATASETS OR TABLES THAT I WANT TO DOWNLOAD, CLICK 'NEXT'
## SELECT 'DECENNIAL CENSUS' IN THE FIRST DROPDOWN
## SELECT '2010 SF1 100% DATA' IN THE SECOND DROPDOWN, CLICK 'AD TO YOUR SELECTIONS,' THEN CLICK 'NEXT'
## IN THE 'GEOGRAPHIES' TAB, SELECT '5-DIGIT ZIP CODE TABULATION AREA - 860', THEN SELECT 'ILLINOIS'
## CLICK THE 'ALL 5-DIGIT....' THEN 'ADD TO YOUR SELECTIONS,' THEN CLICK 'NEXT'
## SELECT THE FILE CALLED 'TOTAL POPULATION' AND CLICK 'DOWNLOAD'
## A .ZIP FILE WILL BE DOWNLOADED TO WHEREVER YOU SELECT ON YOUR COMPUTER.
## THE FILE WITHIN THE .ZIP IS CALLED 'DEC_10_SF1_P1_WITH_ANN.CSV' I CHANGED THE NAME WHEN I COPIED IT
ilpop <- read.csv('./Data/il_2010_populations.csv', header=TRUE, skip=1)

## THE FIRST AND THIRD COLUMNS ARE WORTHLESS TO US SO I GET RID OF THEM
ilpop <- ilpop[,-c(1,3)]
colnames(ilpop) <- c('zip', 'population')

## HERE I AM COUNTING, BY ZIP CODE, THE NUMBER OF INSTANCES FROM THE DATA SUBSET BY AGE AND AFTER 2000
# ilcancer <- datasub %>% count(zip)
ilcancer <- datasub %>% group_by(zip, lat, long) %>% count()
ilcancer <- as.data.frame(ilcancer)
colnames(ilcancer) <- c('zip', 'lat', 'long', 'freq')

## BY DOING A LEFT JOIN, WE MERGE THE TWO DATA FRAMES ON THE 'zip' COLUMN, KEEPING ONLY THE VALUES FROM THE
## 'ilcancer' DATA FRAME THAT ALSO APPEAR IN THE 'ilpop' DATA FRAME.
cancer <- left_join(ilpop, ilcancer)
cancer <- subset(cancer, complete.cases(cancer))
cancer$per_year <- cancer$freq/15
cancer$one_in_every_per_year <- cancer$population/cancer$per_year
cancer$per_100000_per_year <- cancer$per_year*100000/cancer$population
cancer$zip_vs_state <- cancer$per_100000_per_year/per_100000_il_per_year

## SAVING A CSV OF THIS NEW DATA WITH THE STATISTICS FOR EACH ZIP CODE
#write.csv(cancer, './Data/il_cancer_statistics.csv', row.names = FALSE)

## THE LOCAL AREA
cancer_local <- subset(cancer, zip %in% zipcodes)
cancer_local <- arrange(cancer_local, desc(zip_vs_state))

## THE REST OF THE STATE OUTSIDE OF THE STERIGENICS AREA
cancer_rest <- subset(cancer, !(zip %in% zipcodes))
cancer_rest <- arrange(cancer_rest, desc(zip_vs_state))

## THE REST OF THE STATE WITH POPULATION BEING GREATER THAN 5000 PEOPLE
cancer_rest_big <- subset(cancer_rest, population > 5000)

## T-TESTS COMPARING LOCAL RATES TO REST OF STATE RATES
test1 <- t.test(cancer_local$per_100000_per_year, cancer_rest$per_100000_per_year, alternative = 'greater')
test2 <- t.test(cancer_local$per_100000_per_year, cancer_rest_big$per_100000_per_year, alternative = 'greater')

## CHI-SQUARE TEST
local_cancer <- sum(cancer_local$freq)/15
local_no_cancer <- sum(cancer_local$population)/15-local_cancer
rest_cancer <- sum(cancer_rest_big$freq)/15
rest_no_cancer <- sum(cancer_rest_big$population)/15 - rest_cancer
cont <- matrix(c(local_cancer, local_no_cancer, rest_cancer, rest_no_cancer), nrow=2)
cont <- round(cont, 0)
rownames(cont) <- c('Sterigenics Area', 'Rest of State')
colnames(cont) <- c('Cancer', 'No Cancer')
chisq.test(cont)

## CREATING A MAP OF THE LOCAL DATA

## DOWNLOADING SHAPE FILE FROM THE TIGRIS PACKAGE TO GET OUTLINES OF THE ZIP CODES
datashp <- zctas(cb = TRUE, starts_with = zipcodes)

data_map <- merge(datashp, cancer_local, by.x = 'GEOID10', by.y ='zip')

n <- leaflet(data_map) %>% addTiles()
n <- n %>% addMarkers(lat = ~lat, lng = ~long, 
                      popup=~paste('Per 100,000: ', as.character(round(per_100000_per_year, 2)), '<br>',
                                   'ZIP Code vs State: ', as.character(round(zip_vs_state, 2))),
                      label=~paste('Geographic Center of ', GEOID10, ' ZIP Code'))
n <- n %>% addPolygons(data=data_map, weight=2, opacity = 1, fillOpacity = 0.5,
                       fillColor = ~colorQuantile('Greys', per_100000_per_year)(per_100000_per_year))
n <- n %>% addCircles(lat = 41.747375, lng = -87.939954,
                      label = 'Sterigenics Plant Radius',
                      color=rev(brewer.pal(8, 'Spectral')),
                      radius = rev(seq(8))*804.672, opacity = 1, fillOpacity = 0.15)

## CREATING A DATA FRAME TO SHOW THE PROPORTION OF ZIP CODES GREATER THAN ILLINOIS AT CERTAIN THRESHOLDS 
cancer_greater <- c(nrow(subset(cancer, zip_vs_state > 1))/nrow(cancer),
                    nrow(subset(cancer, zip_vs_state > 1.05))/nrow(cancer),
                    nrow(subset(cancer, zip_vs_state > 1.10))/nrow(cancer),
                    nrow(subset(cancer, zip_vs_state > 1.15))/nrow(cancer),
                    nrow(subset(cancer, zip_vs_state > 1.20))/nrow(cancer))
cancer_local_greater <- c(nrow(subset(cancer_local, zip_vs_state >1))/nrow(cancer_local),
                          nrow(subset(cancer_local, zip_vs_state >1.05))/nrow(cancer_local),
                          nrow(subset(cancer_local, zip_vs_state >1.10))/nrow(cancer_local),
                          nrow(subset(cancer_local, zip_vs_state >1.15))/nrow(cancer_local),
                          nrow(subset(cancer_local, zip_vs_state >1.20))/nrow(cancer_local))
cancer_greater_both <- data.frame('Entire_State'=cancer_greater,
                                  'Area_of_Interest'=cancer_local_greater,
                                  row.names = c('Greater_than_Illinois', '5%_Greater_than_Illinois',
                                                '10%_Greater_than_Illinois', '15%_Greater_than_Illinois',
                                                '20%_Greater_than_Illinois'))

## GETTING THE DATA TOGETHER TO PLOT THE DATA FROM 2001-2015 FOR EACH ZIP CODE AND FOR THE STATE OF ILLINOIS AS A WHOLE
local_counts <- datalocalsub %>% group_by(years) %>% count(zip)
local_counts$zip <- as.character(local_counts$zip)

illinois_counts <- datasub %>% group_by(years) %>% count()
illinois_counts$zip <- c('Illinois', 'Illinois', 'Illinois')
illinois_counts <- illinois_counts[,c(1,3,2)]


counts <- rbind(local_counts, illinois_counts)


##############
##############
##############

## TRYING OUT SIMULATING DATA TO SEE STATISTICAL SIGNIFICANCE BETWEEN RANDOM SAMPLES OF 12 ZIP CODES
## FROM THE REST OF THE STATE WITH POPULATION > 5000

set.seed(538)
cancer_rest_big_less <- subset(cancer_rest_big, population < 32500)
num_sims <- 32500:max(cancer_rest_big)


p <- replicate(num_sims, t.test(cancer_local$per_100000_per_year, subset(cancer_rest_big_less, population < num_sims)$per_100000_per_year,
                                alternative = 'greater')$p.value)

ggplot(data.frame(p=p), aes(x=p)) + geom_histogram(bins=100) + geom_vline(xintercept=0.055, lwd=1, color='red')

p <- rep(NA, times=length(num_sims))

for (i in num_sims) {
        p[(i-min(num_sims))] <- t.test(cancer_local$per_100000_per_year, subset(cancer_rest_big, population < i)$per_100000_per_year)$p.value
}

ggplot(data.frame(p=p), aes(x=p)) + geom_histogram(bins=100) + geom_vline(xintercept=0.055, lwd=1, color='red')