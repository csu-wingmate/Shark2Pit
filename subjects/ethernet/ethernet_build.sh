#!/bin/bash
set -euxo pipefail
apt update
apt install -y build-essential cmake git libpcap-dev
cd /root
git clone https://github.com/EIPStackGroup/OpENer.git
cd /root/OpENer/bin/posix
git checkout db1d6bf
cmake \
-DBUILD_EXAMPLES=ON \
-DCMAKE_C_COMPILER=/root/pcguard-cov/afl-clang-fast \
-DCMAKE_CXX_COMPILER=/root/pcguard-cov/afl-clang-fast++ \
-DOpENer_PLATFORM:STRING="POSIX" \
-DBUILD_SHARED_LIBS:BOOL=OFF \
-DCMAKE_BUILD_TYPE:STRING="Debug" \
-DCMAKE_C_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard" \
-DCMAKE_CXX_FLAGS="-Wall -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard" \
../../source
make -j$(nproc)