# CBC求解器MIP问题示例

这个项目展示了如何使用C++版本的CBC（COIN-OR Branch and Cut）求解器来求解混合整数规划（MIP）问题。项目完全使用Docker容器化，无论是本地运行还是部署到服务器，都可以在任何支持Docker的环境中运行，无需担心依赖问题。

## 项目结构

### 核心文件
- `main.cpp` - 主程序源代码，包含CBC求解器的使用示例
- `CMakeLists.txt` - CMake构建配置文件

### Docker相关文件
- `Dockerfile` - Docker镜像构建配置
- `build-docker.sh` - 构建Docker镜像的脚本
- `run-docker.sh` - 运行Docker容器的脚本
- `.dockerignore` - Docker构建时忽略的文件

### 本地编译脚本
- `build-native-simple.sh` - 在本地环境直接编译CBC程序的脚本

### 交叉编译脚本
- `build-for-linux-simple.sh` - 在macOS上编译可在Linux上运行的静态链接可执行文件

### 部署脚本
- `deploy.sh` - 文件上传部署脚本，用于将文件上传到服务器
- `save-and-upload-image.sh` - 镜像打包上传脚本，用于在本地构建镜像并上传到服务器
- `upload-linux-executable.sh` - 上传Linux可执行文件到服务器并运行的脚本

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

项目提供了四种部署方式，可根据不同需求选择：

#### 方式一：使用Docker容器（源代码上传）

这种方式将源代码和配置文件上传到服务器，然后在服务器上构建镜像。

```bash
./deploy.sh --all --run
```

**优点：**
- 简单直接，只需一个命令
- 服务器上的代码始终与本地保持同步

**缺点：**
- 需要在服务器上进行编译，可能耗时较长
- 需要服务器有足够的资源

#### 方式二：使用Docker容器（镜像上传）

这种方式在本地构建镜像，然后将镜像上传到服务器。

```bash
./save-and-upload-image.sh
```

**优点：**
- 避免在服务器上进行耗时的编译
- 确保本地和服务器使用完全相同的镜像

**缺点：**
- 镜像文件可能较大，上传时间较长
- 需要处理架构差异（如ARM Mac与x86_64服务器）

#### 方式三：使用静态链接的可执行文件

这种方式在本地编译出一个静态链接的Linux可执行文件，然后将其上传到服务器。

```bash
# 编译Linux可执行文件
./build-for-linux-simple.sh

# 上传并运行
./upload-linux-executable.sh
```

**优点：**
- 不需要在服务器上安装Docker
- 不需要在服务器上安装任何依赖
- 可执行文件体积小，上传快速

**缺点：**
- 编译过程复杂，需要交叉编译环境
- 只能在相同架构的Linux系统上运行

#### 方式四：本地编译运行

如果您只需要在本地运行，可以直接编译和运行：

```bash
./build-native-simple.sh
```

**优点：**
- 最简单直接的方式
- 不需要Docker
- 编译和运行速度快

**缺点：**
- 需要在本地安装CBC及其依赖
- 只能在本地运行，不能直接在其他环境运行

#### 手动部署方式

如果需要手动部署，可以使用以下命令：

```bash
# 将文件复制到服务器
scp -r ./* user@your-server:/path/to/destination/

# 连接到服务器并运行
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

## 部署脚本说明

项目提供了四个部署脚本，对应四种不同的部署方式：

### 1. `deploy.sh` - 文件上传部署脚本

这个脚本将源代码和配置文件上传到服务器，然后在服务器上构建和运行Docker容器。

#### 可用选项

- `-a, --all`：上传所有核心项目文件
- `-c, --code`：只上传代码文件 (main.cpp 和 CMakeLists.txt)
- `-d, --docker`：只上传Docker相关文件
- `-b, --build`：上传后在服务器上构建Docker镜像
- `-r, --run`：上传后在服务器上构建并运行Docker容器
- `-f, --file <文件>`：上传指定文件
- `-h, --help`：显示帮助信息

### 2. `save-and-upload-image.sh` - 镜像打包上传脚本

这个脚本在本地构建Docker镜像，然后将镜像保存为tar文件并上传到服务器。这种方法避免了在服务器上进行耗时的编译过程。

#### 主要功能

- 自动检测本地和服务器架构
- 支持为服务器架构(x86_64)构建镜像，即使本地是ARM架构(M1/M2 Mac)
- 自动处理架构不匹配的情况

### 3. `build-for-linux-simple.sh` - Linux可执行文件编译脚本

这个脚本在macOS上使用Docker创建交叉编译环境，编译出一个可以在Linux上直接运行的静态链接可执行文件。

#### 主要功能

- 使用Docker创建交叉编译环境
- 从源代码编译CBC及其依赖库
- 生成静态链接的可执行文件，不依赖于外部库
- 支持从 ARM Mac 编译 x86_64 Linux 可执行文件

### 4. `upload-linux-executable.sh` - Linux可执行文件上传脚本

这个脚本将编译好的Linux可执行文件上传到服务器，并在服务器上运行。

#### 主要功能

- 上传静态链接的可执行文件到服务器
- 自动设置执行权限并运行
- 显示运行结果

### 5. `build-native-simple.sh` - 本地编译脚本

这个脚本在本地环境中直接编译CBC程序，不使用Docker。

#### 主要功能

- 检测必要的依赖（CMake、C++编译器、CBC库）
- 自动处理包含路径问题
- 直接编译并运行程序

如果需要修改服务器信息，请编辑脚本开头的配置部分：

```bash
# 服务器配置
SERVER_HOST="43.139.225.193"
SERVER_PORT="22"
SERVER_USER="root"
SERVER_PATH="/root/CBC"
```

## Shell脚本常用操作指南

本项目中的Shell脚本使用了多种常用操作和技巧，下面是对这些操作的简要说明：

### 1. 文件上传与下载

```bash
# 使用scp上传文件到服务器
scp -P $SERVER_PORT "$file" $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

# 使用scp下载服务器文件
scp -P $SERVER_PORT $SERVER_USER@$SERVER_HOST:$SERVER_PATH/file.txt .
```

### 2. 远程命令执行

```bash
# 在服务器上执行命令
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && ./build-docker.sh"

# 检查服务器架构
SERVER_ARCH=$(ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "uname -m")
```

### 3. Docker镜像操作

```bash
# 构建Docker镜像
docker build -t $IMAGE_NAME .

# 保存镜像为tar文件
docker save -o $TAR_FILE $IMAGE_NAME

# 加载镜像
docker load -i $TAR_FILE

# 跨架构构建
docker buildx build --platform linux/amd64 -t $IMAGE_NAME .
```

### 4. 条件判断与循环

```bash
# if条件判断
if [ "$LOCAL_ARCH" = "arm64" ]; then
    echo "ARM架构"
else
    echo "x86_64架构"
fi

# 循环遍历数组
FILES=("main.cpp" "CMakeLists.txt" "Dockerfile")
for file in "${FILES[@]}"; do
    echo "Processing $file"
done
```

### 5. 用户交互

```bash
# 读取用户输入
read -p "是否继续? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "继续执行"
fi

# 彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
echo -e "${GREEN}成功!${NC}"
```

### 6. 错误处理

```bash
# 检查命令执行状态
command
if [ $? -ne 0 ]; then
    echo "命令执行失败"
    exit 1
fi

# 使用try-catch风格的错误处理
{
    command1
    command2
} || {
    echo "错误处理"
    exit 1
}
```

这些操作在项目的`deploy.sh`和`save-and-upload-image.sh`脚本中广泛使用，您可以通过查看这些脚本来了解它们的实际应用。

## 参考资料

- [COIN-OR CBC官方文档](https://github.com/coin-or/Cbc)
- [混合整数规划介绍](https://en.wikipedia.org/wiki/Integer_programming)
- [Docker文档](https://docs.docker.com/)
- [Bash脚本指南](https://www.gnu.org/software/bash/manual/bash.html)
- [SCP命令参考](https://linux.die.net/man/1/scp)
- [Docker Buildx指南](https://docs.docker.com/buildx/working-with-buildx/)
