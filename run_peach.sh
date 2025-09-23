#!/bin/bash

# Store all background process PIDs
declare -a BACKGROUND_PIDS=()
declare -A NETNS_PEACH_PIDS  # Store Peach process PIDs in each network namespace

# Enhanced cleanup function
cleanup() {
    echo "Worker: Received interrupt signal, starting cleanup..."
    
    # Step 1: Terminate all background processes (including collector)
    for pid in "${BACKGROUND_PIDS[@]}"; do
        if ps -p "$pid" > /dev/null; then
            echo "Terminating process $pid"
            kill -TERM "$pid" 2>/dev/null
        fi
    done
    
    # Step 2: Terminate all Peach processes (including child processes started by Pit files)
    for netns in "${!NETNS_PEACH_PIDS[@]}"; do
        pid=${NETNS_PEACH_PIDS[$netns]}
        if ps -p "$pid" > /dev/null; then
            echo "Terminating Peach main process $pid (${netns})"
            kill -TERM "$pid" 2>/dev/null
            
            # Terminate entire process group (including all child processes started by Pit files)
            pkill -9 -g $(ps -o pgid= $pid | tr -d ' ') 2>/dev/null
        fi
    done
    
    # Step 3: Clean up network namespaces
    for i in $(seq 1 ${worker_num}); do
        netns="netns-peach-${index}-${protocol}-${i}"
        if ip netns list | grep -q "${netns}"; then
            # Force terminate all processes in the namespace
            ip netns pids ${netns} | xargs -r kill -9 2>/dev/null
            
            # Delete namespace
            ip netns del ${netns} 2>/dev/null && \
            echo "Deleted network namespace: ${netns}" || \
            echo "Failed to delete ${netns} (may not exist)"
        fi
    done
    
    # Step 4: Clean up temporary files
    rm -f ${cov_edge_path} ${cov_bitmap_path} /tmp/peach_*.pid
    echo "Worker: Cleanup completed, exiting script"
    exit 0
}

# Set interrupt signal handling
trap cleanup SIGINT SIGTERM

# Number of worker processes
protocol=${1:-coap}
worker_num=${2:-1}
index=${3:-1}

# Current time
ttime=$(date +%Y-%m-%d-%T)
t="peach_${protocol}-${ttime}"

# Create temporary file paths
cov_edge_path="/dev/shm/cov_edge_${t}"
cov_bitmap_path="/dev/shm/cov_bitmap_${t}"

# Create temporary files
dd if=/dev/zero of=${cov_edge_path} bs=10M count=1
dd if=/dev/zero of=${cov_bitmap_path} bs=10M count=1
export LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path}

# Create temporary directory
mkdir -p branch

# Run collector (save PID)
python3 /root/collect.py ${cov_edge_path} \
    "./branch/collect_branch_peach_${protocol}_${t}" &
BACKGROUND_PIDS+=($!)

# Path to Peach fuzzer
FUZZER_PATH=/root/Peach

# Start worker processes
for i in $(seq 1 ${worker_num}); do
    netns="netns-peach-${index}-${protocol}-${i}"
    echo "Starting worker process ${i} (${netns})"

    # Create network namespace
    ip netns add ${netns}
    ip netns exec ${netns} ip link set lo up

    # Start Peach in worker process (save PID to file)
    ip netns exec ${netns} bash -c "
        # Set process group ID for terminating entire group
        set -m
        
        LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path} SHM_ENV_VAR=${cov_bitmap_path} \
        PATH=${FUZZER_PATH}:$PATH LD_LIBRARY_PATH=${FUZZER_PATH}:$LD_LIBRARY_PATH \
        timeout 86400 mono ${FUZZER_PATH}/bin/peach.exe \
            /root/Shark2Pit/pit/${protocol}.xml &
        
        peach_pid=\$!
        echo \$peach_pid > /tmp/peach_${netns}.pid
        wait \$peach_pid
    " &
    
    # Save network namespace process PID
    ns_pid=$!
    BACKGROUND_PIDS+=($ns_pid)
    
    # Wait for PID file creation and record Peach PID
    sleep 0.5
    if [ -f "/tmp/peach_${netns}.pid" ]; then
        peach_pid=$(cat "/tmp/peach_${netns}.pid")
        NETNS_PEACH_PIDS[$netns]=$peach_pid
        echo "Recorded Peach PID: ${peach_pid} (${netns})"
    fi
done

# Key: Wait for interrupt signal
echo "Main process started. Press Ctrl+C to terminate all worker processes"
echo "Monitored Peach PIDs: ${NETNS_PEACH_PIDS[@]}"
while true; do
    sleep 3600 &  # Use background sleep
    wait $!       # Wait for sleep to complete or be interrupted
done