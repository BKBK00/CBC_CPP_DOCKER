#include "cbc_bridge.h"
#include <coin/CbcModel.hpp>
#include <coin/OsiClpSolverInterface.hpp>
#include <coin/CoinPackedMatrix.hpp>
#include <coin/CoinPackedVector.hpp>
#include <vector>
#include <stdexcept>

struct CBCSolver {
    OsiClpSolverInterface* osiSolver;
    CbcModel* model;
    std::vector<double> solution;
    
    CBCSolver() : osiSolver(nullptr), model(nullptr) {}
    ~CBCSolver() {
        delete model;
        delete osiSolver;
    }
};

void* CBC_CreateSolver() {
    try {
        CBCSolver* solver = new CBCSolver();
        solver->osiSolver = new OsiClpSolverInterface();
        solver->osiSolver->setObjSense(-1.0); // 最大化
        return solver;
    } catch (...) {
        return nullptr;
    }
}

int CBC_SetObjective(void* solver, int numVars, const double* coefficients) {
    if (!solver || numVars <= 0 || !coefficients) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        
        // 设置目标函数系数
        for (int i = 0; i < numVars; i++) {
            cbcSolver->osiSolver->setObjCoeff(i, coefficients[i]);
        }
        
        return 0;
    } catch (...) {
        return -1;
    }
}

int CBC_AddConstraint(void* solver, int numVars, const int* indices, const double* values, double lb, double ub) {
    if (!solver || numVars <= 0 || !indices || !values) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        
        // 创建约束
        CoinPackedVector row;
        for (int i = 0; i < numVars; i++) {
            row.insert(indices[i], values[i]);
        }
        
        // 添加约束
        cbcSolver->osiSolver->addRow(row, lb, ub);
        
        return 0;
    } catch (...) {
        return -1;
    }
}

int CBC_SetVariableBounds(void* solver, int index, double lb, double ub) {
    if (!solver || index < 0) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        cbcSolver->osiSolver->setColBounds(index, lb, ub);
        return 0;
    } catch (...) {
        return -1;
    }
}

int CBC_SetVariableInteger(void* solver, int index) {
    if (!solver || index < 0) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        cbcSolver->osiSolver->setInteger(index);
        return 0;
    } catch (...) {
        return -1;
    }
}

int CBC_Solve(void* solver) {
    if (!solver) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        
        // 创建CBC模型
        delete cbcSolver->model; // 删除旧模型（如果有）
        cbcSolver->model = new CbcModel(*cbcSolver->osiSolver);
        
        // 设置求解参数
        cbcSolver->model->setLogLevel(1);
        
        // 求解问题
        cbcSolver->model->branchAndBound();
        
        // 保存解
        if (cbcSolver->model->isProvenOptimal()) {
            const double* sol = cbcSolver->model->bestSolution();
            int numCols = cbcSolver->osiSolver->getNumCols();
            cbcSolver->solution.resize(numCols);
            for (int i = 0; i < numCols; i++) {
                cbcSolver->solution[i] = sol[i];
            }
        }
        
        return 0;
    } catch (...) {
        return -1;
    }
}

int CBC_GetSolutionStatus(void* solver) {
    if (!solver) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        if (!cbcSolver->model) return -1;
        
        if (cbcSolver->model->isProvenOptimal()) {
            return 0; // 最优解
        } else if (cbcSolver->model->isProvenInfeasible()) {
            return 1; // 不可行
        } else {
            return 2; // 其他状态
        }
    } catch (...) {
        return -1;
    }
}

double CBC_GetObjectiveValue(void* solver) {
    if (!solver) return 0.0;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        if (!cbcSolver->model || !cbcSolver->model->isProvenOptimal()) {
            return 0.0;
        }
        
        // 注意：由于我们设置为最大化，所以需要取负
        return -cbcSolver->model->getObjValue();
    } catch (...) {
        return 0.0;
    }
}

int CBC_GetSolution(void* solver, double* solution, int size) {
    if (!solver || !solution || size <= 0) return -1;
    
    try {
        CBCSolver* cbcSolver = static_cast<CBCSolver*>(solver);
        if (!cbcSolver->model || !cbcSolver->model->isProvenOptimal()) {
            return -1;
        }
        
        int numCols = cbcSolver->osiSolver->getNumCols();
        int copySize = (size < numCols) ? size : numCols;
        
        for (int i = 0; i < copySize; i++) {
            solution[i] = cbcSolver->solution[i];
        }
        
        return copySize;
    } catch (...) {
        return -1;
    }
}

void CBC_FreeSolver(void* solver) {
    if (solver) {
        delete static_cast<CBCSolver*>(solver);
    }
}
