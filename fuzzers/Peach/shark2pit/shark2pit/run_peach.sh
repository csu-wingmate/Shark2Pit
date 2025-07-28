#!/bin/bash

# 存储所有后台进程PID
declare -a BACKGROUND_PIDS=()
declare -A NETNS_PEACH_PIDS  # 存储每个网络命名空间中的Peach进程PID

# 增强版清理函数
cleanup() {
    echo "Worker: 收到中断信号，开始清理..."
    
    # 第一步：终止所有后台进程（包括收集器）
    for pid in "${BACKGROUND_PIDS[@]}"; do
        if ps -p "$pid" > /dev/null; then
            echo "终止进程 $pid"
            kill -TERM "$pid" 2>/dev/null
        fi
    done
    
    # 第二步：终止所有Peach进程（包括Pit文件启动的子进程）
    for netns in "${!NETNS_PEACH_PIDS[@]}"; do
        pid=${NETNS_PEACH_PIDS[$netns]}
        if ps -p "$pid" > /dev/null; then
            echo "终止Peach主进程 $pid (${netns})"
            kill -TERM "$pid" 2>/dev/null
            
            # 终止整个进程组（包括Pit文件启动的所有子进程）
            pkill -9 -g $(ps -o pgid= $pid | tr -d ' ') 2>/dev/null
        fi
    done
    
    # 第三步：清理网络命名空间
    for i in $(seq 1 ${worker_num}); do
        netns="netns-peach-${index}-${protocol}-${i}"
        if ip netns list | grep -q "${netns}"; then
            # 强制终止命名空间中的所有进程
            ip netns pids ${netns} | xargs -r kill -9 2>/dev/null
            
            # 删除命名空间
            ip netns del ${netns} 2>/dev/null && \
            echo "已删除网络命名空间: ${netns}" || \
            echo "删除 ${netns} 失败（可能已不存在）"
        fi
    done
    
    # 第四步：清理临时文件
    rm -f ${cov_edge_path} ${cov_bitmap_path} /tmp/peach_*.pid
    echo "Worker: 清理完成，退出脚本"
    exit 0
}

# 设置中断信号处理
trap cleanup SIGINT SIGTERM

# 工作进程数量
protocol=${1:-coap}
worker_num=${2:-1}
index=${3:-1}

# 当前时间
ttime=$(date +%Y-%m-%d-%T)
t="peach_${protocol}-${ttime}"

# 创建临时文件路径
cov_edge_path="/dev/shm/cov_edge_${t}"
cov_bitmap_path="/dev/shm/cov_bitmap_${t}"

# 创建临时文件
dd if=/dev/zero of=${cov_edge_path} bs=10M count=1
dd if=/dev/zero of=${cov_bitmap_path} bs=10M count=1
export LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path}

# 创建临时目录
mkdir -p branch

# 运行收集器（保存PID）
python3 /root/collect.py ${cov_edge_path} \
    "./branch/collect_branch_peach_${protocol}_${t}" &
BACKGROUND_PIDS+=($!)

# Peach 模糊测试的路径
FUZZER_PATH=/root/Peach

# 启动工作进程
for i in $(seq 1 ${worker_num}); do
    netns="netns-peach-${index}-${protocol}-${i}"
    echo "启动工作进程 ${i} (${netns})"

    # 创建网络命名空间
    ip netns add ${netns}
    ip netns exec ${netns} ip link set lo up

    # 在工作进程中启动Peach（保存PID到文件）
    ip netns exec ${netns} bash -c "
        # 设置进程组ID以便终止整个组
        set -m
        
        LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path} SHM_ENV_VAR=${cov_bitmap_path} \
        PATH=${FUZZER_PATH}:$PATH LD_LIBRARY_PATH=${FUZZER_PATH}:$LD_LIBRARY_PATH \
        timeout 86400 mono ${FUZZER_PATH}/bin/peach.exe \
            /root/shared/test/pit/${protocol}.xml &
        
        peach_pid=\$!
        echo \$peach_pid > /tmp/peach_${netns}.pid
        wait \$peach_pid
    " &
    
    # 保存网络命名空间进程PID
    ns_pid=$!
    BACKGROUND_PIDS+=($ns_pid)
    
    # 等待PID文件创建并记录Peach PID
    sleep 0.5
    if [ -f "/tmp/peach_${netns}.pid" ]; then
        peach_pid=$(cat "/tmp/peach_${netns}.pid")
        NETNS_PEACH_PIDS[$netns]=$peach_pid
        echo "记录Peach PID: ${peach_pid} (${netns})"
    fi
done

# 关键：等待中断信号
echo "主进程已启动，按 Ctrl+C 终止所有工作进程"
echo "监控中的Peach PIDs: ${NETNS_PEACH_PIDS[@]}"
while true; do
    sleep 3600 &  # 使用后台sleep
    wait $!       # 等待sleep完成或被中断
done