#!/bin/bash

# 服务器配置
SERVER_HOST="43.139.225.193"
SERVER_PORT="22"
SERVER_USER="root"
SERVER_PATH="/root/CBC"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 镜像名称
IMAGE_NAME="cbc-solver"
TAR_FILE="${IMAGE_NAME}.tar"

# 初始化变量
BUILT_FOR_SERVER=false

# 检测本地架构
LOCAL_ARCH=$(uname -m)
if [ "$LOCAL_ARCH" = "arm64" ] || [ "$LOCAL_ARCH" = "aarch64" ]; then
    LOCAL_ARCH="arm64"
    echo -e "${YELLOW}检测到本地是ARM架构 (M1/M2 Mac)${NC}"
    echo -e "${YELLOW}服务器可能是x86_64架构，可能需要多架构构建${NC}"

    echo -e "${YELLOW}选择一个选项:${NC}"
    echo -e "1) 为服务器架构(x86_64)构建镜像"
    echo -e "2) 使用本地架构(ARM)构建镜像"
    read -p "请选择 [1/2]: " -n 1 -r
    echo

    if [[ $REPLY =~ ^[1]$ ]]; then
        echo -e "${BLUE}=== 为x86_64架构构建镜像 ===${NC}"
        # 检查是否安装了buildx
        if ! docker buildx version > /dev/null 2>&1; then
            echo -e "${RED}需要Docker buildx支持跨架构构建${NC}"
            echo -e "${YELLOW}请参考: https://docs.docker.com/buildx/working-with-buildx/${NC}"
            exit 1
        fi

        # 创建并使用新的builder实例
        docker buildx create --name mybuilder --use || true
        docker buildx build --platform linux/amd64 -t $IMAGE_NAME -f Dockerfile . --load

        if [ $? -ne 0 ]; then
            echo -e "${RED}为x86_64架构构建失败${NC}"
            exit 1
        fi

        # 记录我们选择了服务器架构
        BUILT_FOR_SERVER=true
    else
        echo -e "${BLUE}=== 在本地构建Docker镜像（仅$LOCAL_ARCH架构） ===${NC}"
        echo -e "${YELLOW}警告: 如果服务器是x86_64架构，这个镜像可能无法运行${NC}"
        ./build-docker.sh

        if [ $? -ne 0 ]; then
            echo -e "${RED}构建Docker镜像失败，请检查错误信息${NC}"
            exit 1
        fi
    fi
else
    echo -e "${BLUE}=== 在本地构建Docker镜像 (x86_64架构) ===${NC}"
    ./build-docker.sh

    if [ $? -ne 0 ]; then
        echo -e "${RED}构建Docker镜像失败，请检查错误信息${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}=== 将镜像保存为tar文件 ===${NC}"
docker save -o $TAR_FILE $IMAGE_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}保存镜像失败，请确保镜像名称正确${NC}"
    exit 1
fi

echo -e "${GREEN}镜像已保存为 $TAR_FILE${NC}"
echo -e "${YELLOW}文件大小: $(du -h $TAR_FILE | cut -f1)${NC}"

echo -e "${BLUE}=== 上传镜像到服务器 ===${NC}"
echo -e "${YELLOW}上传可能需要一些时间，取决于文件大小和网络速度...${NC}"

# 确保服务器上的目标目录存在
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "mkdir -p $SERVER_PATH"

# 上传tar文件
scp -P $SERVER_PORT $TAR_FILE $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

if [ $? -ne 0 ]; then
    echo -e "${RED}上传镜像失败${NC}"
    exit 1
fi

echo -e "${GREEN}镜像已上传到服务器${NC}"

echo -e "${BLUE}=== 在服务器上加载镜像 ===${NC}"

# 检查服务器架构
SERVER_ARCH=$(ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "uname -m")
echo -e "${YELLOW}服务器架构: $SERVER_ARCH${NC}"

# 如果本地是ARM架构但服务器是x86_64，且我们没有为服务器架构构建，显示警告
if [ "$LOCAL_ARCH" = "arm64" ] && [ "$SERVER_ARCH" = "x86_64" ] && [ "$BUILT_FOR_SERVER" != "true" ]; then
    echo -e "${RED}警告: 本地是ARM架构，但服务器是x86_64架构${NC}"
    echo -e "${RED}镜像可能无法在服务器上运行${NC}"
    read -p "是否仍然继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}操作已取消${NC}"
        exit 0
    fi
fi

ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && docker load -i $TAR_FILE"

if [ $? -ne 0 ]; then
    echo -e "${RED}在服务器上加载镜像失败${NC}"
    exit 1
fi

echo -e "${GREEN}镜像已在服务器上加载成功${NC}"

# 询问是否要运行容器
read -p "是否要在服务器上运行容器? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}=== 在服务器上运行容器 ===${NC}"
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && ./run-docker.sh"
fi

echo -e "${GREEN}完成!${NC}"

# 询问是否要删除本地tar文件
read -p "是否要删除本地tar文件? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm $TAR_FILE
    echo -e "${GREEN}本地tar文件已删除${NC}"
fi
