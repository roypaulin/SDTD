# Kafka Commands

On any zookeeper instance : 
  
  create topic : 
  kafka-topics --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic twitter

  list topics :
  kafka-topics --list --zookeeper localhost:2181


On any kafka broker instance : 

  consumer console (to see output) : 
  kafka-console-consumer --bootstrap-server localhost:9092 --topic twitter --from-beginning

  producer console (write input) : 
  kafka-console-producer --broker-list localhost:9092 --topic twitter

Check confluent status:
  systemctl status confluent*

Concluent-kafka commads:
  sudo systemctl stop confluent-kafka 
  sudo systemctl start confluent-kafka


############ Prepare one kafka broker instance to run twitter.py ##############


sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
exec "$SHELL"

pyenv install 3.7.4
pyenv global 3.7.4
pip install ipython kafka-python python-twitter tweepy

# create file twitter.py
