library(tidyverse)
library(reticulate)
twint <- import("twint")
pandas <- import("pandas")
library(tidytext)
library(textdata)
nrc <- get_sentiments("nrc")
library(RSQLite)
library(taskscheduleR)

#Python
c <- twint$Config()
c$Search <- "Google"
#For the sake of this example, we will analyze negative sentiment about Google
c$Limit <- 100 
#Limit of 100 tweets because I think this will be my PC's limit to keep up with the task schedule
c$Since <- format(Sys.time()-60, tz = "UTC")
c$Utc <- TRUE
c$Full_text <- TRUE
c$Pandas <- TRUE
c$Language <- "en"
c$Filter_retweets <- TRUE
c$Hide_output <- TRUE
twint$run$Search(c)
df <- as.data.frame(twint$storage$panda$Tweets_df)


#Cleaning and Formatting Data
df$hashtags <- paste(lapply(df$hashtags, FUN = toString))
#turning vectorized row entries into single-string lists
#the DB will not accept them as vectors
df$cashtags <- paste(lapply(df$cashtags, FUN = toString))
df$urls <- paste(lapply(df$urls, FUN = toString))
df$photos <- paste(lapply(df$photos, FUN = toString))
df$reply_to <- paste(lapply(df$reply_to, FUN = toString))
df <- df %>% mutate(tweet_analysis = tweet)
df$tweet_analysis <- tolower(df$tweet_analysis)
df$tweet_analysis <- gsub("[[:punct:]]", "", df$tweet_analysis)
df$tweet_analysis <- strsplit(df$tweet_analysis, "\\s+")
df$tweet_analysis <- lapply(df$tweet_analysis, function(x) x[!(x %in% stop_words$word)])
#tidytext stopwords were used instead of a custom list
df <- df %>% unnest(tweet_analysis)
df <- tibble(df, text = tweet_analysis) %>% unnest_tokens(tweet_analysis, text)
df <- df %>% filter(username != tweet_analysis | name != tweet_analysis)
df <- df %>% inner_join(nrc, by = c("tweet_analysis" = "word")) 

#database
setwd("C:/DIRECTORY/")
db <- dbConnect(SQLite(), "twitter_data.sqlite")
dbWriteTable(db, "tweets", df, append = TRUE) #write df to table
dbDisconnect(db)#Disconnect from DB
