#!/bin/bash
set -euxo pipefail

# 设置非交互式前端（防止安装过程中的交互提示）
export DEBIAN_FRONTEND=noninteractive

# 更新系统并安装依赖项
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    openssl unzip \
    git build-essential \
    libglib2.0-dev libcairo2-dev \
    autoconf \
    llvm llvm-dev clang \
    gnutls-dev libgnutls28-dev lcov wget

# 克隆 LightFTP 仓库
cd /root
REPO_URLS=(
    "http://github.com/hfiref0x/LightFTP.git"
)
for url in "${REPO_URLS[@]}"; do
    dir_name=$(basename "$url" .git)  # 自动提取目录名（如 repo1）
    if [ -d "$dir_name" ]; then
        echo "skipping clone: $dir_name"
    else
        echo "start clone: $url"
        git clone "$url"
    fi
done

# 编译 LightFTP
cd LightFTP/Source/Release

# 设置 AFL 编译器路径（根据实际安装位置调整）
AFL_PATH="/root/pcguard-cov"

# 使用 AFL 编译器进行编译
export CC=$AFL_PATH/afl-clang-fast
export CXX=$AFL_PATH/afl-clang-fast++
export CFLAGS="-Wall -O2 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard"
export CXXFLAGS="$CFLAGS"
make

# 创建日志目录和文件
sudo mkdir -p /home/user/
sudo touch /home/user/fftplog

echo "LightFTP finish！"
echo "可执行文件位置: ~/LightFTP/Source/Release/fftp"
echo "日志文件位置: /home/user/fftplog"