#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CURRENT_DIR}/mongo-functions.sh"

initConfigSrv  # Инициализация configSrv
initShards     # Инициализация шарды
initRouter     # Инициализация mongo роутера + сидирование

getDocsCount shard1_node1 27018  # Записи в shard1 node1
getDocsCount shard1_node2 27019  # Записи в shard1 node2
getDocsCount shard1_node3 27020  # Записи в shard1 node3
getDocsCount shard2_node1 27021  # Записи в shard2 node1
getDocsCount shard2_node2 27022  # Записи в shard2 node2
getDocsCount shard2_node3 27023  # Записи в shard2 node3