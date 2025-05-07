#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CURRENT_DIR}/mongo-functions.sh"

initConfigSrv  # Инициализация configSrv
initShards     # Инициализация шарды
initRouter     # Инициализация mongo роутера + сидирование

getDocsCount shard1 27018  # Записи в shard1
getDocsCount shard2 27019  # Записи в shard2