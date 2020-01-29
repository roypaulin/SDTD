lazy val root = (project in file(".")).
  settings(
    name := "SDTD",
    version := "1.0",
    scalaVersion := "2.11.9",
    mainClass in Compile := Some("SDTD.TwitterStream")        
  )

resolvers += Resolver.sbtPluginRepo("releases")

libraryDependencies ++= {
  val sparkVer = "2.4.4"
  Seq(
    "org.apache.spark" %% "spark-sql" % sparkVer % "provided",
    "org.apache.spark" %% "spark-core" % sparkVer % "provided",
    "org.apache.spark" % "spark-streaming_2.11" % sparkVer % "provided",
    "org.apache.spark" % "spark-streaming-kafka-0-10_2.11" % sparkVer,
    "com.datastax.spark" %% "spark-cassandra-connector" % "2.4.2",
  )
}

assemblyMergeStrategy in assembly ~= (old =>{
    case m if m.toLowerCase.endsWith("manifest.mf") => MergeStrategy.discard
    case m if m.toLowerCase.matches("meta-inf.*\\.sf$") => MergeStrategy.discard
    case "log4j.properties" => MergeStrategy.discard
    case m if m.toLowerCase.startsWith("meta-inf/services/") => MergeStrategy.filterDistinctLines
    case "reference.conf" => MergeStrategy.concat
    case _  => MergeStrategy.first
  }
)