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

initShards()
{

echo "All shards initializing..."

echo "try shard1..."

docker compose exec -T shard1_node1 mongosh --port 27018 --quiet << EOF
  rs.initiate({_id: "shard1_node1", members:
    [
      {_id: 0, host: "shard1_node1:27018"},
      {_id: 1, host: "shard1_node2:27019"},
      {_id: 2, host: "shard1_node3:27020"}
    ]
  });
  exit();
EOF

echo "shard1 is initialized...."

echo "try shard2..."

docker compose exec -T shard2_node1 mongosh --port 27021 --quiet << EOF
  rs.initiate({_id: "shard2_node1", members:
    [
      {_id: 0, host: "shard2_node1:27021"},
      {_id: 1, host: "shard2_node2:27022"},
      {_id: 2, host: "shard2_node3:27023"}
    ]
  });
  exit();
EOF
echo "shard2 is initialized..."
}

waitingForRouter()
{
  local host="mongos_router"
  local port="27024"
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
    echo "try $attempt/$max_attempts..."
  done

  echo "mongos_router is started now..."
}

initRouter()
{

waitingForRouter

echo "Turn on mongos_router..."
docker compose exec -T mongos_router mongosh --port 27024 --quiet << EOF
  sh.addShard( "shard1_node1/shard1_node1:27018");
  sh.addShard( "shard2_node1/shard2_node1:27021");
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
  docker compose exec -T "$shard_name" mongosh --port "$shard_port" --quiet <<EOF
    use somedb;
    db.helloDoc.countDocuments();
EOF
    echo "counting is completed..."
}