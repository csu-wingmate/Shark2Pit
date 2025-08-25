# Shark2Pit - Automated Pit Template Generation For Protocol Fuzzing Based on Packet Parser

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
│       └── Dockerfile: for building the Docker image specific to the fuzzing tool
│       └── run.sh: main script to fuzzing inside a Docker container
│       └── other necessary files (e.g.scripts)
└── Shark2Pit.sh: start Shark2Pit
└── run_peach.sh: start peach fuzzing
└── README.md: this file
```
# Tutorial - Fuzzing LightFTP server with Peach
## Step-1. Set up environmental variables
```
git clone https://github.com/csu-wingmate/Shark2Pit.git
cd Shark2Pit
export Shark2Pit=$(pwd)
```

## Step-2. Build a Fuzzer and Shark2Pit Docker image
```bash
cd $Shark2Pit
cd fuzzers/Peach
docker build . -t shark2pit
docker run -d --privileged --shm-size=2G --name shark2pit shark2pit /bin/bash -c "while true; do sleep 1; done"
```
## Step-3. Generate Pit file and Fuzzing
To learn how to use Shark2Pit, you can execute the command `./Shark2Pit.sh -h `to view the help documentation.
```bash
cd Shark2Pit
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
├── Dockerfile (required): based on this, a Docker image is built (See Sdtep-2 in the tutorial)
└── other files (required): dependencies for building Peachstar.
```
All the required files (i.e., Dockerfile) follow some templates so that one can easily follow them to prepare files for a new fuzzer.
# Demo Video
[Click to view the demo video](https://youtu.be/6tuphioX930.)
