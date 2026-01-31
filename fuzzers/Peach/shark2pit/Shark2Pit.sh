#!/bin/bash

# Display help information
show_help() {
    echo "Usage: $0 [options] <protocol_name> [layer1 layer2 ...]"
    echo "Automatically convert PCAP/PCAPNG files to PDML format and generate Pit files"
    echo
    echo "Arguments:"
    echo "  protocol_name     Name of the protocol to process (without file extension)"
    echo "  layer_list        List of protocol layers to process (e.g., coap dns http)"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -s, --synthetic   Enable packet reassembly during Pit generation"
    echo "  -sh, --shuffle    Shuffle states during Pit generation"
    echo "  -r, --repeat      Number of times to repeat the state"
    echo
    echo "Examples:"
    echo "  $0 modbus modbus mbtcp"
    echo "  $0 coap coap"
    echo "  $0 -s dns dns"
    echo "  $0 -s -sh -r 2 coap coap"
    echo "  $0 -s -sh -r 2 bacnet bacnet bvlc bacapp"
    echo "  $0 -s -sh -r 2 ethernet ethernet enip"
    exit 0
}

# Initialize flags
synthetic=false
shuffle_states=false
state_repeat_times=0

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -s|--synthetic)
            synthetic=true
            shift
            ;;
        -sh|--shuffle)
            shuffle_states=true
            shift
            ;;
        -r|--repeat)
            if [[ $# -lt 2 ]]; then
                echo "Error: Missing value for repeat option" >&2
                exit 1
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -lt 0 ]]; then
                echo "Error: Invalid repeat value '$2'. Must be a non-negative integer." >&2
                exit 1
            fi
            state_repeat_times=$2
            shift 2
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            echo "Use '$0 --help' for usage information" >&2
            exit 1
            ;;
        *)
            # First non-option argument is the protocol name
            protocol=$1
            shift
            # Remaining arguments are the layer list
            layers=("$@")
            break
            ;;
    esac
done

# Check if protocol is set
if [ -z "$protocol" ]; then
    echo "Error: Missing protocol name" >&2
    echo "Use '$0 --help' for usage information" >&2
    exit 1
fi

# Check if at least one layer is provided
if [ ${#layers[@]} -eq 0 ]; then
    echo "Error: At least one protocol layer must be specified" >&2
    echo "Use '$0 --help' for usage information" >&2
    exit 1
fi

# Dynamically detect file type
pcap_file="./pcaps/${protocol}.pcap"
pcapng_file="./pcaps/${protocol}.pcapng"

if [ -f "$pcap_file" ]; then
    input_file="$pcap_file"
    echo "Using PCAP file: $input_file"
elif [ -f "$pcapng_file" ]; then
    input_file="$pcapng_file"
    echo "Using PCAPNG file: $input_file"
else
    echo "Error: Neither ${protocol}.pcap nor ${protocol}.pcapng found" >&2
    exit 1
fi

# Create output directories
mkdir -p "./pdml/"
mkdir -p "./json/"
mkdir -p "./pit/"

# Convert pcap to pdml
echo "Converting $input_file to PDML format..."
tshark -r "$input_file" -T pdml > "./pdml/$protocol.pdml" || {
    echo "Error: Tshark conversion failed" >&2
    exit 1
}

# Process PDML file with Python script
echo "Processing PDML file and generating JSON..."
python3 "./tool/preproc.py" \
    "./pdml/$protocol.pdml" \
    "./json/$protocol.json" \
    --layers "${layers[@]}" || {
    echo "Error: preproc.py processing failed" >&2
    exit 1
}

# Prepare flags for forpit.py
synthetic_flag=""
if [ "$synthetic" = true ]; then
    synthetic_flag="--synthetic"
    echo "Enabling packet reassembly (synthetic mode)"
fi

shuffle_flag=""
if [ "$shuffle_states" = true ]; then
    shuffle_flag="--shuffle-states"
    echo "Enabling state shuffling"
fi

repeat_flag=""
if [ "$state_repeat_times" -gt 0 ]; then
    repeat_flag="--state-repeat-times $state_repeat_times"
    echo "State repeat times: $state_repeat_times"
fi

# Generate Pit file with Python script
echo "Generating Pit file..."
python3 "./tool/forpit.py" \
    "./json/$protocol.json" \
    "./pit/$protocol.xml" \
    --protocol "${layers[@]}" \
    $synthetic_flag \
    $shuffle_flag \
    $repeat_flag || {
    echo "Error: forpit.py processing failed" >&2
    exit 1
}

echo "Processing completed!"
echo "PDML file location: ./pdml/$protocol.pdml"
echo "JSON file location: ./json/$protocol.json"
echo "Pit file location:  ./pit/$protocol.xml"