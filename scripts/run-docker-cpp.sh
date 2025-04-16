#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 运行C++版CBC求解器的Docker容器 ===${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到Docker。请安装Docker后再试。${NC}"
    exit 1
fi

# 检查镜像是否存在
if ! docker images | grep -q "cbc-solver"; then
    echo -e "${RED}错误: 未找到cbc-solver镜像。请先运行build-docker-cpp.sh构建镜像。${NC}"
    exit 1
fi

# 运行Docker容器
echo -e "${YELLOW}启动容器...${NC}"
docker run --rm cbc-solver

# 检查运行结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== 容器运行成功! ===${NC}"
else
    echo -e "${RED}=== 容器运行失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
