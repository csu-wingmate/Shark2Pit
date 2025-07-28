
# 使用 Ubuntu 20.04 作为基础镜像
FROM ubuntu:20.04

# 设置非交互式前端，防止apt-get安装过程中出现交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表，安装所需软件包，配置时区
RUN apt-get update && \
    apt-get install -y sudo vim && \
    echo "set nu" >>  ~/.vimrc && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    tzdata \
    coreutils apt-utils wget curl openssl ca-certificates bash-completion \
    joe nano \
    unzip p7zip \
    fping hping3 httping thc-ipv6 gdb \
    tcpdump wireshark-common \
    locales-all \
    git build-essential strace tcpdump \
    ruby doxygen libxml2-utils less openjdk-8-jre xsltproc asciidoctor \
    nodejs node-typescript wget \
    apt-transport-https dirmngr gnupg ca-certificates apt-utils \
    cmake dos2unix \
    libglib2.0-dev libcairo2-dev \
    autoconf \
    llvm llvm-dev clang \
    && echo "tzdata tzdata/Areas select Asia" | debconf-set-selections \
    && echo "tzdata tzdata/Zones/Asia select Shanghai" | debconf-set-selections \
    && echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections \
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

# 设置时区环境变量
ENV TZ=Asia/Shanghai

# 更新系统并安装必要依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 添加 Wireshark 官方仓库
RUN add-apt-repository -y ppa:wireshark-dev/stable

# 预配置 wireshark-common 安装选项
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

# 安装最新版 tshark
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tshark \
    && rm -rf /var/lib/apt/lists/*

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
RUN sudo make && \
    sudo make install
    
# 切换到源代码目录
WORKDIR /etc/    
    
COPY --chown=ubuntu:ubuntu profile /etc/profile
# 执行profile文件来更新环境变量
RUN /bin/bash /etc/profile

# 切换到源代码目录
WORKDIR /root/
COPY --chown=ubuntu:ubuntu collect.py /root/collect.py
RUN mkdir tasks
COPY --chown=ubuntu:ubuntu Peach /root/Peach/
# # COPY --chown=ubuntu:ubuntu --chmod=755 run.sh /root/run.sh
# RUN sed -i 's/\r$//' run.sh
# 复制所需目录及文件（排除fuzzers目录）
COPY --chown=ubuntu:ubuntu ../../branch /root/Shark2Pit/branch
COPY --chown=ubuntu:ubuntu ../../json /root/Shark2Pit/json
COPY --chown=ubuntu:ubuntu ../../logs /root/Shark2Pit/logs
COPY --chown=ubuntu:ubuntu ../../pcaps /root/Shark2Pit/pcaps
COPY --chown=ubuntu:ubuntu ../../pdml /root/Shark2Pit/pdml
COPY --chown=ubuntu:ubuntu ../../pit /root/Shark2Pit/pit
COPY --chown=ubuntu:ubuntu ../../subjects /root/Shark2Pit/subjects
COPY --chown=ubuntu:ubuntu ../../tool /root/Shark2Pit/tool

# 复制根目录文件
# COPY --chown=ubuntu:ubuntu ../../README.md /root/Shark2Pit/
COPY --chown=ubuntu:ubuntu ../../run_peach.sh /root/Shark2Pit/
COPY --chown=ubuntu:ubuntu ../../Shark2Pit.sh /root/Shark2Pit/

# 赋予所有.sh文件执行权限
RUN find /root/Shark2Pit -type f -name "*.sh" -exec chmod +x {} \;


# 容器启动命令
CMD ["bash"]

