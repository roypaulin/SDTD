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
import java.net.InetSocketAddress

object TwitterStream {
	def main(args: Array[String]) {
		val kafkaParams = Map[String, Object](
			// Need to change dynamically this variable
		  "bootstrap.servers" -> "3.12.120.95:9092,3.17.74.99:9092,18.191.98.25:9092",
		  "key.deserializer" -> classOf[StringDeserializer],
		  "value.deserializer" -> classOf[StringDeserializer],
		  "group.id" -> "use_a_separate_group_id_for_each_stream",
		  "auto.offset.reset" -> "latest",
		  "enable.auto.commit" -> (false: java.lang.Boolean)
		)

		 val session = CqlSession.builder().addContactPoint(new InetSocketAddress("172.31.1.225", 9042)).withLocalDatacenter("datacenterSDTD").build()
		try{
			session.execute("CREATE KEYSPACE IF NOT EXISTS test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1}")
		    session.execute("USE test")
		    session.execute("CREATE TABLE IF NOT EXISTS tablewc (word text PRIMARY KEY, wcount list<int>)")
			val sparkConf = new SparkConf().setAppName("twitter").set("spark.cassandra.connection.host", "172.31.1.225")
			val streamingContext = new StreamingContext(sparkConf, Seconds(2))

			val topics = Array("twitter")
			val stream = KafkaUtils.createDirectStream[String, String](
				streamingContext,
				PreferConsistent,
				Subscribe[String, String](topics, kafkaParams)
			)
			stream.foreachRDD(rdd => {
				rdd.flatMap(x => scala.util.parsing.json.JSON.parseFull(x.value()).get.asInstanceOf[Map[String, Any]].get("text"))//.get.asInstanceOf[String].split("\\s+"))
				 .flatMap(x => x.asInstanceOf[String].split("\\s+"))
				 .filter(word => word.startsWith("#"))
                 .map(word => (word, 1))
                 .reduceByKey(_ + _).map(a=>(a._1, Vector(a._2))).saveToCassandra("test", "tablewc", SomeColumns("word", "wcount" add))
				}
			)
			streamingContext.start()
			streamingContext.awaitTerminationOrTimeout(20000)
		} finally{
			session.close()
		}
		// stream.map(record => (record.key, record.value))
	}
}