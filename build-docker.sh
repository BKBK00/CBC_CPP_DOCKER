#!/bin/bash
# 包装脚本，调用scripts/build-docker-cpp.sh
cd "$(dirname "$0")"
./scripts/build-docker-cpp.sh
