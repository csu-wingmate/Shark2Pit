#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y \
    git build-essential cmake \
    make
cd /root
git clone https://github.com/dnp3/opendnp3.git
cd /root/opendnp3
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DDNP3_EXAMPLES=ON \
  -DCMAKE_C_COMPILER=/root/pcguard-cov/afl-clang-fast \
  -DCMAKE_CXX_COMPILER=/root/pcguard-cov/afl-clang-fast++ \
  -DCMAKE_C_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer" \
  -DCMAKE_CXX_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer"
make