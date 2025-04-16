#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 准备为Linux交叉编译CBC程序 ===${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: 未找到Docker。此方法需要Docker来创建交叉编译环境。${NC}"
    exit 1
fi

# 创建临时目录
TEMP_DIR="build-linux-simple"
mkdir -p "$TEMP_DIR"

# 创建C++源文件
echo -e "${BLUE}=== 创建C++源文件 ===${NC}"
cat > "$TEMP_DIR/main.cpp" << 'EOF'
#include <iostream>
#include <coin/CbcModel.hpp>
#include <coin/OsiClpSolverInterface.hpp>
#include <coin/CoinPackedMatrix.hpp>
#include <coin/CoinPackedVector.hpp>

/**
 * 使用CBC求解器解决一个简单的MIP问题示例
 *
 * 问题描述：
 * 最大化: 10x + 6y + 4z
 * 约束条件:
 *   x + y + z <= 100
 *   10x + 4y + 5z <= 600
 *   2x + 2y + 6z <= 300
 *   x, y, z >= 0 且为整数
 */
int main() {
    try {
        // 创建一个线性规划求解器接口
        OsiClpSolverInterface solver;

        // 设置问题为最大化
        solver.setObjSense(-1.0); // -1表示最大化，1表示最小化

        // 定义变量数量和约束数量
        int numVars = 3;
        int numConstraints = 3;

        // 创建矩阵，定义问题
        CoinPackedMatrix matrix(false, 0, 0); // 按行存储

        // 设置变量的上下界
        double* colLb = new double[numVars];
        double* colUb = new double[numVars];
        double* objective = new double[numVars];

        // 设置所有变量的下界为0，上界为无穷大
        for (int i = 0; i < numVars; i++) {
            colLb[i] = 0.0;
            colUb[i] = COIN_DBL_MAX;
        }

        // 设置目标函数系数: 10x + 6y + 4z
        objective[0] = 10.0; // x的系数
        objective[1] = 6.0;  // y的系数
        objective[2] = 4.0;  // z的系数

        // 设置约束的上下界
        double* rowLb = new double[numConstraints];
        double* rowUb = new double[numConstraints];

        // 设置所有约束为小于等于约束
        for (int i = 0; i < numConstraints; i++) {
            rowLb[i] = -COIN_DBL_MAX; // 下界为负无穷
            rowUb[i] = 0.0;           // 上界为0，表示小于等于约束
        }

        // 添加约束: x + y + z <= 100
        CoinPackedVector row1;
        row1.insert(0, 1.0); // x的系数
        row1.insert(1, 1.0); // y的系数
        row1.insert(2, 1.0); // z的系数
        matrix.appendRow(row1);
        rowUb[0] = 100.0; // 右侧常数

        // 添加约束: 10x + 4y + 5z <= 600
        CoinPackedVector row2;
        row2.insert(0, 10.0); // x的系数
        row2.insert(1, 4.0);  // y的系数
        row2.insert(2, 5.0);  // z的系数
        matrix.appendRow(row2);
        rowUb[1] = 600.0; // 右侧常数

        // 添加约束: 2x + 2y + 6z <= 300
        CoinPackedVector row3;
        row3.insert(0, 2.0); // x的系数
        row3.insert(1, 2.0); // y的系数
        row3.insert(2, 6.0); // z的系数
        matrix.appendRow(row3);
        rowUb[2] = 300.0; // 右侧常数

        // 加载问题到求解器
        solver.loadProblem(matrix, colLb, colUb, objective, rowLb, rowUb);

        // 设置所有变量为整数变量
        for (int i = 0; i < numVars; i++) {
            solver.setInteger(i);
        }

        // 创建CBC模型
        CbcModel model(solver);

        // 设置求解参数
        model.setLogLevel(1); // 设置日志级别

        // 求解问题
        model.branchAndBound();

        // 检查是否找到最优解
        if (model.isProvenOptimal()) {
            const double* solution = model.bestSolution();
            double objValue = model.getObjValue();

            std::cout << "找到最优解!" << std::endl;
            std::cout << "目标函数值: " << -objValue << std::endl; // 注意：由于我们设置为最大化，所以需要取负
            std::cout << "x = " << solution[0] << std::endl;
            std::cout << "y = " << solution[1] << std::endl;
            std::cout << "z = " << solution[2] << std::endl;
        } else {
            std::cout << "未找到最优解!" << std::endl;
        }

        // 释放内存
        delete[] colLb;
        delete[] colUb;
        delete[] objective;
        delete[] rowLb;
        delete[] rowUb;

    } catch (const std::exception& e) {
        std::cerr << "发生异常: " << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "发生未知异常" << std::endl;
        return 1;
    }

    return 0;
}
EOF

# 创建Dockerfile
echo -e "${BLUE}=== 创建Dockerfile ===${NC}"
cat > "$TEMP_DIR/Dockerfile" << 'EOF'
FROM ubuntu:20.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

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
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

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
docker build $PLATFORM_FLAG -t cbc-linux-builder "$TEMP_DIR"

# 编译程序
echo -e "${BLUE}=== 在Docker容器中编译程序 ===${NC}"
docker run --rm -v "$(pwd)/$TEMP_DIR:/app" cbc-linux-builder bash -c "chmod +x /app/compile.sh && /app/compile.sh"

# 检查编译结果
if [ -f "$TEMP_DIR/CBC" ]; then
    echo -e "${GREEN}=== 编译成功! ===${NC}"
    echo -e "${GREEN}Linux可执行文件位于: $(pwd)/$TEMP_DIR/CBC${NC}"
    echo -e "${YELLOW}您可以将此文件复制到任何Linux x86_64系统上运行，无需安装额外依赖${NC}"
else
    echo -e "${RED}=== 编译失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
