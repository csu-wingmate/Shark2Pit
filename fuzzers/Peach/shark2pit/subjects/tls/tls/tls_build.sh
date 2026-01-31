#!/bin/bash

# Set non-interactive frontend to prevent interactive prompts during installation
export DEBIAN_FRONTEND=noninteractive

# Update package list and install required software packages
apt-get update && \
apt-get upgrade -y && \
apt-get install -y \
    unzip \
    git build-essential \
    llvm llvm-dev clang

# Install additional dependencies
apt-get install -y \
    gnutls-dev libgnutls28-dev lcov wget

# Create and change to working directory
mkdir -p /root/
cd /root/

# Clone OpenSSL repository
cd /root
git clone https://github.com/openssl/openssl.git
cd /root/openssl
# Configure, build and install OpenSSL with AFL and ASAN
CC=/root/pcguard-cov/afl-clang-fast CXX=/root/pcguard-cov/afl-clang-fast++ AFL_USE_ASAN=1 ./Configure --prefix=/usr/local
CC=/root/pcguard-cov/afl-clang-fast CXX=/root/pcguard-cov/afl-clang-fast++ AFL_USE_ASAN=1 make
CC=/root/pcguard-cov/afl-clang-fast CXX=/root/pcguard-cov/afl-clang-fast++ AFL_USE_ASAN=1 make install

# Copy libraries
cp -r /usr/local/lib64/* /usr/lib/