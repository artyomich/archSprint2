#!/bin/bash

initConfigSrv()
{
echo "configSrv..."

docker compose exec -T configSrv mongosh --port 27017 --quiet << EOF
  rs.initiate(
    {
      _id : "config_server",
        configsvr: true,
      members: [
        { _id : 0, host : "configSrv:27017" }
      ]
    }
  );
  exit();
EOF

echo "configSrv initialized..."
}

initShards() {
  echo "Инициализация shard1..."
  docker compose exec -T shard1 mongosh --port 27018 --quiet << EOF
    rs.initiate({
      _id: "shard1",
      members: [{ _id: 0, host: "shard1:27018" }]
    });
    exit();
EOF
  echo "shard1 is initialized...."

  echo "try shard2..."

  docker compose exec -T shard2 mongosh --port 27019 --quiet << EOF
    rs.initiate(
        {
          _id : "shard2",
          members: [{ _id : 1, host : "shard2:27019" }]
        }
    );
    exit();
EOF
  echo "shard2 is initialized..."
}

waitingForRouter()
{
  local host="mongos_router"
  local port="27020"
  local maxAttempts=20
  local attempt=0

  echo "try mongos_router on $port..."

  while ! docker compose exec -T "$host" mongosh --port "$port" --eval "db.runCommand({ping:1})" --quiet >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$maxAttempts" ]; then
      echo "Error: mongos_router failed after $maxAttempts attempt(s)"
      exit 1
    fi
    sleep 1
    echo "try $attempt/$maxAttempts..."
  done

  echo "mongos_router is started now..."
}

initRouter()
{

waitingForRouter

echo "Turn on mongos_router..."
docker compose exec -T mongos_router mongosh --port 27020 --quiet << EOF
  sh.addShard( "shard1/shard1:27018");
  sh.addShard( "shard2/shard2:27019");
  sh.enableSharding("somedb");
  sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
  use somedb
  for(var i = 0; i < 1050; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
  db.helloDoc.countDocuments()
  exit();
EOF
echo "Seeding complete! mongos_router is ready!"
}

getDocsCount() {
  local shardName="$1"
  local shardPort="$2"
  echo "try shard "$shardName":"$shardPort"..."
  docker compose exec -T "$shardName" mongosh --port "$shardPort" --quiet <<EOF
    use somedb;
    db.helloDoc.countDocuments();
EOF
    echo "counting is completed..."
}