from cassandra.cluster import Cluster
from cassandra.policies import DCAwareRoundRobinPolicy
import uuid

cluster = Cluster(['{{ hostvars['cassandra-seed-01'].public_ip }}'])
session = cluster.connect()

session.execute("CREATE KEYSPACE IF NOT EXISTS test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1}")

session.execute('USE test')
session.execute('CREATE TABLE IF NOT EXISTS tablewc (word text PRIMARY KEY, wcount list<int>)')

rows = session.execute('SELECT word, wcount FROM tablewc')
rows = [[row[0], sum(row[1])] for row in rows]
rows.sort(key= lambda x: x[1])
for row in rows:
    print(row[1], row[0])
