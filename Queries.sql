CREATE TABLE IF NOT EXISTS tweets 
(id NUMERIC, conversation_id NUMERIC, created_at NUMERIC, date TIMESTAMP, 
timezone VARCHAR, place VARCHAR, tweet VARCHAR, language VARCHAR, hashtags VARCHAR, 
cashtags VARCHAR, user_id NUMERIC, user_id_str VARCHAR, username VARCHAR, name VARCHAR,
day TINYINT, hour TINYINT, link VARCHAR, urls VARCHAR, photos VARCHAR, video TINYINT,
thumbnail VARCHAR, retweet BOOLEAN, nlikes NUMERIC, nreplies NUMERIC, nretweets NUMERIC,
quote_url VARCHAR, search VARCHAR, near VARCHAR, geo VARCHAR, source VARCHAR, user_rt_id VARCHAR,
user_rt VARCHAR, retweet_id NUMERIC, reply_to VARCHAR, retweet_date TIMESTAMP, translate VARCHAR,
trans_src VARCHAR, trans_dest VARCHAR, tweet_analysis VARCHAR, sentiment VARCHAR);

CREATE VIEW IF NOT EXISTS all_tweets AS
SELECT DISTINCT id, conversation_id, created_at, date, timezone, place, tweet, language, hashtags,
				cashtags, user_id, user_id_str, username, name, day, hour, link, urls, photos,
				video, thumbnail, retweet, nlikes, nreplies, nretweets, quote_url, search, near,
				geo, source, user_rt_id, user_rt, retweet_id, reply_to, retweet_date, translate,
				trans_src, trans_dest, tweet_analysis, sentiment 
FROM tweets
ORDER BY date;

CREATE VIEW IF NOT EXISTS active_threats1 AS
SELECT id, date, username, count(sentiment) AS 'negativity_factor', tweet, nlikes, nreplies, nretweets --lists user, ID, total negative sentiment, and tweet info such as retweets and likes
FROM (SELECT DISTINCT id, date, username, tweet, nlikes, nreplies, nretweets, tweet_analysis, sentiment FROM tweets) --checks that duplicates are not counted
WHERE (sentiment = 'anger' OR sentiment = 'disgust' OR sentiment = 'fear')  --only the most severe negative sentiments selected
GROUP BY id
ORDER BY count(sentiment) DESC;

CREATE VIEW IF NOT EXISTS active_threats2 AS
SELECT id, date, username, count(sentiment) AS 'negativity_factor', tweet, nlikes, nreplies, nretweets --lists user, ID, total negative sentiment, and tweet info such as retweets and likes
FROM (SELECT DISTINCT id, date, username, tweet, nlikes, nreplies, nretweets, tweet_analysis, sentiment FROM tweets) --checks that duplicates are not counted
WHERE (sentiment = 'anger' OR sentiment = 'disgust' OR sentiment = 'fear')  --only the most severe negative sentiments selected
AND (SELECT count(sentiment) FROM tweets WHERE sentiment = 'positive' GROUP BY id) < 1 --optional condition that results must contain no positive sentiment whatsoever, might limit too much
GROUP BY id
ORDER BY count(sentiment) DESC;

CREATE VIEW IF NOT EXISTS dupe_checker AS SELECT COUNT(*), COUNT(DISTINCT (id || tweet_analysis || sentiment)) FROM tweets;
--checks for duplicate entries

DELETE FROM tweets --deletes duplicates 
WHERE rowid NOT IN (SELECT MIN(rowid) FROM tweets GROUP BY id, tweet_analysis, sentiment);

SELECT * FROM tweets;
SELECT * FROM all_tweets;
SELECT * FROM active_threats1;
SELECT * FROM active_threats2;
SELECT * FROM dupe_checker;