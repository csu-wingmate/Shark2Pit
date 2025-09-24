#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Update system and install basic dependencies
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    openssl unzip  \
    git build-essential \
    libglib2.0-dev libcairo2-dev \
    autoconf \
    llvm llvm-dev clang
    
# Create working directory
mkdir -p /root/
cd /root/

# Install additional dependency packages
sudo apt-get install -y \
    gnutls-dev libgnutls28-dev lcov wget

# Clone dnsmasq repository
git clone git://thekelleys.org.uk/dnsmasq.git 
cd /root/dnsmasq

AFL_PATH="/root/pcguard-cov"
# Set AFL compiler and sanitizer options
export CC=$AFL_PATH/afl-clang-fast
export CXX=$AFL_PATH/afl-clang-fast++
export AFL_USE_ASAN=1
export CFLAGS="-Wall -O2 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fsanitize-coverage=trace-pc-guard"
export CXXFLAGS="$CFLAGS"

# Execute compilation
make
make install

# Create log directory and file
mkdir -p /var/log/dnsmasq
touch /var/log/dnsmasq/dnsmasq.log

# Copy configuration file
cp -f /root/Shark2Pit/subjects/dns/dnsmasq.conf /root/dnsmasq/dnsmasq.conf
