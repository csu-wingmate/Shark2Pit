#!/bin/bash
cd /root
git clone https://github.com/stargieg/bacnet-stack.git
cd bacnet-stack
git checkout 4f11def
mkdir -p build
cd build
cmake -DBUILD_EXAMPLES=ON \
    -DCMAKE_C_COMPILER=/root/pcguard-cov/afl-clang-fast \
    -DCMAKE_CXX_COMPILER=/root/pcguard-cov/afl-clang-fast++ \
    -DCMAKE_C_FLAGS="-Wall -O1 -g -fno-omit-frame-pointer -fsanitize=memory -fsanitize-memory-track-origins -fsanitize-coverage=trace-pc-guard" \
    -DCMAKE_CXX_FLAGS="-Wall -O1 -g -fno-omit-frame-pointer -fsanitize=memory -fsanitize-memory-track-origins -fsanitize-coverage=trace-pc-guard" \
    ..
make -j
