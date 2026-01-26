# Shark2Pit: Automated Test Template Generation for Protocol Fuzzing

**Shark2Pit** is an automated tool designed to generate high-quality test templates (Pit files) for protocol fuzzing. By leveraging **Tshark** for packet parsing, Shark2Pit extracts protocol metadata and constructs data models to synthesize structural-valid data and state models.


## 🌟 Key Features

*   **Automated Parsing:** Converts PCAP/PCAPNG traffic into structured PDML formats automatically.
*   **Structure-Preserving Synthesis:** Generates novel data models while maintaining protocol structural validity using the `--synthetic` flag.
*   **State Model Enhancement:** Supports state shuffling and repetition strategies to explore deeper interaction paths.
*   **Extensibility:** Designed to easily integrate new protocols and fuzzing engines.



## 📂 Project Structure

The project is organized as follows:

```text
Shark2Pit
├── pcaps/       # Input: Raw protocol traffic files (e.g., coap.pcap)
├── pdml/        # Intermediate: Tshark parsing outputs
├── json/        # Intermediate: Preprocessing results
├── pit/         # Output: Generated Pit files (XML)
├── tool/        # Core Shark2Pit implementation source code
├── subjects/    # Target protocol implementations for evaluation
│   ├── bacnet/
│   └── coap/    # Includes build scripts (e.g., coap_build.sh)
├── fuzzers/     # Generation-based fuzzing engines
│   ├── Peach/
│   └── PeachStar/
└── Shark2Pit.sh # Main entry script
```


## 🚀 Installation

Shark2Pit is optimized for **Ubuntu 20.04 (64-bit)** or newer. We strongly recommend using Docker to ensure a consistent environment.

### Option 1: Pull from Docker Hub (Recommended)
This is the fastest way to get started. The docker image contains the tool and pre-configured dependencies.

```bash
docker pull fyldocker/shark2pit:peach
docker run -it --privileged --name shark2pit fyldocker/shark2pit:peach /bin/bash
```

### Option 2: Build from Source
If you prefer to build the environment locally or modify the source code:

```bash
# 1. Install system dependencies
apt update && apt install -y tshark tcpdump

# 2. Clone the repository
cd /root
git clone https://github.com/csu-wingmate/Shark2Pit.git

# 3. Build the Docker image
cd /root/Shark2Pit/fuzzers/Peach
docker build . -t shark2pit

# 4. Run the container
docker run -it --privileged --name shark2pit shark2pit /bin/bash
```



## 🛠️ Usage

The main functionality is accessed via the `Shark2Pit.sh` script.

```bash
./Shark2Pit.sh [options] <protocol_name> [layer1 layer2 ...]
```

### Arguments
*   **`protocol_name`**: The name of the protocol to process (corresponds to the filename in `pcaps/` without extension).
*   **`layer_list`**: Space-separated list of protocol layers to analyze (e.g., `coap`, `dns`, `mbtcp`).

### Options
*   `-h`, `--help`: Show the help message.
*   `-s`, `--synthetic`: **(Recommended)** Enable data reconstitution (packet reassembly) to generate diverse data models.
*   `-sh`, `--shuffle`: Enable state shuffling to discover new transition paths.
*   `-r`, `--repeat`: Specify the number of times to repeat states (tests protocol stability).

### Examples
```bash
# Basic generation for CoAP
./Shark2Pit.sh coap coap

# Generation with synthetic data, state shuffling, and state repetition
./Shark2Pit.sh -s -sh -r 2 coap coap

# Multi-layer protocols
./Shark2Pit.sh modbus modbus mbtcp
./Shark2Pit.sh -s dns dns
```



## 📖 Tutorial: Fuzzing libcoap

This tutorial demonstrates how to generate a Pit file for CoAP and run the Peach fuzzer.

### 1. Environment Setup
Enter the working directory inside the container:
```bash
cd /root/Shark2Pit
```

### 2. Build the Target Protocol
*Note: If you used **Option 1 (Docker Pull)**, the targets are pre-built, and you can skip this step.*

If you built from source, compile the CoAP implementation:
```bash
cd /root/Shark2Pit/subjects/coap
./coap_build.sh
cd /root/Shark2Pit # Return to root
```

### 3. Generate Pit File
Generate the test template using Shark2Pit with synthesis enabled:
```bash
./Shark2Pit.sh -s -sh -r 2 coap coap
```

### 4. Start Fuzzing
Run the fuzzing script. The default protocol is CoAP.
```bash
cd /root/Shark2Pit/fuzzers/Peach
./run_peach.sh coap
```



## 🏆 Real-world Bug Discovery

To validate the effectiveness of Shark2Pit, we evaluated it against several actively maintained, open-source protocol implementations. Shark2Pit successfully uncovered **5 previously unknown bugs**, ranging from memory safety violations to undefined behaviors. All discovered bugs have been reported to the respective vendors, and most have been fixed.

The table below summarizes the critical vulnerabilities found by Shark2Pit:

| Target Protocol | Bug Type | Issue ID / Link | Status |
| :--- | :--- | :--- | :--- |
| **libcoap** | Use-of-uninitialized-value | [obgm/libcoap#1720](https://github.com/obgm/libcoap/issues/1720) | Acked |
| **libcoap** | Heap-use-after-free | [obgm/libcoap#1659](https://github.com/obgm/libcoap/issues/1659) | **Fixed** |
| **OpENer** | Undefined-behavior | [EIPStackGroup/OpENer#532](https://github.com/EIPStackGroup/OpENer/issues/532) | **Fixed** |
| **bacnet-stack** | Use-of-uninitialized-value | [bacnet-stack/bacnet-stack#1045](https://github.com/bacnet-stack/bacnet-stack/issues/1045) | **Fixed** |
| **open62541** | Undefined-behavior | [open62541/open62541#7358](https://github.com/open62541/open62541/issues/7358) | Acked |



## 🔌 Extensibility

Shark2Pit is designed to be easily extended to new protocols and fuzzers.

### Adding a New Target Protocol
To add a protocol (e.g., FTP) and a target server (e.g., LightFTP):

1.  **Create Protocol Directory:** Create a new folder in `subjects/`.
    ```text
    subjects/ftp/
    └── ftp_build.sh  # Script to build the target binary
    ```
2.  **Update Configuration:** Register the protocol in `tool/shark2pit_config.json`.
    ```json
    "ftp": {
      "transport": "Tcp",
      "default_executable": "/root/LightFTP/Source/Release/fftp",
      "default_arguments": "/root/LightFTP/Bin/fftp.conf",
      "default_host": "127.0.0.1",
      "default_port": 21,
      "agent_class": "TcpClient"
    }
    ```

### Adding a New Fuzzer
To integrate a new fuzzing engine (e.g., PeachStar):

1.  **Create Fuzzer Directory:**
    ```text
    fuzzers/PeachStar/
    ├── Dockerfile          # For building the fuzzer environment
    ├── run_peachstar.sh    # Execution script
    └── ...                 # Other dependencies
    ```
2.  **Follow Templates:** Refer to the existing `fuzzers/Peach/` directory for structure and naming conventions.

---

## 🎥 Demo Video

A demonstration of Shark2Pit in action can be viewed here:
[[Demo Video](https://youtu.be/kPuTv74w16Y)]


