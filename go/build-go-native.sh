#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 编译Go版CBC求解器 ===${NC}"

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    echo -e "${RED}错误: 未找到Go。请安装Go后再试。${NC}"
    exit 1
fi

# 检查CBC库是否安装
if ! pkg-config --exists cbc; then
    echo -e "${RED}错误: 未找到CBC库。请安装CBC库后再试。${NC}"
    echo -e "${YELLOW}可以使用以下命令安装CBC库:${NC}"
    echo -e "  - macOS: brew install cbc"
    echo -e "  - Ubuntu: sudo apt-get install coinor-libcbc-dev coinor-libclp-dev coinor-libcoinutils-dev"
    exit 1
fi

# 编译C++桥接层
echo -e "${BLUE}=== 编译C++桥接层 ===${NC}"
cd bridge
g++ -c -fPIC cbc_bridge.cpp -o cbc_bridge.o $(pkg-config --cflags cbc)
g++ -shared -o libcbc_bridge.so cbc_bridge.o $(pkg-config --libs cbc)
cd ..

# 设置环境变量
export CGO_ENABLED=1
export CGO_LDFLAGS="-L$(pwd)/bridge -lcbc_bridge"
export CGO_CFLAGS="-I$(pwd)/bridge"

# 编译Go示例程序
echo -e "${BLUE}=== 编译Go示例程序 ===${NC}"
cd ../examples/go
go build -o simple_mip simple_mip.go

# 检查编译结果
if [ -f "simple_mip" ]; then
    echo -e "${GREEN}=== 编译成功! ===${NC}"
    echo -e "${GREEN}可执行文件位于: $(pwd)/simple_mip${NC}"
    echo -e "${YELLOW}运行方式: ./simple_mip${NC}"
    
    # 询问是否运行程序
    read -p "是否立即运行程序? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}=== 运行程序 ===${NC}"
        LD_LIBRARY_PATH=$(pwd)/../../go/bridge ./simple_mip
    fi
else
    echo -e "${RED}=== 编译失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
