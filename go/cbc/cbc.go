package cbc

/*
#cgo CFLAGS: -I${SRCDIR}/../bridge -I/usr/local/include/coin-or
#cgo LDFLAGS: -L${SRCDIR}/../bridge -L/usr/local/lib -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils -lstdc++

#include "cbc_bridge.h"
*/
import "C"
import (
    "errors"
    "unsafe"
)

// 求解器状态常量
const (
    StatusOptimal     = 0
    StatusInfeasible  = 1
    StatusOther       = 2
)

// Solver 封装CBC求解器
type Solver struct {
    handle unsafe.Pointer
}

// NewSolver 创建新的求解器实例
func NewSolver() (*Solver, error) {
    handle := C.CBC_CreateSolver()
    if handle == nil {
        return nil, errors.New("failed to create CBC solver")
    }
    return &Solver{handle: handle}, nil
}

// SetObjective 设置目标函数
func (s *Solver) SetObjective(coefficients []float64) error {
    if len(coefficients) == 0 {
        return errors.New("empty coefficients")
    }
    
    status := C.CBC_SetObjective(
        s.handle,
        C.int(len(coefficients)),
        (*C.double)(&coefficients[0]),
    )
    
    if status != 0 {
        return errors.New("failed to set objective")
    }
    return nil
}

// AddConstraint 添加约束条件
func (s *Solver) AddConstraint(indices []int, values []float64, lb, ub float64) error {
    if len(indices) == 0 || len(values) == 0 || len(indices) != len(values) {
        return errors.New("invalid constraint data")
    }
    
    // 转换indices为C数组
    cIndices := make([]C.int, len(indices))
    for i, idx := range indices {
        cIndices[i] = C.int(idx)
    }
    
    status := C.CBC_AddConstraint(
        s.handle,
        C.int(len(indices)),
        &cIndices[0],
        (*C.double)(&values[0]),
        C.double(lb),
        C.double(ub),
    )
    
    if status != 0 {
        return errors.New("failed to add constraint")
    }
    return nil
}

// SetVariableBounds 设置变量的上下界
func (s *Solver) SetVariableBounds(index int, lb, ub float64) error {
    status := C.CBC_SetVariableBounds(
        s.handle,
        C.int(index),
        C.double(lb),
        C.double(ub),
    )
    
    if status != 0 {
        return errors.New("failed to set variable bounds")
    }
    return nil
}

// SetVariableInteger 设置变量为整数变量
func (s *Solver) SetVariableInteger(index int) error {
    status := C.CBC_SetVariableInteger(
        s.handle,
        C.int(index),
    )
    
    if status != 0 {
        return errors.New("failed to set variable as integer")
    }
    return nil
}

// Solve 求解问题
func (s *Solver) Solve() error {
    status := C.CBC_Solve(s.handle)
    
    if status != 0 {
        return errors.New("failed to solve problem")
    }
    return nil
}

// GetStatus 获取求解状态
func (s *Solver) GetStatus() int {
    return int(C.CBC_GetSolutionStatus(s.handle))
}

// GetObjectiveValue 获取目标函数值
func (s *Solver) GetObjectiveValue() float64 {
    return float64(C.CBC_GetObjectiveValue(s.handle))
}

// GetSolution 获取解向量
func (s *Solver) GetSolution() []float64 {
    // 假设我们知道解的大小（这里使用3，实际应用中可能需要动态确定）
    size := 3
    solution := make([]float64, size)
    
    C.CBC_GetSolution(
        s.handle,
        (*C.double)(&solution[0]),
        C.int(size),
    )
    
    return solution
}

// Free 释放求解器资源
func (s *Solver) Free() {
    if s.handle != nil {
        C.CBC_FreeSolver(s.handle)
        s.handle = nil
    }
}
