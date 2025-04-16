# CBC求解器项目

这个项目展示了如何使用CBC（COIN-OR Branch and Cut）求解器来求解混合整数规划（MIP）问题。项目提供了C++和Go两种语言实现，并支持多种部署方案。

## 项目结构

```
CBC/
├── cpp/                      # C++版本目录
│   ├── main.cpp              # C++示例程序
│   ├── CMakeLists.txt        # C++构建配置
│   ├── build-native-simple.sh # 本地C++编译脚本
│   └── build-for-linux-simple.sh # Linux C++交叉编译脚本
│
├── go/                       # Go语言版本目录
│   ├── cbc/                  # Go CBC包
│   │   ├── cbc.go            # Go CBC接口
│   │   └── cbc_test.go       # 测试文件
│   ├── bridge/               # C++/C桥接层
│   │   ├── cbc_bridge.h      # C桥接头文件
│   │   └── cbc_bridge.cpp    # C桥接实现
│   ├── build-go-native.sh    # Go本地编译脚本
│   └── build-go-for-linux.sh # Go交叉编译脚本
│
├── docker/                   # Docker相关文件
│   ├── Dockerfile.cpp        # C++版本的Dockerfile
│   ├── Dockerfile.go         # Go版本的Dockerfile
│   └── .dockerignore         # Docker忽略文件
│
├── scripts/                  # 部署和运行脚本
│   ├── build-docker-cpp.sh   # 构建C++版Docker镜像
│   ├── build-docker-go.sh    # 构建Go版Docker镜像
│   ├── run-docker-cpp.sh     # 运行C++版Docker容器
│   ├── run-docker-go.sh      # 运行Go版Docker容器
│   ├── deploy-cpp.sh         # C++版部署脚本
│   ├── deploy-go.sh          # Go版部署脚本
│   ├── save-and-upload-image-cpp.sh # C++镜像上传脚本
│   ├── save-and-upload-image-go.sh  # Go镜像上传脚本
│   ├── upload-linux-executable-cpp.sh # C++可执行文件上传脚本
│   └── upload-linux-executable-go.sh  # Go可执行文件上传脚本
│
├── examples/                 # 示例程序
│   ├── cpp/                  # C++示例
│   │   └── simple_mip.cpp    # 简单MIP问题示例
│   └── go/                   # Go示例
│       └── simple_mip.go     # 相同问题的Go实现
│
├── docs/                     # 文档目录
│   ├── cpp-guide.md          # C++版本使用指南
│   ├── go-guide.md           # Go版本使用指南
│   └── deployment.md         # 部署指南
│
└── README.md                 # 项目主文档
```

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
- 或安装CBC库及其依赖（[CBC安装指南](https://github.com/coin-or/Cbc)）
- 对于Go版本，还需要安装Go（[Go安装指南](https://golang.org/doc/install)）

### C++版本

#### 使用Docker

```bash
# 构建Docker镜像
./scripts/build-docker-cpp.sh

# 运行Docker容器
./scripts/run-docker-cpp.sh
```

#### 本地编译

```bash
./cpp/build-native-simple.sh
```

### Go版本

#### 使用Docker

```bash
# 构建Docker镜像
./scripts/build-docker-go.sh

# 运行Docker容器
./scripts/run-docker-go.sh
```

#### 本地编译

```bash
./go/build-go-native.sh
```

## 部署方案

项目支持四种部署方案：

1. **Docker容器（源代码上传）**：将源代码上传到服务器，在服务器上构建Docker镜像
2. **Docker容器（镜像上传）**：在本地构建Docker镜像，然后上传到服务器
3. **静态链接可执行文件**：编译静态链接的可执行文件，上传到服务器直接运行
4. **本地编译运行**：直接在本地编译和运行

详细说明请参阅[部署指南](docs/deployment.md)。

## 语言实现

### C++实现

C++版本直接使用CBC的C++接口实现。详细说明请参阅[C++使用指南](docs/cpp-guide.md)。

### Go实现

Go版本通过CGO调用C++桥接层，间接使用CBC的C++接口。详细说明请参阅[Go使用指南](docs/go-guide.md)。

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

如果您想修改问题或扩展功能，可以编辑示例程序，然后重新构建。例如，您可以：

- 修改目标函数系数
- 添加或修改约束条件
- 增加变量数量
- 尝试不同类型的约束（等式、大于等于）

## 参考资料

- [CBC官方文档](https://github.com/coin-or/Cbc)
- [COIN-OR项目](https://www.coin-or.org/)
- [混合整数规划介绍](https://en.wikipedia.org/wiki/Integer_programming)
- [Go语言CGO文档](https://golang.org/cmd/cgo/)
- [Docker文档](https://docs.docker.com/)


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

如果您想修改问题或扩展功能，可以编辑示例程序，然后重新构建。例如，您可以：

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
