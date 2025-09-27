# Shark2Pit - Automated Pit Template Generation For Protocol Fuzzing Based on Packet Parser
Shark2Pit is an automated tool that generates Pit template files for generation-based protocol fuzzing, such as Peach and its variants. It parses real network traffic (in pcap/pcapng format) and uses Tshark to extract protocol field information, automatically constructing data models and state models while synthesizing new test cases that comply with the protocol structure. The tool ultimately outputs Pit files that can be directly used for fuzzing. Key features include automated modeling, which eliminates the need for manually writing Pit files and significantly reduces the barrier and labor cost of protocol fuzzing; structure-preserving synthesis, which generates diverse test cases while maintaining protocol semantics to improve code path coverage; and multi-protocol support, allowing extension to any protocol supported by Tshark. Shark2Pit enables a fully automated workflow from traffic to test template generation, making it suitable for security testing and vulnerability mining in protocol implementations.
# Folder Structure
```
Shark2Pit
├── pcaps: folders for different protocol traffic
│   └── coap.pcap
│   └── dns.pcap
│   └── other traffic files (e.g.dds.pcap)
├── pdml: folders for Tshark parsing output
│   └── coap.pdml
│   └── dns.pdml
│   └── other files (e.g.dds.pdml)
├── json: folders for preprocessing results
│   └── coap.json
│   └── dns.json
│   └── other files (e.g.dds.json)
├── pit: folders for different Pit files
│   └── coap.xml
│   └── dns.xml
│   └── other files (e.g.dds.xml)
├── tool: Shark2Pit implementations
├── subjects: folders for different protocol implementations
│   └── bacnet
│       └── bacnet_build.sh: build protolcol impementation
│   └── other folders (e.g.coap)
├── fuzzers: contains folders for different generation-based fuzzing tool
│   └── Peach
│       └── Dockerfile: for building the Docker image of the Peach fuzzer
│       └── run_peach.sh: start Peach fuzzing
│       └── other necessary files (e.g.scripts)
│   └── PeachStar
│       └── Dockerfile: for building the Docker image of the PeachStar fuzzer
│       └── run_peachstar.sh: start Peachstar fuzzing
│       └── other necessary files (e.g.scripts)
└── Shark2Pit.sh: start Shark2Pit
└── README.md: this file
```
# Shark2Pit Installation (Tested on Ubuntu 20.04 64-bit (or newer); Docker required.)
```
apt update
apt install -y tshark tcpdump
cd /root
git clone https://github.com/csu-wingmate/Shark2Pit.git
cd /root/Shark2Pit/fuzzers/Peach
docker build . -t shark2pit
docker run -it --privileged --shm-size=2G --name shark2pit shark2pit /bin/bash
```
# Usage
```
Usage: ./Shark2Pit.sh [options] <protocol_name> [layer1 layer2 ...]
Automatically convert PCAP/PCAPNG files to PDML format and generate Pit files

Arguments:
  protocol_name     Name of the protocol to process (without file extension)
  layer_list        List of protocol layers to process (e.g., coap dns http)

Options:
  -h, --help        Show this help message
  -s, --synthetic   Enable packet reassembly during Pit generation
  -sh, --shuffle    Shuffle states during Pit generation
  -r, --repeat      Number of times to repeat the state

Examples:
  ./Shark2Pit.sh modbus modbus mbtcp
  ./Shark2Pit.sh coap coap
  ./Shark2Pit.sh -s dns dns
  ./Shark2Pit.sh -s -sh -r 2 coap coap
```

# Tutorial - Fuzzing libcoap server with Peach
## Step-1. Set up environmental variables
```
cd /root/Shark2Pit
export Shark2Pit=$(pwd)
```
## Step-2. Building the libcoap Protocol Implementation
```bash
cd $Shark2Pit/subjects/coap
./coap_build.sh
```
## Step-3. Generate Pit file and Fuzzing
To learn how to use Shark2Pit, you can execute the command `./Shark2Pit.sh -h `to view the help documentation.
```bash
cd $Shark2Pit
./Shark2Pit.sh coap coap
./run_peach.sh coap
```

# FAQs
## 1. How do I extend Shark2Pit?
### 1）add a target protocol
To add a new protocol and/or a new target server for a supported protocol, follow the folder structure outlined above and complete the following steps, using LightFTP as an example:

#### Step-1. Create a new folder for the protocol/target server
The folder for LightFTP server is located at [subjects/ftp].

#### Step-2. Write a prepare subject-specific script
Refer to the existing folder structure for ftp
```
subjects/ftp/
├──ftp_build.sh (required): script to build experiment inside a container 
```
#### Step-3. Add parameters in tool/shark2pit_config.json
Add the necessary parameters in tool/shark2pit_config.json.
```
"ftp": {
        "transport": "tcp",
        "default_executable":"/root/LightFTP/Source/Release/fftp",
        "default_arguments":"/root/LightFTP/Bin/fftp.conf ",
        "default_host":"127.0.0.1",
        "default_port": 21,
        "agent_class": "TcpClient"
      }
```

### 2）add a fuzzer
To add a new fuzzer, follow the folder structure outlined above and complete the following steps, using PeachStar as an example:

#### Step-1. Create a new folder for fuzzer
The folder for PeachStar is located at [fuzzers/PeachStar](https://github.com/csu-wingmate/Shark2Pit/tree/master/fuzzers/PeachStar).

#### Step-2. Write a Dockerfile file
Refer to the existing folder structure for PeachStar
```
fuzzers/PeachStar
├── Dockerfile (required): based on this, a Docker image is built (See Shark2Pit)
└── other files (required): dependencies for building Peachstar.
```
All the required files (i.e., Dockerfile) follow some templates so that one can easily follow them to prepare files for a new fuzzer.
# Demo Video
[Click to view the demo video](https://youtu.be/eVpCG0vjpPQ)
