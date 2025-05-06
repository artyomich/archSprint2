#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CURRENT_DIR}/mongo-functions.sh"

initConfigSrv  # Инициализация configSrv
initShards     # Инициализация шарды
initRouter     # Инициализация mongo роутера + сидирование