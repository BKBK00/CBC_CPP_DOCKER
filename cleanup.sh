#!/bin/bash

# 删除构建目录
rm -rf build cmake-build-debug

# 删除临时上传脚本
rm -f upload-fixed-files.sh upload-modified-files.sh upload-to-server.sh deploy-to-server.sh

# 删除临时SSH密钥文件
rm -f "ssh-keygen -t rsa" "ssh-keygen -t rsa.pub"

# 删除macOS系统文件
rm -f .DS_Store

# 删除IDE配置文件
rm -rf .idea

echo "清理完成！保留了以下核心文件："
echo "- main.cpp (CBC求解器示例代码)"
echo "- CMakeLists.txt (项目构建配置)"
echo "- Dockerfile (Docker容器配置)"
echo "- .dockerignore (Docker忽略文件)"
echo "- docker-compose.yml (Docker Compose配置)"
echo "- build-docker.sh (构建Docker镜像脚本)"
echo "- run-docker.sh (运行Docker容器脚本)"
echo "- README.md (项目说明文档)"
