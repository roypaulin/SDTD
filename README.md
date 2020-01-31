# SDTD

##Pre-Requirements:
 - Java 8
 - python v3.7 (with boto)
 - terraform v0.12.12
 - ansible v2.9.4
 - spark v2.4.4 (hadoop2.7)
 - sbt v1.3.7
 - aws v1
 - docker

## Environment
1) Set environment variables (Use the .examples as base)

    **(AWS Credentials)**

    ``$ cp env/aws.env.example env/aws.env (and edit the file)``

    **(API Twitter Credentails)**

    ``$ cp env/twitter.env.example env/twitter.env (and edit the file)``

    **(Dockerhub Credentials)**

    ``$ cp env/docker.env.example env/docker.env (and edit the file)``

2) Install python requirements on your environment

    ``$ pip install -r requirements.txt``


## Deploying
1) Deploy all clusters (This might take up to 30 minutes)

    ``$ deploy.sh all``

2) You can also deploy individual parts with:

    ``$ deploy.sh cassandra``

    ``$ deploy.sh kafka``
   
    ``$ deploy.sh kubernetes``

    ``$ deploy.sh spark`` (depends on kubernetes)

    **EXPERIMENTAL**: It's also possible to deploy the appliation running a docker image to avoid OS issues, but it's not yet fully tested and functionnal.

    ``$ docker build -t sdtd .``

    ``$ docker run --rm sdtd deploy.sh all``
## Testing
1) Read contents saved on Cassandra's cluster (frequency of #hashtags) 

    ``$ python clusters/cassandra/readDB.py`` 

    **NOTE**: This won't work if you're connected to Ensimag's network because of their firewall. Alternatinavelly you can do:
  
    ``$ ssh -f -F ssh_config cassandra-seed-01 'python3 -u readDB.py'`` 

## Destroying
1) To destroy instances afterwards, run: 
    
    ``$ destroy.sh all`` 

2) You can also deploy individual parts with:

    ``$ destroy.sh cassandra``
  
    ``$ destroy.sh kafka``
  
    ``$ destroy.sh kubernetes`` (destroy spark together)

    ``$ destroy.sh spark``

    ``$ destroy.sh utils`` (remove installed utils on folder 'utils/')

    **EXPERIMENTAL**: It's also possible to deploy the appliation running a docker image to avoid OS issues, but it's not yet fully tested and functionnal.

    ``$ docker build -t sdtd .``

    ``$ docker run --rm sdtd destroy.sh all``