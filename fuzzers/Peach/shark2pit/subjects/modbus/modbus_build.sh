#!/bin/bash
apt-get update
apt-get install -y autoconf automake libtool gcc make pkg-config build-essential gnutls-dev libgnutls28-dev lcov
cd /root
git clone https://github.com/stephane/libmodbus.git
cd /root/libmodbus
#mkdir -p build && cd build
# 生成配置脚本
./autogen.sh

# 设置AFL环境变量
export CC=/root/pcguard-cov/afl-clang-fast
export CXX=/root/pcguard-cov/afl-clang-fast++
export AFL_USE_ASAN=1
export CFLAGS="-O2 -g -fsanitize=address,undefined -fno-omit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-fsanitize=address,undefined"

# 配置并编译
./configure \
    --prefix=/usr/local \
    --enable-static \
    --disable-shared

make -j$(nproc)