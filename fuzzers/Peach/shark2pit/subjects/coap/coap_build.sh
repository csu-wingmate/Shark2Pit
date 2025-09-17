#!/bin/bash
# 设置日志输出
set -e  # 出错立即退出
apt-get update
apt-get install -y sudo 
# 更新包列表并安装依赖
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
    unzip \
    git build-essential \
    llvm llvm-dev clang \
    autoconf automake pkg-config libtool libtool-bin \
    gnutls-dev libgnutls28-dev lcov wget

# 创建工作目录并进入
cd /root/
git clone https://github.com/obgm/libcoap.git

# 回到根目录并克隆 libcoap
cd /root/libcoap
git checkout 60e9f08
# 配置 libcoap 的编译环境
export CC=/root/pcguard-cov/afl-clang-fast
export CXX=/root/pcguard-cov/afl-clang-fast++
export CFLAGS="-Wall -O2 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-fsanitize=address,undefined"
export AFL_USE_ASAN=1 ASAN_OPTIONS=detect_leaks=0

# 执行构建步骤
./autogen.sh
./configure --disable-doxygen --disable-manpages --enable-tests --disable-documentation --enable-examples --disable-shared --disable-tests
make -j

echo "All operations completed successfully!"
