lazy val root = (project in file(".")).
  settings(
    name := "SDTD",
    version := "1.0",
    scalaVersion := "2.11.9",
    mainClass in Compile := Some("SDTD.WordCount")        
  )

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-sql" % "2.4.4" % "provided",
  "com.datastax.spark" %% "spark-cassandra-connector" % "2.4.2",
  "com.datastax.oss" % "java-driver-core" % "4.4.0",
  "com.datastax.oss" % "java-driver-query-builder" % "4.4.0",
  "com.datastax.oss" % "java-driver-mapper-runtime" % "4.4.0"
)

mergeStrategy in assembly ~= (old =>{
    case PathList("META-INF", xs @ _*) => MergeStrategy.discard
    case x => MergeStrategy.first
  }
)
// name := "SDTD"
// version := "1.0"
// scalaVersion := "2.11.8"
// libraryDependencies += "org.apache.spark" %% "spark-sql" % "2.4.4"
// libraryDependencies += "com.datastax.oss" % "java-driver-core" % "4.4.0"
// libraryDependencies += "com.datastax.oss" % "java-driver-query-builder" % "4.4.0"
// libraryDependencies += "com.datastax.oss" % "java-driver-mapper-runtime" % "4.4.0"

