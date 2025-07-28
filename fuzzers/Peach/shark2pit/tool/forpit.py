import argparse
import json
import random
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom
import logging
import os
import re
from collections import defaultdict
import math 

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

###synthetic packet count###
def calculate_optimal_synthetic_count(original_count):
    if original_count == 0:
        return 0
    
    base = max(5, int(round(math.sqrt(original_count))))
    
    if original_count < 20:
        return min(3 * original_count, 50)
    elif 20 <= original_count <= 100:
        return min(int(1.5 * base), 50)
    else:
        return min(max(15, int(2 * math.log(original_count))), 50)
###Load configuration file###
def load_config_file(file_path):
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error(f"Config file not found: {file_path}")
        return {}
    except json.JSONDecodeError:
        logger.error(f"Invalid config format: {file_path}")
        return {}
    except Exception as e:
        logger.error(f"Config load error: {e}")
        return {}

def correct_field_value(value, size):
    expected_length = size * 2
    clean_value = re.sub(r'[^0-9a-fA-F]', '', value)
    
    if len(clean_value) > expected_length:
        return clean_value[:expected_length]
    elif len(clean_value) < expected_length:
        return '0' * (expected_length - len(clean_value)) + clean_value
    return clean_value

def generate_unique_field_name(field, protocol):
    """Generate globally unique field identifier"""
    original_name = field.get("name", "")
    layer = field.get("layer", protocol[0])
    size = field["size"]
    
    if not original_name or original_name.strip() == '':
        return f"{layer}_field_{size}"
    return f"{layer}_{original_name}_{size}"

def generate_field_name(field, protocol, name_counter, empty_name_counter):
    """Generate unique XML field name"""
    original_name = field.get("name", "")
    
    if not original_name or original_name.strip() == '':
        new_name = f"{protocol[0]}_{empty_name_counter[0]}"
        empty_name_counter[0] += 1
        return new_name
    
    if original_name in name_counter:
        count = name_counter[original_name] + 1
        new_name = f"{original_name}_{count}"
        name_counter[original_name] = count
    else:
        new_name = original_name
        name_counter[original_name] = 1
    return re.sub(r'[^a-zA-Z0-9_]', '_', new_name)

def create_field_element(block, field, name):
    """Create XML field element"""
    size_bits = field["size"] * 8
    corrected_value = correct_field_value(field["value"], field["size"])
    
    attrs = {
        "name": name,
        "valueType": "hex",
        "value": corrected_value,
        "size": str(size_bits)
    }
    
    if size_bits < 65:
        return SubElement(block, 'Number', **attrs)
    else:
        return SubElement(block, 'Blob', **attrs)

def create_synthetic_packets(templates, value_pool, protocol, count=5):
    if not templates or count <= 0:
        return []
    
    synthetic_packets = []
    for i in range(count):
        template = random.choice(templates)
        synthetic_fields = []
        
        for field in template["fields"]:
            new_field = field.copy()
            unique_name = generate_unique_field_name(field, protocol)
            candidate_values = [v for v in value_pool[unique_name] if v != field["value"]]
            
            if candidate_values:
                new_field["value"] = random.choice(candidate_values)
            else:
                new_field["value"] = field["value"]
            
            synthetic_fields.append(new_field)
        
        synthetic_packets.append({
            'name': f"Synthetic_{template['name']}_{i}",
            'fields': synthetic_fields
        })
    
    return synthetic_packets

def process_packet_fields(packet, protocol):
    """Filter and sort packet fields"""
    if not any(field.get('layer') in protocol for field in packet["fields"]):
        return None
    return [field for field in sorted(packet["fields"], key=lambda x: x["position"]) 
            if field["size"] > 0]

def create_data_model(peach, name, fields, protocol):
    """Create DataModel XML structure"""
    dm = SubElement(peach, 'DataModel', name=name)
    main_block = SubElement(dm, 'Block', name=protocol[0])
    
    name_counter = {}
    empty_name_counter = [1]
    
    for field in fields:
        name = generate_field_name(field, protocol, name_counter, empty_name_counter)
        create_field_element(main_block, field, name)
    
    return dm

def json_to_peach_pit(input_json, output_pit, protocol, synthetic=False):
    """Main conversion function: JSON to Peach PIT"""
    try:
        with open(input_json) as f:
            data = json.load(f)
    except Exception as e:
        logger.error(f"JSON load failed: {e}")
        return
    
    config_path = './tool/shark2pit_config.json'
    pro_config = load_config_file(config_path)
    config = pro_config.get(protocol[0], {
        'default_executable': '',
        'default_arguments': '',
        'default_host': 'localhost',
        'default_port': '80',
        'agent_class': 'Tcp'
    })
    
    peach_attrs = {
        "xmlns": "http://peachfuzzer.com/2012/Peach",
        "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation": "http://peachfuzzer.com/2012/Peach ../peach.xsd"
    }
    peach = Element('Peach', **peach_attrs)
    
    data_models = []
    packet_templates = []
    field_value_pool = defaultdict(list)
    
    packet_num = 1
    for packet in data["packets"]:
        fields = process_packet_fields(packet, protocol)
        if not fields:
            continue
        
        dm_name = f"packet_{packet_num}"
        create_data_model(peach, dm_name, fields, protocol)
        data_models.append(dm_name)
        
        template = {
            "name": dm_name,
            "field_names": [field["name"] for field in fields],
            "fields": fields
        }
        packet_templates.append(template)
        
        for field in fields:
            unique_name = generate_unique_field_name(field, protocol)
            field_value_pool[unique_name].append(field["value"])
        
        packet_num += 1
    
    synthetic_count = 0
    original_count = len(packet_templates)
    
    if synthetic and packet_templates:
        syn_count = calculate_optimal_synthetic_count(original_count)
        logger.info(f"Optimal synthetic packets: {syn_count} (Original: {original_count})")
        
        synthetic_packets = create_synthetic_packets(
            packet_templates, 
            field_value_pool, 
            protocol, 
            count=syn_count
        )
        synthetic_count = len(synthetic_packets)
        
        for packet in synthetic_packets:
            create_data_model(peach, packet['name'], packet['fields'], protocol)
            data_models.append(packet['name'])
    else:
        logger.info("Synthetic packet generation disabled")
    
    if not data_models:
        logger.warning("No valid packets found")
        return
    
    state_model = SubElement(peach, 'StateModel', name=f"{protocol[0]}_StateModel", initialState="test")
    state = SubElement(state_model, 'State', name="test")
    
    for dm_name in data_models:
        action = SubElement(state, 'Action', name=f"Send_{dm_name}", type="output")
        SubElement(action, 'DataModel', ref=dm_name)
    
    agent = SubElement(peach, 'Agent', name="PublisherAgent")
    monitor = SubElement(agent, 'Monitor', {"class": "Process"})
    SubElement(monitor, 'Param', name="Executable", value=config['default_executable'])
    SubElement(monitor, 'Param', name="Arguments", value=config['default_arguments'])
    SubElement(monitor, 'Param', name="RestartOnEachTest", value="false")
    SubElement(monitor, 'Param', name="Faultonearlyexit", value="true")
    
    test = SubElement(peach, 'Test', name="Default")
    SubElement(test, 'Agent', ref="PublisherAgent", platform="linux")
    SubElement(test, 'StateModel', ref=f"{protocol[0]}_StateModel")
    
    publisher = SubElement(test, 'Publisher', {
        'class': config['agent_class'],
        'name': 'client'
    })
    SubElement(publisher, 'Param', name="Host", value=config['default_host'])
    SubElement(publisher, 'Param', name="Port", value=str(config['default_port']))
    
    logger_elem = SubElement(test, 'Logger', {'class': "File"})
    SubElement(logger_elem, 'Param', name="Path", value="logs")
    
    try:
        xml_str = tostring(peach, 'utf-8')
        pretty_xml = minidom.parseString(xml_str).toprettyxml(indent="    ")
        pretty_xml = '\n'.join(line for line in pretty_xml.split('\n') if line.strip())
        
        os.makedirs(os.path.dirname(output_pit), exist_ok=True)
        
        with open(output_pit, 'w') as f:
            f.write(pretty_xml)
        logger.info(f"PIT file generated: {output_pit}")
        logger.info(f"Original packets: {original_count}")
        logger.info(f"Synthetic packets: {synthetic_count}")
    except Exception as e:
        logger.error(f"XML generation error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate Peach PIT files",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("input_json", help="Input JSON path")
    parser.add_argument("output_pit", help="Output XML path")
    parser.add_argument("--protocol", "-p", nargs='+', type=str, 
                        required=True, help="Protocol type (e.g., mqtt modbus)")
    parser.add_argument("--synthetic", action="store_true",
                        help="Enable synthetic packet generation")
    
    args = parser.parse_args()
    
    json_to_peach_pit(
        input_json=args.input_json,
        output_pit=args.output_pit,
        protocol=args.protocol,
        synthetic=args.synthetic 
    )