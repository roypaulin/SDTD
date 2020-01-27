package SDTD

import org.apache.kafka.clients.consumer.ConsumerRecord
import org.apache.kafka.common.serialization.StringDeserializer
import org.apache.spark.streaming.kafka010._
import org.apache.spark.streaming.kafka010.LocationStrategies.PreferConsistent
import org.apache.spark.streaming.kafka010.ConsumerStrategies.Subscribe
import org.apache.spark.SparkConf
import org.apache.spark.streaming._
import com.datastax.spark.connector._
import com.datastax.oss.driver.api.core.CqlSession
import com.datastax.oss.driver.api.core.cql._

object TwitterStream {
	def main(args: Array[String]) {
		val kafkaParams = Map[String, Object](
			// Need to change dynamically this variable
		  "bootstrap.servers" -> "3.16.10.104:9092,3.134.104.119:9092,18.188.138.46:9092",
		  "key.deserializer" -> classOf[StringDeserializer],
		  "value.deserializer" -> classOf[StringDeserializer],
		  "group.id" -> "use_a_separate_group_id_for_each_stream",
		  "auto.offset.reset" -> "latest",
		  "enable.auto.commit" -> (false: java.lang.Boolean)
		)

		val session = CqlSession.builder().build()
		try{
			session.execute("CREATE KEYSPACE IF NOT EXISTS test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1}")
		    session.execute("USE test")
		    session.execute("CREATE TABLE IF NOT EXISTS tablewc (word text PRIMARY KEY, wcount int)")
			val sparkConf = new SparkConf().setAppName("twitter")
			val streamingContext = new StreamingContext(sparkConf, Seconds(2))

			val topics = Array("twitter")
			val stream = KafkaUtils.createDirectStream[String, String](
				streamingContext,
				PreferConsistent,
				Subscribe[String, String](topics, kafkaParams)
			)
			
			stream.foreachRDD(rdd =>
				rdd.flatMap(x => scala.util.parsing.json.JSON.parseFull(x.value()).get.asInstanceOf[Map[String, Any]].get("text"))//.get.asInstanceOf[String].split("\\s+"))
				 .flatMap(x => x.asInstanceOf[String].split("\\s+"))
				 .filter(word => word.startsWith("#"))
                 .map(word => (word, 1))
                 .reduceByKey(_ + _).saveToCassandra("test", "tablewc", SomeColumns("word", "wcount"))
     //             rdd.foreach { record =>
					// val value = record.value()
					// val tweet = scala.util.parsing.json.JSON.parseFull(value)
					// val map:Map[String,Any] = tweet.get.asInstanceOf[Map[String, Any]]
					// println("TEXT: " + map.get("text"))
				//}
			)
			streamingContext.start()
			streamingContext.awaitTermination()
		} finally{
			session.close()
		}
		// stream.map(record => (record.key, record.value))
	}
}