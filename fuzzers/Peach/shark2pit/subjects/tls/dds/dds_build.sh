#!/bin/bash
set -euxo pipefail

# 安装依赖项 (使用非交互模式)
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssl \
    unzip \
    git build-essential cmake \
    libglib2.0-dev libcairo2-dev \
    autoconf \
    llvm llvm-dev clang \
    gnutls-dev libgnutls28-dev lcov wget

# 创建工作目录
mkdir -p ~/cyclonedds_build
cd ~/cyclonedds_build

# 克隆仓库
git clone https://github.com/eclipse-cyclonedds/cyclonedds.git
cd cyclonedds
mkdir -p build
cd build

# 注意：以下路径需要根据你的 AFL 实际安装位置修改
AFL_PATH="/root/pcguard-cov"

# 运行 CMake 和构建
cmake \
    -DBUILD_EXAMPLES=ON \
    -DCMAKE_C_COMPILER="$AFL_PATH/afl-clang-fast" \
    -DCMAKE_CXX_COMPILER="$AFL_PATH/afl-clang-fast++" \
    -DCMAKE_C_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard" \
    -DCMAKE_CXX_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard" \
    ..

cmake --build . --parallel

echo "success"