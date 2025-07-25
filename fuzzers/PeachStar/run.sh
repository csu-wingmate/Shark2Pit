#!/bin/bash

# Define cleanup function
function cleanup {
    echo "Cleaning up ${project}[$$]"
    pkill -P $$  # Kill all child processes

    # Get PIDs in network namespace
    pids=$(ip netns pids${netns})

    echo "Cleaning ${netns}, pids:${pids}"
    # Kill processes
    for pid in $pids; do
        kill -9 $pid
    done
}

# Set trap for EXIT signal
trap cleanup EXIT

# Number of workers
protocol=${1:-coap}
worker_num=${2:-1}
index=${3:-1}

# Current timestamp
ttime=`date +%Y-%m-%d-%T`
t="peach_${protocol}-${ttime}"

# Temp file paths
cov_edge_path="/dev/shm/cov_edge_${t}"
cov_bitmap_path="/dev/shm/cov_bitmap_${t}"

# Create temp files
dd if=/dev/zero of=${cov_edge_path}  bs=10M count=1
dd if=/dev/zero of=${cov_bitmap_path} bs=10M count=1
export LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path}

# Create temp dir
mkdir -p branch

# Run coverage collector
python3 /root/collect.py ${cov_edge_path} \
    "./branch/collect_branch_peach_${protocol}_${t}" &

# Peach fuzzer path
FUZZER_PATH=/root/PeachStar/output/linux_x86_64_release

# Start workers
for i in $(seq 1 ${worker_num}) ; do
    netns="netns-peach-${index}-${protocol}-${i}"

    echo "Starting worker ${i} in ${netns}"

    # Create network namespace
    ip netns add ${netns}

    # Enable loopback interface
    ip netns exec ${netns} ip link set lo up

    # Launch worker in namespace
    ip netns exec ${netns} bash -c "
        LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path} SHM_ENV_VAR=${cov_bitmap_path} \
        PATH=${FUZZER_PATH}:$PATH LD_LIBRARY_PATH=${FUZZER_PATH}:$LD_LIBRARY_PATH \
        timeout 86400 mono ${FUZZER_PATH}/bin/peach.exe \
            /root/Shark2Pit/pit/${protocol}.xml  &

    "
done