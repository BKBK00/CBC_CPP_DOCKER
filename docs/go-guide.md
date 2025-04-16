# Go版CBC求解器使用指南

本文档介绍如何使用Go语言通过CGO调用CBC求解器来解决混合整数规划(MIP)问题。

## 环境要求

- Go 1.16或更高版本
- GCC或Clang编译器
- CBC库及其依赖(CoinUtils, Osi, Clp, Cgl)

## 安装依赖

### macOS

```bash
brew install cbc go
```

### Ubuntu/Debian

```bash
sudo apt-get install coinor-libcbc-dev coinor-libclp-dev coinor-libcoinutils-dev golang-go
```

## 构建方法

### 使用Docker(推荐)

1. 构建Docker镜像:
   ```bash
   ./scripts/build-docker-go.sh
   ```

2. 运行Docker容器:
   ```bash
   ./scripts/run-docker-go.sh
   ```

### 本地编译

```bash
./go/build-go-native.sh
```

### 交叉编译(为Linux)

```bash
./go/build-go-for-linux.sh
```

## 代码示例

```go
package main

import (
    "fmt"
    "log"
    
    "github.com/yourusername/cbc-go/cbc"
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
```

## API参考

### Solver

```go
// 创建新的求解器
func NewSolver() (*Solver, error)

// 设置目标函数
func (s *Solver) SetObjective(coefficients []float64) error

// 添加约束条件
func (s *Solver) AddConstraint(indices []int, values []float64, lb, ub float64) error

// 设置变量的上下界
func (s *Solver) SetVariableBounds(index int, lb, ub float64) error

// 设置变量为整数变量
func (s *Solver) SetVariableInteger(index int) error

// 求解问题
func (s *Solver) Solve() error

// 获取求解状态
func (s *Solver) GetStatus() int

// 获取目标函数值
func (s *Solver) GetObjectiveValue() float64

// 获取解向量
func (s *Solver) GetSolution() []float64

// 释放求解器资源
func (s *Solver) Free()
```

### 状态常量

```go
const (
    StatusOptimal     = 0
    StatusInfeasible  = 1
    StatusOther       = 2
)
```

## 更多资源

- [CBC官方文档](https://github.com/coin-or/Cbc)
- [Go语言CGO文档](https://golang.org/cmd/cgo/)
- [COIN-OR项目](https://www.coin-or.org/)
