#!/usr/bin/env python3
"""
Script to convert system_context.yaml to system_context.json
Preserves all content and structure from the YAML file.
"""

import yaml
import json
from pathlib import Path


def convert_yaml_to_json(yaml_path: str, json_path: str):
    """
    Convert YAML file to JSON format.
    
    Args:
        yaml_path: Path to input YAML file
        json_path: Path to output JSON file
    """
    # Read YAML file
    with open(yaml_path, 'r', encoding='utf-8') as yaml_file:
        data = yaml.safe_load(yaml_file)
    
    # Write JSON file with proper formatting
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(data, json_file, indent=2, ensure_ascii=False)
    
    print(f"✓ Converted {yaml_path} to {json_path}")


if __name__ == "__main__":
    # Define paths relative to script location
    script_dir = Path(__file__).parent
    docs_dir = script_dir.parent
    
    yaml_file = docs_dir / "system_context.yaml"
    json_file = docs_dir / "system_context.json"
    
    # Convert
    convert_yaml_to_json(str(yaml_file), str(json_file))
