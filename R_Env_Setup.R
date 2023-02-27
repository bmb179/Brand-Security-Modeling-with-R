########Environment Setup########
#################################

###R Libraries###

library(tidyverse)#data cleaning and graphs

library(reticulate)#scraping Twitter via Python's twint library
#prerequisite: local Python >3.6 installation with twint and pandas installed
twint <- import("twint")
pandas <- import("pandas")

library(tidytext)#text mining
library(textdata)#using the nrc lexicon for sentiment analysis
nrc <- get_sentiments("nrc")
#https://www.tidytextmining.com/

library(RSQLite)#database interaction

library(taskscheduleR)#scheduling recurring tasks
#without the involvement of Windows administration tools

###DB Setup###

db <- dbConnect(SQLite(), "twitter_data.sqlite")

#creating primary table
dbExecute(db, "CREATE TABLE IF NOT EXISTS tweets 
(id NUMERIC, conversation_id NUMERIC, created_at NUMERIC, date TIMESTAMP, 
timezone VARCHAR, place VARCHAR, tweet VARCHAR, language VARCHAR, hashtags VARCHAR, 
cashtags VARCHAR, user_id NUMERIC, user_id_str VARCHAR, username VARCHAR, name VARCHAR,
day TINYINT, hour TINYINT, link VARCHAR, urls VARCHAR, photos VARCHAR, video TINYINT,
thumbnail VARCHAR, retweet BOOLEAN, nlikes NUMERIC, nreplies NUMERIC, nretweets NUMERIC,
quote_url VARCHAR, search VARCHAR, near VARCHAR, geo VARCHAR, source VARCHAR, user_rt_id VARCHAR,
user_rt VARCHAR, retweet_id NUMERIC, reply_to VARCHAR, retweet_date TIMESTAMP, translate VARCHAR,
trans_src VARCHAR, trans_dest VARCHAR, tweet_analysis VARCHAR, sentiment VARCHAR);")

#creating views for reporting use
dbExecute(db, "CREATE VIEW IF NOT EXISTS all_tweets AS
SELECT DISTINCT id, conversation_id, created_at, date, timezone, place, tweet, language, hashtags,
				cashtags, user_id, user_id_str, username, name, day, hour, link, urls, photos,
				video, thumbnail, retweet, nlikes, nreplies, nretweets, quote_url, search, near,
				geo, source, user_rt_id, user_rt, retweet_id, reply_to, retweet_date, translate,
				trans_src, trans_dest, tweet_analysis, sentiment 
FROM tweets
ORDER BY date;")

dbExecute(db, "CREATE VIEW IF NOT EXISTS active_threats1 AS
SELECT id, date, username, count(sentiment) AS 'negativity_factor', tweet, nlikes, nreplies, nretweets 
FROM (SELECT DISTINCT id, date, username, tweet, nlikes, nreplies, nretweets, tweet_analysis, sentiment FROM tweets)
WHERE (sentiment = 'anger' OR sentiment = 'disgust' OR sentiment = 'fear')
GROUP BY id
ORDER BY count(sentiment) DESC;")

dbExecute(db, "CREATE VIEW IF NOT EXISTS active_threats2 AS
SELECT id, date, username, count(sentiment) AS 'negativity_factor', tweet, nlikes, nreplies, nretweets
FROM (SELECT DISTINCT id, date, username, tweet, nlikes, nreplies, nretweets, tweet_analysis, sentiment FROM tweets)
WHERE (sentiment = 'anger' OR sentiment = 'disgust' OR sentiment = 'fear')
AND (SELECT count(sentiment) FROM tweets WHERE sentiment = 'positive' GROUP BY id) < 1
GROUP BY id
ORDER BY count(sentiment) DESC;")

dbExecute(db, "CREATE VIEW IF NOT EXISTS dupe_checker AS SELECT COUNT(*), COUNT(DISTINCT (id || tweet_analysis || sentiment)) FROM tweets;")

#script for removing duplicates
dbExecute(db,"DELETE FROM tweets WHERE rowid NOT IN (SELECT MIN(rowid) FROM tweets GROUP BY id, tweet_analysis, sentiment);")

dbDisconnect(db)

###Task Scheduling for Every 60 Seconds###

taskscheduler_create(taskname = "twitter_scrape_60seconds", 
                     rscript = "C:/DIRECTORY/Run_Twitter_Scrape.R",
                     schedule = "MINUTE",
                     starttime = format(Sys.time() + 62, "%H:%M"),
                     startdate = format(Sys.Date(), "%m/%d/%Y"))

###Misc###

view(taskscheduler_ls()) #view all tasks
taskscheduler_delete(taskname = "twitter_scrape_60seconds") #end recurring task

db <- dbConnect(SQLite(), "twitter_data.sqlite")#reopen the database to look at the table and views
view(dbReadTable(db, "tweets"))
view(dbReadTable(db, "all_tweets"))
view(dbReadTable(db, "active_threats1"))
view(dbReadTable(db, "active_threats2"))
view(dbReadTable(db, "dupe_checker"))

###Data Viz###

dbReadTable(db, "tweets") %>% count(tweet_analysis, sort = TRUE) %>% 
  filter(n >= 50) %>% mutate(tweet_analysis = reorder(tweet_analysis, n)) %>% 
  ggplot(aes(n, tweet_analysis, fill = tweet_analysis)) +
  geom_col(show.legend = FALSE) + labs(y = NULL)

dbReadTable(db, "tweets") %>% count(tweet_analysis, sentiment, sort = TRUE) %>%
  filter(n >= 25) %>% mutate(tweet_analysis = reorder(tweet_analysis, n)) %>%
  ggplot(aes(n, tweet_analysis, fill = sentiment)) +
  geom_col(show.legend = FALSE) + facet_wrap(~sentiment, scales = "free_y") +
  labs(x = "Contribution to Sentiment", y = NULL)

dbReadTable(db, "tweets") %>% group_by(sentiment) %>% count(sentiment, sort = TRUE) %>%
  ggplot(aes(n, sentiment, fill = sentiment)) + geom_col() +
  labs(x = "Contribution to Sentiment")

###Data Viz with my blog theme###

blog_theme <- theme(
  plot.background = element_rect(fill = "#14101b", color = "#14101b"),
  panel.background = element_rect(fill = "#14101b", color = "#14101b"),
  legend.background = element_rect(fill = "#14101b", color = "#14101b"),
  legend.title = element_text(family = "serif", color = "White", face = "bold"),
  legend.text = element_text(family = "serif", color = "White"),
  axis.title = element_text(family = "serif", color = "White", face = "bold"),
  axis.text = element_text(family = "serif", color = "White"),
  plot.title= element_text(family = "serif", color = "White", face = "bold"),
  plot.subtitle= element_text(family = "serif", color = "White")
)

dbReadTable(db, "tweets") %>% count(tweet_analysis, sort = TRUE) %>% 
  filter(n >= 50) %>% mutate(tweet_analysis = reorder(tweet_analysis, n)) %>% 
  ggplot(aes(n, tweet_analysis, fill = tweet_analysis)) +
  geom_col(show.legend = FALSE) + labs(y = NULL) + blog_theme

dbReadTable(db, "tweets") %>% count(tweet_analysis, sentiment, sort = TRUE) %>%
  filter(n >= 25) %>% mutate(tweet_analysis = reorder(tweet_analysis, n)) %>%
  ggplot(aes(n, tweet_analysis, fill = sentiment)) +
  geom_col(show.legend = FALSE) + facet_wrap(~sentiment, scales = "free_y") +
  labs(x = "Contribution to Sentiment", y = NULL) + blog_theme

dbReadTable(db, "tweets") %>% group_by(sentiment) %>% count(sentiment, sort = TRUE) %>%
  ggplot(aes(n, sentiment, fill = sentiment)) + geom_col() +
  labs(x = "Contribution to Sentiment") + blog_theme

###DB Disconnect###

dbDisconnect(db)

