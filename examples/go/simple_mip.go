package main

import (
    "fmt"
    "log"
    
    "../../go/cbc"
)

func main() {
    // 创建求解器
    solver, err := cbc.NewSolver()
    if err != nil {
        log.Fatalf("Failed to create solver: %v", err)
    }
    defer solver.Free()
    
    // 设置目标函数: 10x + 6y + 4z
    err = solver.SetObjective([]float64{10.0, 6.0, 4.0})
    if err != nil {
        log.Fatalf("Failed to set objective: %v", err)
    }
    
    // 设置变量的上下界
    for i := 0; i < 3; i++ {
        err = solver.SetVariableBounds(i, 0.0, 1e30) // 0 <= x,y,z < ∞
        if err != nil {
            log.Fatalf("Failed to set variable bounds: %v", err)
        }
    }
    
    // 添加约束条件: x + y + z <= 100
    err = solver.AddConstraint(
        []int{0, 1, 2},
        []float64{1.0, 1.0, 1.0},
        -1e30, 100.0,
    )
    if err != nil {
        log.Fatalf("Failed to add constraint: %v", err)
    }
    
    // 添加约束条件: 10x + 4y + 5z <= 600
    err = solver.AddConstraint(
        []int{0, 1, 2},
        []float64{10.0, 4.0, 5.0},
        -1e30, 600.0,
    )
    if err != nil {
        log.Fatalf("Failed to add constraint: %v", err)
    }
    
    // 添加约束条件: 2x + 2y + 6z <= 300
    err = solver.AddConstraint(
        []int{0, 1, 2},
        []float64{2.0, 2.0, 6.0},
        -1e30, 300.0,
    )
    if err != nil {
        log.Fatalf("Failed to add constraint: %v", err)
    }
    
    // 设置变量为整数
    for i := 0; i < 3; i++ {
        err = solver.SetVariableInteger(i)
        if err != nil {
            log.Fatalf("Failed to set variable as integer: %v", err)
        }
    }
    
    // 求解问题
    err = solver.Solve()
    if err != nil {
        log.Fatalf("Failed to solve: %v", err)
    }
    
    // 获取结果
    status := solver.GetStatus()
    if status == cbc.StatusOptimal {
        objValue := solver.GetObjectiveValue()
        solution := solver.GetSolution()
        
        fmt.Println("找到最优解!")
        fmt.Printf("目标函数值: %f\n", objValue)
        fmt.Printf("x = %f\n", solution[0])
        fmt.Printf("y = %f\n", solution[1])
        fmt.Printf("z = %f\n", solution[2])
    } else {
        fmt.Println("未找到最优解!")
    }
}
