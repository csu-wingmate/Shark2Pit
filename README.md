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
docker build . -t peach
```


# Demo Video
[Click to view the demo video](https://youtu.be/6tuphioX930.)
