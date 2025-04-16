#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 构建C++版CBC求解器的Docker镜像 ===${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到Docker。请安装Docker后再试。${NC}"
    exit 1
fi

# 检查当前架构
CURRENT_ARCH=$(uname -m)
echo -e "${YELLOW}当前架构: $CURRENT_ARCH${NC}"

# 如果是ARM架构，使用--platform指定目标架构
if [ "$CURRENT_ARCH" = "arm64" ] || [ "$CURRENT_ARCH" = "aarch64" ]; then
    echo -e "${YELLOW}检测到ARM架构，将使用--platform=linux/amd64指定目标架构${NC}"
    PLATFORM_FLAG="--platform=linux/amd64"
else
    PLATFORM_FLAG=""
fi

# 构建Docker镜像
docker build $PLATFORM_FLAG -t cbc-solver -f docker/Dockerfile .

# 检查构建结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== Docker镜像构建成功! ===${NC}"
    echo -e "${GREEN}镜像名称: cbc-solver${NC}"
    echo -e "${YELLOW}运行容器: ./run-docker-cpp.sh${NC}"
else
    echo -e "${RED}=== Docker镜像构建失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
