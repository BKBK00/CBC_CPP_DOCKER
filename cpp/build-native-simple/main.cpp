#include <iostream>
#include "/opt/homebrew/Cellar/cbc/2.10.12/include/cbc/coin/CbcModel.hpp"
#include "/opt/homebrew/Cellar/clp/1.17.10/include/clp/coin/OsiClpSolverInterface.hpp"
#include "/opt/homebrew/Cellar/coinutils/2.11.12/include/coinutils/coin/CoinPackedMatrix.hpp"
#include "/opt/homebrew/Cellar/coinutils/2.11.12/include/coinutils/coin/CoinPackedVector.hpp"

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
