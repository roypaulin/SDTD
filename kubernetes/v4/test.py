from cassandra.cluster import Cluster
import uuid

cluster = Cluster()
session = cluster.connect()

session.execute("CREATE KEYSPACE IF NOT EXISTS test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1}")

session.execute('USE test')

rows = session.execute('SELECT word, wcount FROM tablewc')
for row in rows:
    print(row[0], row[1])