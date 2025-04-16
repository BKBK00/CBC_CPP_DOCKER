#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 构建Go版CBC求解器的Docker镜像 ===${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到Docker。请安装Docker后再试。${NC}"
    exit 1
fi

# 构建Docker镜像
docker build -t cbc-go-solver -f docker/Dockerfile.go .

# 检查构建结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== Docker镜像构建成功! ===${NC}"
    echo -e "${GREEN}镜像名称: cbc-go-solver${NC}"
    echo -e "${YELLOW}运行容器: ./scripts/run-docker-go.sh${NC}"
else
    echo -e "${RED}=== Docker镜像构建失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
