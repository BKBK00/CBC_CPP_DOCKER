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
