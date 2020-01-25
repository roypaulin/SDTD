#!/usr/bin/python3

import tweepy
from tweepy import OAuthHandler
from tweepy import Stream
from tweepy.streaming import StreamListener
import json
from dotenv import load_dotenv
import pykafka
import os

# Using variable environment to protect keys
load_dotenv()

access_token = os.getenv("ACCESS_TOKEN")
access_token_secret = os.getenv("ACCESS_TOKEN_SECRET")
consumer_key = os.getenv("CONSUMER_KEY")
consumer_secret = os.getenv("CONSUMER_SECRET")

auth = OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)

class TweetListener(StreamListener):
	def __init__(self):
		self.client = pykafka.KafkaClient("kafka-broker-01:9092")
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
        
key_words = ['the', 'i', 'to', 'a', 'and', 'is', 'in', 'it', 'you', 'of']
twitter_stream = Stream(auth, TweetListener())
twitter_stream.filter(languages=['en'], track=key_words)