#!/bin/bash
# Define cleanup function
function cleanup {
    echo "Starting cleanup for ${project}[$$]"
    pkill -P $$  # Kill all child processes

    # Get process IDs in the network namespace
    pids=$(ip netns pids${netns})

    echo "Cleaning up ${netns}, pids:${pids}"
    # Kill processes
    for pid in $pids; do
        kill -9 $pid
    done
}

# Set trap to catch exit signals and execute cleanup function
trap cleanup EXIT

protocol=${1:-coap}
worker_num=${2:-1}
index=${3:-1}

# Current time
ttime=`date +%Y-%m-%d-%T`
t="peach_dns-${ttime}"

# Create temporary file paths
cov_edge_path="/dev/shm/cov_edge_${t}"
cov_bitmap_path="/dev/shm/cov_bitmap_${t}"

# Create temporary files
dd if=/dev/zero of=${cov_edge_path}  bs=10M count=1
dd if=/dev/zero of=${cov_bitmap_path} bs=10M count=1
export LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path}

# Create temporary directory
mkdir -p branch

# Run collector
python3 /root/collect.py ${cov_edge_path} \
    "./branch/collect_branch_mutable_${project}_${t}_${port}" &

# Path for Peach fuzzer
# FUZZER_PATH=/root/Peach
FUZZER_PATH=/root/PeachStar/peach-3.0.202-source/output/linux_x86_64_release

# worker_num=4
for i in $(seq 1 ${worker_num}) ; do
    netns="netns-peach-${index}-${project}-${i}"

    echo "Start worker ${i} in ${netns}"

    # Create a new network namespace for the worker
    ip netns add ${netns}

    # Create and enable the loopback interface in the new network namespace
    ip netns exec ${netns} ip link set lo up

    ip netns exec ${netns} bash -c "
        LUCKY_GLOBAL_MMAP_FILE=${cov_edge_path} SHM_ENV_VAR=${cov_bitmap_path} \
        PATH=${FUZZER_PATH}:$PATH LD_LIBRARY_PATH=${FUZZER_PATH}:$LD_LIBRARY_PATH \
        timeout 86400 mono ${FUZZER_PATH}/bin/peach.exe \
            /root/Shark2Pit/pit/${project}.xml  &
    "
done


while true; do echo 'Worker: Hit CTRL+C'; sleep 1800; done