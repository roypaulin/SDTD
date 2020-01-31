#!/usr/bin/python3
from cassandra.cluster import Cluster

cluster = Cluster(['{% if 'cassandra_seed' in groups -%}{% for host in groups['cassandra_seed'] %}{% if loop.index > 1%}','{% endif %}{{ hostvars[host].public_ip }}{% endfor %}{% if 'cassandra_node' in groups -%}{% for host in groups['cassandra_node'] %}','{{ hostvars[host].public_ip }}{% endfor %}{% endif %}{% endif %}'])
session = cluster.connect()

session.execute("CREATE KEYSPACE IF NOT EXISTS sdtd WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 2}")

session.execute('USE sdtd')
session.execute('CREATE TABLE IF NOT EXISTS tablewc (word text PRIMARY KEY, wcount list<int>)')