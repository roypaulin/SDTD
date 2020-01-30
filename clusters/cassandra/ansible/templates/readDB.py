#!/usr/bin/python3
from cassandra.cluster import Cluster

cluster = Cluster(['{% if 'cassandra_seed' in groups -%}{% for host in groups['cassandra_seed'] %}{% if loop.index > 1%}','{% endif %}{{ hostvars[host].public_ip }}{% endfor %}{% if 'cassandra_node' in groups -%}{% for host in groups['cassandra_node'] %}','{{ hostvars[host].public_ip }}{% endfor %}{% endif %}{% endif %}'])
session = cluster.connect()

session.execute('USE sdtd')

rows = session.execute('SELECT word, wcount FROM tablewc')
rows = [[row[0], sum(row[1])] for row in rows]
rows.sort(key= lambda x: x[1])
for row in rows:
    print(row[1], row[0])
