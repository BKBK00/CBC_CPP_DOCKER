#!/bin/bash

# 服务器信息
SERVER_HOST="43.139.225.193"
SERVER_PORT="22"
SERVER_USER="root"
SERVER_PASSWORD="lyy@100126"  # 注意：在脚本中包含密码不是安全的做法，仅用于演示
SERVER_PATH="/root/CBC"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 上传Linux可执行文件到服务器 ===${NC}"

# 确保目标目录存在
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "mkdir -p $SERVER_PATH"

# 上传可执行文件
echo -e "${YELLOW}上传文件: ../cpp/build-linux-simple/CBC${NC}"
scp -P $SERVER_PORT "../cpp/build-linux-simple/CBC" $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 文件上传成功${NC}"

    # 设置执行权限并运行
    echo -e "${BLUE}=== 在服务器上运行可执行文件 ===${NC}"
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && chmod +x CBC && ./CBC"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 程序在服务器上成功运行${NC}"
    else
        echo -e "${RED}✗ 程序在服务器上运行失败${NC}"
    fi
else
    echo -e "${RED}✗ 文件上传失败${NC}"
fi
