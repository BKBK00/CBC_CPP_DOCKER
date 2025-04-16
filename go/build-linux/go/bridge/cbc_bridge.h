#ifndef CBC_BRIDGE_H
#define CBC_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

// 创建求解器实例
void* CBC_CreateSolver();

// 设置问题参数
int CBC_SetObjective(void* solver, int numVars, const double* coefficients);
int CBC_AddConstraint(void* solver, int numVars, const int* indices, const double* values, double lb, double ub);
int CBC_SetVariableBounds(void* solver, int index, double lb, double ub);
int CBC_SetVariableInteger(void* solver, int index);

// 求解问题
int CBC_Solve(void* solver);

// 获取结果
int CBC_GetSolutionStatus(void* solver);
double CBC_GetObjectiveValue(void* solver);
int CBC_GetSolution(void* solver, double* solution, int size);

// 释放资源
void CBC_FreeSolver(void* solver);

#ifdef __cplusplus
}
#endif

#endif // CBC_BRIDGE_H
