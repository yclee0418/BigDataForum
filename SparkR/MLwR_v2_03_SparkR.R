# init sparkR session
if (nchar(Sys.getenv("SPARK_HOME")) < 1) {
  Sys.setenv(SPARK_HOME = "...")
}
library(SparkR, lib.loc = c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib")))
sparkR.session(master = "local[*]", sparkConfig = list(spark.driver.memory = "2g"))

##### Chapter 3: Classification using RandomForest SparkR Version--------------------
filePath <- "/Machine Learning with R (2nd Ed.)/Chapter 03/wisc_bc_data.csv"

wbcd <- read.df(filePath, "csv", header = "true", inferSchema = "true", na.strings = "NA")
str(wbcd)
head(wbcd)

## drop the id feature
wbcd <- select(wbcd, names(wbcd)[-1])
str(wbcd)
createOrReplaceTempView(wbcd, "wbcd")

#generate aggrate sql
sql <- c()
for (col in names(wbcd)[2:31]) 
	sql <- c(sql, paste0("min(", col , ") as ", col ,"_min"), paste0("max(", col , ") as ", col ,"_max"))
selcols <- paste(sql, sep="",collapse=",")
selsql <- paste("select ", selcols, " from wbcd", sep="",collapse="")
aggTable <- sql(selsql)
createOrReplaceTempView(aggTable, "aggTable")



# table of diagnosis
showDF(count(groupBy(wbcd, "diagnosis")))

# summarize three numeric features
showDF(describe(wbcd, "radius_mean", "area_mean", "smoothness_mean"))
#find median
lmedian <- list(median_radius=approxQuantile(wbcd, "radius_mean", c(0.5), 0.0)[[1]],
	median_area=approxQuantile(wbcd, "area_mean", c(0.5), 0.0)[[1]],
	smoothness_area=approxQuantile(wbcd, "smoothness_mean", c(0.5), 0.0)[[1]])

#generate min-max normalized df
#select  (radius_mean-radius_mean_min)/(radius_mean_max-radius_mean_min) as radius_mean from wbcd, aggTable where 1 = 1
sql <- c()
for (col in names(wbcd)[2:31]) 
	sql <- c(sql, paste0("(",col , "-" ,col, "_min)/(",col,"_max-",col,"_min) as ", col))
selcols <- paste(sql, sep="",collapse=",")
selsql <- paste("select (case diagnosis when 'B' then 1 else 0 end) as diagnosis, ", selcols, " from wbcd, aggTable where radius_mean_min-1 <> radius_mean", sep="",collapse="")
wbcd_n <- sql(selsql)
showDF(describe(wbcd_n, "radius_mean", "area_mean", "smoothness_mean"))

#split train data & test data
wbcd_train_test <- randomSplit(wbcd_n, c(0.75,0.25), 0)
wbcd_n_train <- wbcd_train_test[[1]]
wbcd_n_test <- wbcd_train_test[[2]]
#show proportion of diagnosis
showDF(count(groupBy(wbcd_n_train, "diagnosis")))
showDF(count(groupBy(wbcd_n_test, "diagnosis")))

# train model with randomForest for classification
model <- spark.randomForest(wbcd_n_train, diagnosis ~ ., "classification")
summary(model)
#make prediction
predictions <- predict(model, wbcd_n_test)
head(predictions)

#translate SparkDataFrame to R data.frame
pred_t <- as.data.frame(select(predictions, "diagnosis", "prediction"))
str(pred_t)

pred_t$prediction <- as.integer(pred_t$prediction)

#calcuate F-measure
measurePrecisionRecall <- function(predict, actual_labels){
  precision <- sum(predict & actual_labels) / sum(predict)
  recall <- sum(predict & actual_labels) / sum(actual_labels)
  fmeasure <- 2 * precision * recall / (precision + recall)

  cat('precision:  ')
  cat(precision * 100)
  cat('%')
  cat('\n')

  cat('recall:     ')
  cat(recall * 100)
  cat('%')
  cat('\n')

  cat('f-measure:  ')
  cat(fmeasure * 100)
  cat('%')
  cat('\n')
}

measurePrecisionRecall(pred_t$prediction, pred_t$diagnosis)
#precision:  96.1039%
#recall:     97.36842%
#f-measure:  96.73203%

############ bayes ########################
#categorize wbcd by ntile(n)

#select ntile(4) over (order by radius_mean) as radius_mean, .... from wbcd
sql <- c()
for (col in names(wbcd)[2:31]) 
  sql <- c(sql, paste0("ntile(2) over (order by ", col , ")-1 as ", col))
selcols <- paste(sql, sep="",collapse=",")
selsql <- paste("select (case diagnosis when 'B' then 1 else 0 end) as diagnosis, ", selcols, " from wbcd", sep="",collapse="")
wbcd_b <- sql(selsql)
#split train data & test data
wbcd_train_test_b <- randomSplit(wbcd_b, c(0.75,0.25), 0)
wbcd_b_train <- wbcd_train_test_b[[1]]
wbcd_b_test <- wbcd_train_test_b[[2]]
#show proportion of diagnosis
showDF(count(groupBy(wbcd_b_train, "diagnosis")))
showDF(count(groupBy(wbcd_b_test, "diagnosis")))

#train Bayes model
model <- spark.naiveBayes(wbcd_b_train, diagnosis ~ ., smoothing = 0)
summary(model)
#make prediction
predictions <- predict(model, wbcd_b_test)
head(predictions)

#translate SparkDataFrame to R data.frame
pred_t <- as.data.frame(select(predictions, "diagnosis", "prediction"))
str(pred_t)

pred_t$prediction <- as.integer(pred_t$prediction)
measurePrecisionRecall(pred_t$prediction, pred_t$diagnosis)
#precision:  92%
#recall:     90.78947%
#f-measure:  91.39073%