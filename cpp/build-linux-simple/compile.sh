#!/bin/bash
set -e

# 编译程序，使用静态链接
# 首先检查zlib的静态库是否存在
if [ ! -f "/usr/lib/x86_64-linux-gnu/libz.a" ]; then
    echo "静态zlib库不存在，尝试使用动态链接"
    g++ -std=c++17 -o CBC main.cpp \
        -I/usr/local/include/coin-or \
        -L/usr/local/lib \
        -Wl,-Bstatic \
        -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils \
        -llapack -lopenblas \
        -Wl,-Bdynamic \
        -lpthread -lm -lz -ldl
else
    echo "使用完全静态链接"
    g++ -std=c++17 -o CBC main.cpp \
        -I/usr/local/include/coin-or \
        -L/usr/local/lib \
        -static \
        -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils \
        -llapack -lopenblas -lpthread -lm -lz -ldl
fi

# 检查是否成功编译
if [ -f "CBC" ]; then
    echo "编译成功！"
    # 检查是否为静态链接
    ldd CBC || echo "这是一个静态链接的可执行文件"
else
    echo "编译失败！"
    exit 1
fi
