package SDTD

import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD
import com.datastax.spark.connector._
import com.datastax.oss.driver.api.core.CqlSession
import com.datastax.oss.driver.api.core.cql._
import java.net.InetSocketAddress

object WordCount {

  def main(args:Array[String]):Unit = {
    val session = CqlSession.builder().addContactPoint(new InetSocketAddress("172.31.1.225", 9042)).withLocalDatacenter("DC1").build()
    session.execute("CREATE KEYSPACE IF NOT EXISTS test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1}")
    session.execute("USE test")
    session.execute("CREATE TABLE IF NOT EXISTS tablewc (word text PRIMARY KEY, wcount int)")
    val conf = new SparkConf().setAppName("SDTD").set("spark.cassandra.connection.host", "172.31.1.225")
    val sc = new SparkContext(conf)
    sc.setLogLevel("ERROR")
    val textFile = sc.textFile(args(0))
    val counts = textFile.flatMap(line => line.split(" "))
                 .map(word => (word, 1))
                 .reduceByKey(_ + _)
    counts.saveToCassandra("test", "tablewc", SomeColumns("word", "wcount"))
    session.close()
  }
}
