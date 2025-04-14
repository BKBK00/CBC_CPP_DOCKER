#!/bin/bash

# 服务器信息
SERVER_HOST="43.139.225.193"
SERVER_PORT="22"
SERVER_USER="root"
SERVER_PATH="/root/CBC"

echo "===== 上传README.md到服务器 ====="

# 上传README.md文件
scp -P $SERVER_PORT README.md $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

echo "===== 上传完成 ====="
