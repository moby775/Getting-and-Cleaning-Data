library(data.table)
library(reshape2)
setwd("C:/Users/Zhi Rong/Desktop/Datascience/Getting and Cleaning Data")
path <- getwd()
## create directory
if(!file.exists("Project")){
    dir.create("Project")
}

## download and unzip file
fileUrl <-"https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
path <- getwd()
folder<-file.path(path,"Project")
filename<-"data.zip"
f<-file.path(folder,filename)
download.file(fileUrl,f)
setwd(folder)
unzip(f)

##read the files
train_folder<-"UCI HAR Dataset/train"
test_folder<-"UCI HAR Dataset/test"
dtSubjectTrain<-fread(file.path(folder,train_folder,"subject_train.txt"))
dtSubjectTest<-fread(file.path(folder,test_folder,"subject_test.txt"))
dtLabelTrain<-fread(file.path(folder,train_folder,"y_train.txt"))
dtLabelTest<-fread(file.path(folder,test_folder,"y_test.txt"))
dfSetTrain<-read.table(file.path(folder,train_folder,"X_train.txt"))
dtSetTrain<-data.table(dfSetTrain)
dfSetTest<-read.table(file.path(folder,test_folder,"X_test.txt"))
dtSetTest<-data.table(dfSetTest)

##merge training and test data rows
dtSubject<-rbind(dtSubjectTrain,dtSubjectTest)
setnames(dtSubject,"V1","Subject")
dtActivity<-rbind(dtLabelTrain,dtLabelTest)
setnames(dtActivity,"V1","Activity")
dtSet<-rbind(dtSetTrain,dtSetTest)

##Requirement 1: Merges the training and the test sets to create one data set.

##merge the columns
dt <- cbind(dtSubject,dtActivity)
dt <- cbind(dt,dtSet)
setkey(dt,Subject,Activity)
##End of Requirement 1

##Requirement 2: Extracts only the measurements on the mean and standard 
##deviation for each measurement. 
dtFeatures<-fread(file.path(folder,"UCI HAR Dataset","features.txt"))
setnames(dtFeatures,names(dtFeatures), c("FeatureNumber", "FeatureDescription"))
setnames(dtSet,names(dtSet),dtFeatures$FeatureDescription)
FeaturesMeanStd <- grepl("mean|std", dtFeatures$FeatureDescription)
dtSetMeanStd <- dtSet[,FeaturesMeanStd,with=FALSE]
dtMeanStd <- cbind(dtSubject,dtActivity)
dtMeanStd <- cbind(dtMeanStd,dtSetMeanStd)
setkey(dtMeanStd,Subject,Activity)
##End of Requirement 2


##Requirement 3: Uses descriptive activity names to name 
##the activities in the data set

##read the activity labels first
dtActivityLabels <- fread(file.path
                          (folder,"UCI HAR Dataset/", "activity_labels.txt"))
setnames(dtActivityLabels,names(dtActivityLabels), c("Activity","Description"))
setkey(dtActivityLabels,Activity)

## merge activity labels to the Activity dataset
## merge data.table is always sorted,thus convert to data frame for merging
dtActivitywText <- merge(as.data.frame(dtActivity),
                         as.data.frame(dtActivityLabels),all=TRUE,sort=FALSE)
dtActivitywText<- data.table(dtActivitywText)

##Requirement 4:Appropriately labels the data set with descriptive variable names. 
setnames(dtSet,names(dtSet),dtFeatures$FeatureDescription)

##merge the columns again with descriptive activity and variable names.
dt <- cbind(dtSubject,dtActivitywText)
dt <- cbind(dt,dtSet)
setkey(dt,Subject,Activity)
##End of Requirement 3 & 4 

##Requirement 5:From the data set in step 4, creates a second, independent tidy data set 
##with the average of each variable for each activity and each subject.
TidyKeys <- c("Subject","Activity","Description")
TidyVariables <- setdiff(colnames(dt),TidyKeys)
##Melting the dataset
dtMelt <- melt(dt,id=TidyKeys,measure.vars=TidyVariables)
##casting the dataset
TidyData <- dcast(dtMelt,Subject+Activity+Description~variable,mean)
write.table(TidyData, file = "./TidyData.txt",row.name=FALSE)
##End of Requirement 5