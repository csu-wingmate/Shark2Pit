#!/bin/bash
set -euxo pipefail
sudo apt install -y cmake build-essential
cd /root
git clone https://github.com/open62541/open62541.git
cd open62541
mkdir build && cd build
cmake .. -DUA_BUILD_EXAMPLES=ON \
         -DBUILD_EXAMPLES=ON \
         -DCMAKE_C_COMPILER=/root/pcguard-cov/afl-clang-fast \
         -DCMAKE_CXX_COMPILER=/root/pcguard-cov/afl-clang-fast++ \
         -DCMAKE_C_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer" \
         -DCMAKE_CXX_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer"
make