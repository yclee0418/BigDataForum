df <- read.csv("sparkPage.txt", header=FALSE)
head(df)

#install.packages("tm")
#install.packages("SnowballC")
#install.packages("wordcloud")

library(tm)

sms_corpus <- VCorpus(VectorSource(df$V1))

# examine the sms corpus
print(sms_corpus)
inspect(sms_corpus[1:2])

as.character(sms_corpus[[1]])
lapply(sms_corpus[1:2], as.character)

showWords <- function(sms_corpus_clean) {
	words <- c()
	for (x in c(1:length(sms_corpus_clean)))  words <- c(words, as.character(sms_corpus_clean[[x]]))
	words
}

# clean up the corpus using tm_map()
sms_corpus_clean <- tm_map(sms_corpus, content_transformer(tolower))

# show the difference between sms_corpus and corpus_clean
#as.character(sms_corpus[[1]])
#as.character(sms_corpus_clean[[1]])
sms_corpus_clean <- tm_map(sms_corpus_clean, removeWords, stopwords());as.character(sms_corpus_clean[[166]]) # remove stop words
sms_corpus_clean <- tm_map(sms_corpus_clean, removeNumbers);as.character(sms_corpus_clean[[166]]) # remove numbers
sms_corpus_clean <- tm_map(sms_corpus_clean, removePunctuation);as.character(sms_corpus_clean[[166]]) # remove punctuation


# illustration of word stemming

library(SnowballC)

sms_corpus_clean <- tm_map(sms_corpus_clean, stemDocument);as.character(sms_corpus_clean[[166]])
sms_corpus_clean <- tm_map(sms_corpus_clean, stripWhitespace);as.character(sms_corpus_clean[[166]]) # eliminate unneeded whitespace
sms_corpus_clean <- tm_map(sms_corpus_clean, removeWords, c(stopwords(), "can", "classcaretb", "classcolmd","colsm","div","html","li")) # remove stop words



sms_dtm <- DocumentTermMatrix(sms_corpus_clean)
sms_freq_words <- findFreqTerms(sms_dtm, 4);length(sms_freq_words);sms_freq_words

# examine the final clean corpus
#lapply(sms_corpus[1:3], as.character)
#lapply(sms_corpus_clean[1:3], as.character)

# create a document-term sparse matrix



library(wordcloud)

wordcloud(sms_corpus_clean, min.freq = 4, random.order = FALSE, scale = c(3, 0.5))

