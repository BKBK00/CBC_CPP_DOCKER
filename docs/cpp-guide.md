# C++版CBC求解器使用指南

本文档介绍如何使用C++版本的CBC求解器来解决混合整数规划(MIP)问题。

## 环境要求

- C++编译器(支持C++17)
- CMake 3.10或更高版本
- CBC库及其依赖(CoinUtils, Osi, Clp, Cgl)

## 安装依赖

### macOS

```bash
brew install cbc
```

### Ubuntu/Debian

```bash
sudo apt-get install coinor-libcbc-dev coinor-libclp-dev coinor-libcoinutils-dev
```

## 构建方法

### 使用Docker(推荐)

1. 构建Docker镜像:
   ```bash
   ./scripts/build-docker-cpp.sh
   ```

2. 运行Docker容器:
   ```bash
   ./scripts/run-docker-cpp.sh
   ```

### 本地编译

```bash
./cpp/build-native-simple.sh
```

### 交叉编译(为Linux)

```bash
./cpp/build-for-linux-simple.sh
```

## 代码示例

```cpp
#include <iostream>
#include <coin/CbcModel.hpp>
#include <coin/OsiClpSolverInterface.hpp>
#include <coin/CoinPackedMatrix.hpp>
#include <coin/CoinPackedVector.hpp>

int main() {
    // 创建求解器
    OsiClpSolverInterface solver;
    
    // 设置为最大化问题
    solver.setObjSense(-1.0);
    
    // 定义变量和约束
    int numVars = 3;
    int numConstraints = 3;
    
    // 设置目标函数: 10x + 6y + 4z
    double objective[3] = {10.0, 6.0, 4.0};
    
    // 设置变量边界: 0 <= x,y,z < ∞
    double* colLb = new double[numVars];
    double* colUb = new double[numVars];
    for (int i = 0; i < numVars; i++) {
        colLb[i] = 0.0;
        colUb[i] = COIN_DBL_MAX;
    }
    
    // 创建约束矩阵
    CoinPackedMatrix matrix;
    
    // 添加约束: x + y + z <= 100
    CoinPackedVector row1;
    row1.insert(0, 1.0);
    row1.insert(1, 1.0);
    row1.insert(2, 1.0);
    matrix.appendRow(row1);
    
    // 添加约束: 10x + 4y + 5z <= 600
    CoinPackedVector row2;
    row2.insert(0, 10.0);
    row2.insert(1, 4.0);
    row2.insert(2, 5.0);
    matrix.appendRow(row2);
    
    // 添加约束: 2x + 2y + 6z <= 300
    CoinPackedVector row3;
    row3.insert(0, 2.0);
    row3.insert(1, 2.0);
    row3.insert(2, 6.0);
    matrix.appendRow(row3);
    
    // 设置约束边界
    double* rowLb = new double[numConstraints];
    double* rowUb = new double[numConstraints];
    for (int i = 0; i < numConstraints; i++) {
        rowLb[i] = -COIN_DBL_MAX;
    }
    rowUb[0] = 100.0;
    rowUb[1] = 600.0;
    rowUb[2] = 300.0;
    
    // 加载问题
    solver.loadProblem(matrix, colLb, colUb, objective, rowLb, rowUb);
    
    // 设置变量为整数
    for (int i = 0; i < numVars; i++) {
        solver.setInteger(i);
    }
    
    // 创建CBC模型并求解
    CbcModel model(solver);
    model.branchAndBound();
    
    // 输出结果
    if (model.isProvenOptimal()) {
        const double* solution = model.bestSolution();
        std::cout << "找到最优解!" << std::endl;
        std::cout << "目标函数值: " << -model.getObjValue() << std::endl;
        std::cout << "x = " << solution[0] << std::endl;
        std::cout << "y = " << solution[1] << std::endl;
        std::cout << "z = " << solution[2] << std::endl;
    } else {
        std::cout << "未找到最优解!" << std::endl;
    }
    
    // 释放内存
    delete[] colLb;
    delete[] colUb;
    delete[] rowLb;
    delete[] rowUb;
    
    return 0;
}
```

## 更多资源

- [CBC官方文档](https://github.com/coin-or/Cbc)
- [COIN-OR项目](https://www.coin-or.org/)
- [CBC API参考](https://coin-or.github.io/Cbc/)
