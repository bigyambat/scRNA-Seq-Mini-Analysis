#!/usr/bin/env python3
"""
Simple YAML parser for configuration files
Handles basic YAML parsing without external dependencies
"""

import sys
import re
import json

def parse_yaml_simple(yaml_content):
    """Simple YAML parser for basic key-value pairs"""
    config = {}
    section_stack = [(0, config)]
    
    for line_num, line in enumerate(yaml_content.split('\n'), 1):
        original_line = line
        line = line.rstrip()
        if not line or line.strip().startswith('#'):
            continue
            
        # Handle indentation
        indent = len(line) - len(line.lstrip())
        line = line.strip()
        
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()
            
            # Remove quotes
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            
            # Remove inline comments
            if '#' in value:
                value = value.split('#')[0].strip()
            
            # Handle boolean values
            if value.lower() == 'true':
                value = True
            elif value.lower() == 'false':
                value = False
            elif value.isdigit():
                value = int(value)
            elif '.' in value and value.replace('.', '').isdigit() and value.count('.') == 1:
                value = float(value)
            # Keep other values as strings (including version strings like "7.2.0")
            
            # Navigate to correct section based on indentation
            # Remove sections that are at or beyond current indentation
            while len(section_stack) > 1 and section_stack[-1][0] >= indent:
                section_stack.pop()
            
            target_section = section_stack[-1][1]
            
            if value == '':
                # This is a section header
                if key not in target_section:
                    target_section[key] = {}
                section_stack.append((indent, target_section[key]))
            else:
                target_section[key] = value
    
    return config

def get_config_value(config, key_path):
    """Get a value from config using dot notation"""
    keys = key_path.split('.')
    value = config
    for key in keys:
        if isinstance(value, dict) and key in value:
            value = value[key]
        else:
            return None
    return value

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 parse_config.py <config_file> <key_path>")
        sys.exit(1)
    
    config_file = sys.argv[1]
    key_path = sys.argv[2]
    
    try:
        with open(config_file, 'r') as f:
            yaml_content = f.read()
        
        config = parse_yaml_simple(yaml_content)
        value = get_config_value(config, key_path)
        
        if value is not None:
            print(value)
        else:
            print(f"Key '{key_path}' not found", file=sys.stderr)
            sys.exit(1)
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
