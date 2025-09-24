#!/bin/bash
set -euxo pipefail

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssl \
    unzip \
    git build-essential cmake \
    libglib2.0-dev libcairo2-dev \
    autoconf \
    llvm llvm-dev clang \
    gnutls-dev libgnutls28-dev lcov wget

mkdir -p ~/cyclonedds_build
cd ~/cyclonedds_build

git clone https://github.com/eclipse-cyclonedds/cyclonedds.git
cd cyclonedds
mkdir -p build
cd build

AFL_PATH="/root/pcguard-cov"

cmake \
    -DBUILD_EXAMPLES=ON \
    -DCMAKE_C_COMPILER="$AFL_PATH/afl-clang-fast" \
    -DCMAKE_CXX_COMPILER="$AFL_PATH/afl-clang-fast++" \
    -DCMAKE_C_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard" \
    -DCMAKE_CXX_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard" \
    ..

cmake --build . --parallel

echo "success"
