# CBC求解器MIP问题示例

这个项目展示了如何使用C++版本的CBC（COIN-OR Branch and Cut）求解器来求解混合整数规划（MIP）问题。项目使用Docker容器化，可以在任何支持Docker的环境中运行，无需担心依赖问题。

## 项目结构

- `main.cpp` - 主程序源代码，包含CBC求解器的使用示例
- `CMakeLists.txt` - CMake构建配置文件
- `Dockerfile` - Docker镜像构建配置
- `build-docker.sh` - 构建Docker镜像的脚本
- `run-docker.sh` - 运行Docker容器的脚本
- `.dockerignore` - Docker构建时忽略的文件
- `deploy.sh` - 多功能部署脚本，用于将文件上传到服务器

## 问题描述

示例程序解决了以下混合整数规划问题：

**目标函数（最大化）**：
```
10x + 6y + 4z
```

**约束条件**：
```
x + y + z <= 100
10x + 4y + 5z <= 600
2x + 2y + 6z <= 300
x, y, z >= 0 且为整数
```

## 使用方法

### 前提条件

- 安装Docker（[Docker安装指南](https://docs.docker.com/get-docker/)）

### 本地运行

1. 克隆或下载本项目
2. 在项目目录中打开终端
3. 构建Docker镜像：
   ```bash
   ./build-docker.sh
   ```
4. 运行Docker容器：
   ```bash
   ./run-docker.sh
   ```

### 在服务器上部署

使用项目自带的部署脚本：

1. **上传所有文件并运行**：
   ```bash
   ./deploy.sh --all --run
   ```

2. **只上传代码文件**：
   ```bash
   ./deploy.sh --code
   ```

3. **上传特定文件**：
   ```bash
   ./deploy.sh --file main.cpp
   ```

4. **查看部署脚本的帮助信息**：
   ```bash
   ./deploy.sh --help
   ```

手动部署方式：

1. 将项目文件复制到服务器：
   ```bash
   scp -r ./* user@your-server:/path/to/destination/
   ```
2. 连接到服务器并运行：
   ```bash
   ssh user@your-server
   cd /path/to/destination/
   ./build-docker.sh
   ./run-docker.sh
   ```

## 代码说明

`main.cpp`文件实现了一个使用CBC求解器解决MIP问题的示例。主要步骤包括：

1. 创建求解器接口（OsiClpSolverInterface）
2. 设置问题为最大化问题
3. 定义变量和约束
4. 设置目标函数系数
5. 添加约束条件
6. 设置变量为整数变量
7. 创建CBC模型并求解
8. 输出最优解

## Docker镜像说明

Docker镜像基于Ubuntu 22.04，并从源代码编译安装了以下组件：

1. CoinUtils - 基础工具库
2. Osi - 开放求解器接口
3. Clp - 线性规划求解器
4. Cgl - 割平面生成库
5. CBC - 分支切割求解器

这确保了CBC求解器在容器中正确运行，无需担心依赖问题。

## 运行结果

成功运行后，程序将输出MIP问题的最优解：

```
找到最优解!
目标函数值: 732
x = 33
y = 67
z = 0
```

这表示最优解是x=33, y=67, z=0，此时目标函数值为10×33 + 6×67 + 4×0 = 732。

## 扩展和修改

如果您想修改问题或扩展功能，可以编辑`main.cpp`文件，然后重新构建Docker镜像。例如，您可以：

- 修改目标函数系数
- 添加或修改约束条件
- 增加变量数量
- 尝试不同类型的约束（等式、大于等于）

## 故障排除

如果遇到问题，请检查：

1. Docker是否正确安装并运行
2. 构建脚本是否有执行权限（`chmod +x build-docker.sh run-docker.sh`）
3. 网络连接是否正常（构建过程需要下载源代码）

## 参考资料

- [COIN-OR CBC官方文档](https://github.com/coin-or/Cbc)
- [混合整数规划介绍](https://en.wikipedia.org/wiki/Integer_programming)
- [Docker文档](https://docs.docker.com/)
