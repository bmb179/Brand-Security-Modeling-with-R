import twint
import pandas

c = twint.Config()
c.Search = "Google"
c.Limit = 100
#c.Since
c.Utc = True
c.Full_text = True
c.Pandas = True
c.Language = "en"
c.Filter_retweets = True
c.Hide_output = False
twint.run.Search(c)
df = twint.storage.panda.Tweets_df
df
