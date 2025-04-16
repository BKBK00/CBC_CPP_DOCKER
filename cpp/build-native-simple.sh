#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 检查必要的依赖 ===${NC}"

# 检查编译器
if command -v g++ &> /dev/null; then
    COMPILER="g++"
elif command -v clang++ &> /dev/null; then
    COMPILER="clang++"
else
    echo -e "${RED}错误: 未找到C++编译器(g++或clang++)。请安装编译器后再试。${NC}"
    exit 1
fi

echo -e "${GREEN}使用编译器: $COMPILER${NC}"

# 检查pkg-config
if ! command -v pkg-config &> /dev/null; then
    echo -e "${RED}错误: 未找到pkg-config。请安装pkg-config后再试。${NC}"
    echo -e "${YELLOW}可以使用以下命令安装pkg-config:${NC}"
    echo -e "  - macOS: brew install pkg-config"
    echo -e "  - Ubuntu: sudo apt-get install pkg-config"
    exit 1
fi

# 检查CBC库
echo -e "${YELLOW}检查CBC库...${NC}"
if pkg-config --exists cbc; then
    echo -e "${GREEN}CBC库已安装${NC}"
    CBC_CFLAGS=$(pkg-config --cflags cbc)
    CBC_LIBS=$(pkg-config --libs cbc)
    echo -e "${YELLOW}CBC编译标志: $CBC_CFLAGS${NC}"
    echo -e "${YELLOW}CBC链接标志: $CBC_LIBS${NC}"
else
    echo -e "${RED}未找到CBC库${NC}"
    echo -e "${YELLOW}您需要安装CBC库及其依赖:${NC}"
    echo -e "  - macOS: brew install cbc"
    echo -e "  - Ubuntu: sudo apt-get install coinor-libcbc-dev coinor-libclp-dev coinor-libcoinutils-dev"
    exit 1
fi

# 创建临时目录
TEMP_DIR="build-native-simple"
mkdir -p "$TEMP_DIR"

# 分析CBC头文件路径
CBC_INCLUDE_DIRS=$(echo $CBC_CFLAGS | grep -o '\-I[^ ]*' | cut -c 3-)
echo -e "${GREEN}CBC头文件路径:${NC}"
for dir in $CBC_INCLUDE_DIRS; do
    echo -e "${GREEN}  $dir${NC}"
done

# 查找各个头文件的实际位置
CBC_MODEL_PATH=""
OSI_CLP_PATH=""
COIN_PACKED_MATRIX_PATH=""
COIN_PACKED_VECTOR_PATH=""

for dir in $CBC_INCLUDE_DIRS; do
    if [ -z "$CBC_MODEL_PATH" ] && [ -f "$dir/CbcModel.hpp" ]; then
        CBC_MODEL_PATH="$dir/CbcModel.hpp"
    fi
    if [ -z "$OSI_CLP_PATH" ] && [ -f "$dir/OsiClpSolverInterface.hpp" ]; then
        OSI_CLP_PATH="$dir/OsiClpSolverInterface.hpp"
    fi
    if [ -z "$COIN_PACKED_MATRIX_PATH" ] && [ -f "$dir/CoinPackedMatrix.hpp" ]; then
        COIN_PACKED_MATRIX_PATH="$dir/CoinPackedMatrix.hpp"
    fi
    if [ -z "$COIN_PACKED_VECTOR_PATH" ] && [ -f "$dir/CoinPackedVector.hpp" ]; then
        COIN_PACKED_VECTOR_PATH="$dir/CoinPackedVector.hpp"
    fi
done

echo -e "${GREEN}CbcModel.hpp: $CBC_MODEL_PATH${NC}"
echo -e "${GREEN}OsiClpSolverInterface.hpp: $OSI_CLP_PATH${NC}"
echo -e "${GREEN}CoinPackedMatrix.hpp: $COIN_PACKED_MATRIX_PATH${NC}"
echo -e "${GREEN}CoinPackedVector.hpp: $COIN_PACKED_VECTOR_PATH${NC}"

# 创建一个简单的C++程序
echo -e "${BLUE}=== 创建临时C++程序 ===${NC}"

cat > "$TEMP_DIR/main.cpp" << EOF
#include <iostream>
#include "$CBC_MODEL_PATH"
#include "$OSI_CLP_PATH"
#include "$COIN_PACKED_MATRIX_PATH"
#include "$COIN_PACKED_VECTOR_PATH"
EOF

# 添加代码主体
cat >> "$TEMP_DIR/main.cpp" << 'EOF'

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

# 编译程序
echo -e "${BLUE}=== 编译程序 ===${NC}"
$COMPILER -std=c++17 -o "$TEMP_DIR/CBC" "$TEMP_DIR/main.cpp" $CBC_CFLAGS $CBC_LIBS

# 检查编译结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== 编译成功! ===${NC}"
    echo -e "${GREEN}可执行文件位于: $(pwd)/$TEMP_DIR/CBC${NC}"
    echo -e "${YELLOW}运行方式: ./$TEMP_DIR/CBC${NC}"

    # 询问是否运行程序
    read -p "是否立即运行程序? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}=== 运行程序 ===${NC}"
        ./$TEMP_DIR/CBC
    fi
else
    echo -e "${RED}=== 编译失败 ===${NC}"
    echo -e "${RED}请检查上面的错误信息${NC}"
    exit 1
fi
