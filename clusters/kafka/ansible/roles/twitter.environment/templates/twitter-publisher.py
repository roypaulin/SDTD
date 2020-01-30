#!/usr/bin/python3
from dotenv import load_dotenv

import os
import pykafka
import tweepy
import json

from tweepy import OAuthHandler
from tweepy import Stream
from tweepy.streaming import StreamListener

# Using variable environment to protect keys
load_dotenv()

consumer_key = os.getenv("CONSUMER_KEY")
consumer_secret = os.getenv("CONSUMER_SECRET")
access_token = os.getenv("ACCESS_TOKEN")
access_token_secret = os.getenv("ACCESS_TOKEN_SECRET")

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)

#auth = tweepy.AppAuthHandler(consumer_key, consumer_secret)

#CHECK: https://bhaskarvk.github.io/2015/01/how-to-use-twitters-search-rest-api-most-effectively./

class TweetListener(StreamListener):
	def __init__(self):
		self.client = pykafka.KafkaClient("kafka-broker-01:9092,kafka-broker-02:9092,kafka-broker-03:9092")
		self.producer = self.client.topics[bytes('twitter','utf-8')].get_producer()

	def on_data(self, data):
		try:
			self.producer.produce(bytes(data,'utf-8'))
			# Only for debugging
			# json_data = json.loads(data)
			# print(json_data)
			return True
		except KeyError:
			return True

	def on_error(self, status):
		print(status)
		return True
        
key_words = ['#']
twitter_stream = Stream(auth=auth, listener=TweetListener(), wait_on_rate_limit=True, wait_on_rate_limit_notify=True)
twitter_stream.filter(track=key_words)