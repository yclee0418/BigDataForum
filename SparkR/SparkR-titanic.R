source("E:/spark-2.1.0/R/initSparkR.R")
#titanic <- read.df("titanic.txt", "csv", header = "true", inferSchema = "true", na.strings = "NA", sep='\t')
titanic <- read.df("/Users/yungchuanlee/Dropbox/learn/R/titanic.txt", "csv", header = "true", inferSchema = "true", na.strings = "NA", sep='\t')

#show structure of data
str(titanic) 
# summarize three numeric features
ci <- 0
colts <- coltypes(titanic)
for (coln in columns(titanic)) { 
  ci <- ci+1
  isNum <- colts[ci]=='numeric' || colts[ci] == 'integer'
  if (isNum) {
    print(coln)
    showDF(describe(titanic, coln))
  }
}
print("Count null values: ")
ci <- 0
for (coln in columns(titanic)) { 
  ci <- ci+1
  col <- column(coln)
  #count null value for each column  
  nullCnt <- count(filter(titanic, isNull(col)))
  isNum <- colts[ci]=='numeric' || colts[ci] == 'integer'
  if (nullCnt > 0) {
    if (isNum) {
      med <- approxQuantile(titanic, coln, c(0.5), 0.0)[[1]]
      print(paste0(coln, ' null count: ', nullCnt, ', median:', med))
    } else {
      print(paste0(coln, ': ', nullCnt))
    }
  }
}

#fill na value
naCols <- c("Age")
titanic <- fillna(titanic, 28, cols = naCols)

showProp <- function(trainData, testData) {
  print('train data table of Survived:')
  traindf <- collect(count(groupBy(trainData, trainData$Survived)))
  traindf$prop <- traindf$count/sum(traindf$count)
  print(traindf)
  print('test data table of Survived:')
  testdf <- collect(count(groupBy(testData, testData$Survived)))
  testdf$prop <- testdf$count/sum(testdf$count)
  print(testdf)
}

titanic_train_test <- randomSplit(titanic, c(0.85,0.15), 1234)
titanic_train <- titanic_train_test[[1]]
titanic_test <- titanic_train_test[[2]]
showProp(titanic_train, titanic_test)

doTrainRF <- function(trainData) {
  model <- spark.randomForest(trainData, Survived ~ Age+PClass_1st+PClass_2nd+Sex_female+Title_Miss+Title_Mr+Title_Mrs, type = "classification", maxDepth = 5, maxBins = 32,
  numTrees = 5)
}

doTrainGlm <- function(trainData) {
  model <- glm(Survived ~Age+PClass_1st+PClass_2nd+Sex_female+Title_Miss+Title_Mr+Title_Mrs, family = 'binomial', data=trainData)
}

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

doPredict <- function(model, testData) {
  predictions <- predict(model, testData)
  head(predictions)
  pred_t <- as.data.frame(select(predictions, "Survived", "prediction"))
  pred_t$prediction <- ifelse(pred_t$prediction > 0.5, 1, 0)  
  #pred_t$prediction <- as.integer(pred_t$prediction)
  measurePrecisionRecall(pred_t$prediction, pred_t$Survived)
}

#model <- doTrainRF(select(titanic_train, names(titanic_train)[-1]))
model <- doTrainGlm(select(titanic_train, names(titanic_train)[-1]))
doPredict(model, select(titanic_test, names(titanic_test)[-1]))
#f-measure:  68.71795%


####### feature engineering ##############
#add Title feature from Name
addFeatures <- function(titanic) {
    titanic <- selectExpr(titanic, 
      "*", "(case when Name like '%Mr %' then 'Mr' when Name like '%Mrs %' then 'Mrs' when Name like '%Miss%' then 'Miss' else 'Nothing' end) as Title")
    #remove Name feature
    titanic <- select(titanic, names(titanic)[-1])
    #binarize char feature
    ci <- 0
    colts <- coltypes(titanic)
    titanic_new <- titanic
    for (coln in columns(titanic)) { 
      ci <- ci+1
      isChar <- colts[ci]=='character' 
      if (isChar) {
        print(coln)
        #extract factor
        df_t<-collect(distinct(select(titanic, coln)))
        #if (dim(df_t)[1]>2) {
          for (newcol in df_t[,coln]) {
            if (!base::is.na(newcol)) {
              #generate PClass_1st PClass_2nd PClass_3rd Sex_female Sex_male Title_Miss Title_Mr Title_Mrs Title_Nothing
              df_t[, paste0(coln,"_", newcol)] <- ifelse(df_t[,coln]==newcol,1,0)
            }
          }

          #print(df_t)
          dfDT <- createDataFrame(df_t)
          #join titanic with dfDT
          titanic_new <- merge(titanic_new, dfDT, by.x=coln, by.y=coln)
          #remove origin feature, left binarize feature only
          titanic_new <- select(titanic_new, names(titanic_new)[!(names(titanic_new) %in% c(paste0(coln,"_x"),paste0(coln,"_y")))])
        #}
      }
    }
    titanic <- titanic_new
}

titanic_train2 <- addFeatures(titanic_train)
titanic_test2 <- addFeatures(titanic_test)
#model <- doTrainRF(titanic_train2)
model <- doTrainGlm(titanic_train2)
doPredict(model, titanic_test2)



