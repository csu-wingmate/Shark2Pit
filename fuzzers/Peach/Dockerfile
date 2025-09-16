FROM ubuntu:20.04

# 设置非交互式前端，防止apt-get安装过程中出现交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
# 更新包列表，安装所需软件包，配置时区
RUN apt-get update && \
    echo "tzdata tzdata/Areas select Asia" | debconf-set-selections && \
    echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections && \
    apt-get install -y sudo vim && \
    echo "set nu" >>  ~/.vimrc && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    tzdata \
    coreutils apt-utils wget curl ca-certificates \
    nano \
    unzip \
    gdb \
    locales-all \
    git build-essential strace tcpdump tshark \
    wget \
    cmake \
    autoconf \
    llvm llvm-dev clang && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 预先配置debconf以自动回答tshark的安装问题
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
# 更新包列表并安装所需软件
RUN apt-get install -y --no-install-recommends tshark 

# 安装Mono 4.8.1
RUN cd /usr/bin && \
    wget https://download.mono-project.com/sources/mono/mono-4.8.1.0.tar.bz2 && \
    tar -jxvf mono-4.8.1.0.tar.bz2 && \
    cd mono-4.8.1 && \
    sudo apt-get install -y libtool-bin && \
    ./autogen.sh && \
    make get-monolite-latest

COPY --chown=ubuntu:ubuntu processes.c /usr/bin/mono-4.8.1/mono/io-layer/processes.c
# 切换到源代码目录
WORKDIR /usr/bin/mono-4.8.1

# 编译Mono
RUN sudo make -j$(nproc) && \
    sudo make install
    
# 切换到源代码目录
WORKDIR /etc/    
    
COPY --chown=ubuntu:ubuntu profile /etc/profile

RUN /bin/bash /etc/profile

# 切换到源代码目录
WORKDIR /root/
COPY --chown=ubuntu:ubuntu collect.py /root/collect.py
COPY --chown=ubuntu:ubuntu Peach /root/Peach/
COPY --chown=ubuntu:ubuntu run_peach.sh /root/run_peach.sh

RUN mkdir -p /root/Shark2Pit
COPY --chown=ubuntu:ubuntu shark2pit /root/Shark2Pit

# 赋予所有.sh文件执行权限
RUN find /root/ -type f -name "*.sh" -exec chmod +x {} \;
WORKDIR /root/
RUN git clone https://github.com/Fuyulai-Hub/pcguard-cov.git
RUN cd /root/pcguard-cov \
    && cd /root/pcguard-cov \
    && unzip -o pcguard-cov.zip \
    && make -j$(nproc)
# 构建 llvm_mode
RUN cd /root/pcguard-cov/llvm_mode/ \
    && AFL_TRACE_PC=1 make -j$(nproc)

# 容器启动命令
CMD ["bash"]

