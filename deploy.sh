#!/bin/bash

# 服务器配置
SERVER_HOST="43.139.225.193"
SERVER_PORT="22"
SERVER_USER="root"
SERVER_PATH="/root/CBC"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}CBC项目部署脚本${NC}"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -a, --all             上传所有核心项目文件"
    echo "  -c, --code            只上传代码文件 (main.cpp)"
    echo "  -d, --docker          只上传Docker相关文件 (Dockerfile, docker-compose.yml)"
    echo "  -b, --build           上传后在服务器上构建Docker镜像"
    echo "  -r, --run             上传后在服务器上构建并运行Docker容器"
    echo "  -f, --file <文件>      上传指定文件"
    echo "  -h, --help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --all              上传所有核心项目文件"
    echo "  $0 --code --build     上传代码文件并构建Docker镜像"
    echo "  $0 --file main.cpp    只上传main.cpp文件"
    echo "  $0 --all --run        上传所有文件并构建运行Docker容器"
}

# 上传文件函数
upload_file() {
    local file=$1
    if [ -f "$file" ]; then
        echo -e "${YELLOW}上传文件: ${file}${NC}"
        scp -P $SERVER_PORT "$file" $SERVER_USER@$SERVER_HOST:$SERVER_PATH/
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 文件 ${file} 上传成功${NC}"
        else
            echo -e "${RED}✗ 文件 ${file} 上传失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ 错误: 文件 ${file} 不存在${NC}"
        exit 1
    fi
}

# 在服务器上执行命令
execute_command() {
    local command=$1
    echo -e "${YELLOW}在服务器上执行: ${command}${NC}"
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && $command"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 命令执行成功${NC}"
    else
        echo -e "${RED}✗ 命令执行失败${NC}"
        exit 1
    fi
}

# 默认参数
UPLOAD_ALL=false
UPLOAD_CODE=false
UPLOAD_DOCKER=false
BUILD_DOCKER=false
RUN_DOCKER=false
SPECIFIC_FILE=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            UPLOAD_ALL=true
            shift
            ;;
        -c|--code)
            UPLOAD_CODE=true
            shift
            ;;
        -d|--docker)
            UPLOAD_DOCKER=true
            shift
            ;;
        -b|--build)
            BUILD_DOCKER=true
            shift
            ;;
        -r|--run)
            BUILD_DOCKER=true
            RUN_DOCKER=true
            shift
            ;;
        -f|--file)
            SPECIFIC_FILE="$2"
            shift
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 如果没有指定任何上传选项，显示帮助
if [[ "$UPLOAD_ALL" == "false" && "$UPLOAD_CODE" == "false" && "$UPLOAD_DOCKER" == "false" && -z "$SPECIFIC_FILE" ]]; then
    echo -e "${RED}错误: 请指定要上传的文件${NC}"
    show_help
    exit 1
fi

# 确保服务器上的目标目录存在
echo -e "${YELLOW}确保目标目录存在: ${SERVER_PATH}${NC}"
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "mkdir -p $SERVER_PATH"

# 上传文件
if [[ "$UPLOAD_ALL" == "true" ]]; then
    echo -e "${BLUE}上传所有核心项目文件...${NC}"
    CORE_FILES=("main.cpp" "CMakeLists.txt" "Dockerfile" ".dockerignore" "docker-compose.yml" "build-docker.sh" "run-docker.sh" "README.md")
    for file in "${CORE_FILES[@]}"; do
        upload_file "$file"
    done
fi

if [[ "$UPLOAD_CODE" == "true" ]]; then
    echo -e "${BLUE}上传代码文件...${NC}"
    upload_file "main.cpp"
    upload_file "CMakeLists.txt"
fi

if [[ "$UPLOAD_DOCKER" == "true" ]]; then
    echo -e "${BLUE}上传Docker相关文件...${NC}"
    upload_file "Dockerfile"
    upload_file ".dockerignore"
    upload_file "docker-compose.yml"
    upload_file "build-docker.sh"
    upload_file "run-docker.sh"
fi

if [[ -n "$SPECIFIC_FILE" ]]; then
    echo -e "${BLUE}上传指定文件...${NC}"
    upload_file "$SPECIFIC_FILE"
fi

# 设置脚本执行权限
if [[ "$UPLOAD_ALL" == "true" || "$UPLOAD_DOCKER" == "true" ]]; then
    echo -e "${YELLOW}设置脚本执行权限...${NC}"
    execute_command "chmod +x build-docker.sh run-docker.sh"
fi

# 构建Docker镜像
if [[ "$BUILD_DOCKER" == "true" ]]; then
    echo -e "${BLUE}在服务器上构建Docker镜像...${NC}"
    execute_command "./build-docker.sh"
fi

# 运行Docker容器
if [[ "$RUN_DOCKER" == "true" ]]; then
    echo -e "${BLUE}在服务器上运行Docker容器...${NC}"
    execute_command "./run-docker.sh"
fi

echo -e "${GREEN}部署完成!${NC}"
