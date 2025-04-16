#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 为Linux交叉编译Go版CBC求解器 ===${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到Docker。此方法需要Docker来创建交叉编译环境。${NC}"
    exit 1
fi

# 创建临时目录
TEMP_DIR="build-linux"
mkdir -p "$TEMP_DIR"

# 复制必要的文件到临时目录
cp -r ../go "$TEMP_DIR/"
cp -r ../examples/go "$TEMP_DIR/"

# 创建Dockerfile
cat > "$TEMP_DIR/Dockerfile" << 'EOF'
FROM golang:1.17

# 安装必要的工具和依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    wget \
    unzip \
    libopenblas-dev \
    liblapack-dev \
    git \
    autoconf \
    automake \
    libtool \
    zlib1g-dev

# 下载并编译CoinUtils
WORKDIR /tmp
RUN wget https://github.com/coin-or/CoinUtils/archive/releases/2.11.9.tar.gz && \
    tar xzf 2.11.9.tar.gz && \
    cd CoinUtils-releases-2.11.9 && \
    ./configure --prefix=/usr/local --enable-static --disable-shared && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf CoinUtils-releases-2.11.9 2.11.9.tar.gz

# 下载并编译Osi
RUN wget https://github.com/coin-or/Osi/archive/releases/0.108.8.tar.gz && \
    tar xzf 0.108.8.tar.gz && \
    cd Osi-releases-0.108.8 && \
    ./configure --prefix=/usr/local --enable-static --disable-shared && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Osi-releases-0.108.8 0.108.8.tar.gz

# 下载并编译Clp
RUN wget https://github.com/coin-or/Clp/archive/releases/1.17.8.tar.gz && \
    tar xzf 1.17.8.tar.gz && \
    cd Clp-releases-1.17.8 && \
    ./configure --prefix=/usr/local --enable-static --disable-shared && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Clp-releases-1.17.8 1.17.8.tar.gz

# 下载并编译Cgl
RUN wget https://github.com/coin-or/Cgl/archive/releases/0.60.7.tar.gz && \
    tar xzf 0.60.7.tar.gz && \
    cd Cgl-releases-0.60.7 && \
    ./configure --prefix=/usr/local --enable-static --disable-shared && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Cgl-releases-0.60.7 0.60.7.tar.gz

# 下载并编译CBC
RUN wget https://github.com/coin-or/Cbc/archive/releases/2.10.8.tar.gz && \
    tar xzf 2.10.8.tar.gz && \
    cd Cbc-releases-2.10.8 && \
    ./configure --prefix=/usr/local --enable-static --disable-shared && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Cbc-releases-2.10.8 2.10.8.tar.gz

# 更新动态链接器运行时绑定
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf && \
    ldconfig

# 工作目录
WORKDIR /app
EOF

# 创建编译脚本
cat > "$TEMP_DIR/compile.sh" << 'EOF'
#!/bin/bash
set -e

# 编译C++桥接层
cd /app/go/bridge
g++ -c -fPIC cbc_bridge.cpp -o cbc_bridge.o -I/usr/local/include/coin-or
g++ -shared -o libcbc_bridge.so cbc_bridge.o -L/usr/local/lib -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils

# 编译Go程序
cd /app/go
export CGO_ENABLED=1
export CGO_LDFLAGS="-L/app/go/bridge -lcbc_bridge -L/usr/local/lib -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lstdc++"
export CGO_CFLAGS="-I/app/go/bridge -I/usr/local/include/coin-or"
export GOOS=linux
export GOARCH=amd64

# 编译示例程序
cd /app/go
go build -o cbc_go_linux ../go/simple_mip.go

# 检查是否成功编译
if [ -f "cbc_go_linux" ]; then
    echo "编译成功！"
    # 尝试静态链接
    echo "尝试创建静态链接版本..."
    export CGO_LDFLAGS="-L/app/go/bridge -lcbc_bridge -L/usr/local/lib -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lstdc++ -static"
    go build -o cbc_go_linux_static -ldflags "-linkmode external -extldflags -static" ../go/simple_mip.go
    if [ -f "cbc_go_linux_static" ]; then
        echo "静态链接版本创建成功！"
    else
        echo "静态链接版本创建失败，将使用动态链接版本。"
    fi
else
    echo "编译失败！"
    exit 1
fi
EOF

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
echo -e "${BLUE}=== 构建Docker镜像 ===${NC}"
docker build $PLATFORM_FLAG -t cbc-go-linux-builder "$TEMP_DIR"

# 编译程序
echo -e "${BLUE}=== 在Docker容器中编译程序 ===${NC}"
docker run --rm -v "$(pwd)/$TEMP_DIR:/app" cbc-go-linux-builder bash -c "chmod +x /app/compile.sh && /app/compile.sh"

# 检查编译结果
if [ -f "$TEMP_DIR/go/cbc_go_linux" ]; then
    echo -e "${GREEN}=== 编译成功! ===${NC}"
    echo -e "${GREEN}Linux可执行文件位于: $(pwd)/$TEMP_DIR/go/cbc_go_linux${NC}"
    
    # 检查是否有静态链接版本
    if [ -f "$TEMP_DIR/go/cbc_go_linux_static" ]; then
        echo -e "${GREEN}Linux静态链接可执行文件位于: $(pwd)/$TEMP_DIR/go/cbc_go_linux_static${NC}"
        echo -e "${YELLOW}您可以将此文件复制到任何Linux x86_64系统上运行，无需安装额外依赖${NC}"
    else
        echo -e "${YELLOW}注意: 只生成了动态链接版本，运行时需要安装CBC库${NC}"
    fi
else
    echo -e "${RED}=== 编译失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
