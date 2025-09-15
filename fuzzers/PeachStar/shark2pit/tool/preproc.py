import argparse
import xml.etree.ElementTree as ET
import json

def parse_pdml_to_json(pdml_file, json_file, target_layers):
    """Parse PDML to JSON format"""
    packets = []
    tree = ET.parse(pdml_file)
    root = tree.getroot()
    parent_map = {child: parent for parent in tree.iter() for child in parent}

    def has_parent_with_value(field_elem):
        """Check if field has parent with non-empty value"""
        current = field_elem
        while True:
            parent = parent_map.get(current)
            if parent is None or parent.tag == 'proto':
                break
            if parent.tag == 'field' and parent.get('value'):
                return True  
            current = parent
        return False

    for packet_elem in root.findall('packet'):
        packet = {'number': None, 'fields': []}
        geninfo = packet_elem.find(".//proto[@name='geninfo']")
        if geninfo is not None:
            num_field = geninfo.find(".//field[@name='num']")
            if num_field is not None:
                packet['number'] = num_field.get('show')
        fields = []
        for proto in packet_elem.findall('proto'):
            proto_name = proto.get('name')           
            if proto_name == 'geninfo' or proto_name not in target_layers:
                continue  
            for field in proto.findall('.//field'):
                if has_parent_with_value(field):
                    continue
                size_attr = field.get('size', '0')
                value_attr = field.get('value', '') 
                try:
                    size_val = int(size_attr)
                except ValueError:
                    size_val = 0                 
                if size_val > 0 and not value_attr:
                    continue
                
                field_data = {
                    'name': field.get('name'),
                    'position': int(field.get('pos', 0)),
                    'size': size_val,
                    'value': value_attr,
                    'show': field.get('show', ''),
                    'layer': proto_name
                }
                fields.append(field_data)
    
        packet['fields'] = sorted(fields, key=lambda x: x['position'])
        packets.append(packet)
    
    # Write JSON output
    with open(json_file, 'w') as f:
        json.dump({'packets': packets}, f, indent=2)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PDML file parser")
    parser.add_argument("input_file", help="Input PDML file path")
    parser.add_argument("output_file", help="Output JSON file path")
    parser.add_argument("--layers", nargs='+', type=str, help="Target protocol layers")
    args = parser.parse_args()
    
    parse_pdml_to_json(
        pdml_file=args.input_file,
        json_file=args.output_file,
        target_layers=args.layers
    )