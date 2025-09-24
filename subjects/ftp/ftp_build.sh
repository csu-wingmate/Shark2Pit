#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y \
    openssl unzip \
    git build-essential \
    libglib2.0-dev libcairo2-dev \
    autoconf \
    llvm llvm-dev clang \
    gnutls-dev libgnutls28-dev lcov wget

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
cd /root/LightFTP
git checkout 8b453c2
cd /root/LightFTP/Source/Release
AFL_PATH="/root/pcguard-cov"
export CC=$AFL_PATH/afl-clang-fast
export CXX=$AFL_PATH/afl-clang-fast++
export CFLAGS="-Wall -O2 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard"
export CXXFLAGS="$CFLAGS"
make -j

sudo mkdir -p /home/user/
sudo touch /home/user/fftplog

echo "LightFTP finish！"
echo "Executable location: ~/LightFTP/Source/Release/fftp"
echo "Log file location: /home/user/fftplog"
