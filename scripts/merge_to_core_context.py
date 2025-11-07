#!/usr/bin/env python3
"""
Script to merge database schemas, requirements, and system context into core_context.json
Combines:
- All YAML files from docs/database/
- All JSON files from docs/requirements/
- docs/system_context.json
Into a single core_context.json file
"""

import yaml
import json
from pathlib import Path
from typing import Dict, Any


def load_yaml_file(file_path: Path) -> Dict[str, Any]:
    """Load a YAML file and return its content."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def load_json_file(file_path: Path) -> Dict[str, Any]:
    """Load a JSON file and return its content."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def merge_database_schemas(database_dir: Path) -> Dict[str, Any]:
    """Merge all YAML files from database directory."""
    merged = {
        "tables": {},
        "enums": {},
        "indexes": {},
        "relationships": {}
    }
    yaml_files = sorted(database_dir.glob('*.yaml'))
    
    for yaml_file in yaml_files:
        print(f"  Loading {yaml_file.name}...")
        data = load_yaml_file(yaml_file)
        
        # Deep merge each section
        if "tables" in data:
            merged["tables"].update(data["tables"])
        if "enums" in data:
            merged["enums"].update(data["enums"])
        if "indexes" in data:
            merged["indexes"].update(data["indexes"])
        if "relationships" in data:
            merged["relationships"].update(data["relationships"])
    
    return merged


def merge_requirements(requirements_dir: Path) -> Dict[str, Any]:
    """Merge all JSON files from requirements directory."""
    merged = {}
    json_files = sorted(requirements_dir.glob('*.json'))
    
    for json_file in json_files:
        print(f"  Loading {json_file.name}...")
        data = load_json_file(json_file)
        # Use filename (without extension) as key
        key = json_file.stem
        merged[key] = data
    
    return merged


def create_core_context(docs_dir: Path) -> Dict[str, Any]:
    """Create the core context by merging all sources."""
    core_context = {}
    
    # 1. Merge database schemas
    print("Merging database schemas...")
    database_dir = docs_dir / "database"
    if database_dir.exists():
        core_context["database"] = merge_database_schemas(database_dir)
    else:
        print(f"  Warning: {database_dir} not found")
    
    # 2. Merge requirements
    print("\nMerging requirements...")
    requirements_dir = docs_dir / "requirements"
    if requirements_dir.exists():
        core_context["requirements"] = merge_requirements(requirements_dir)
    else:
        print(f"  Warning: {requirements_dir} not found")
    
    # 3. Load system context
    print("\nLoading system context...")
    system_context_file = docs_dir / "system_context.json"
    if system_context_file.exists():
        system_context = load_json_file(system_context_file)
        core_context.update(system_context)
    else:
        print(f"  Warning: {system_context_file} not found")
    
    return core_context


def main():
    """Main execution function."""
    # Define paths
    script_dir = Path(__file__).parent
    docs_dir = script_dir.parent
    output_file = docs_dir / "core_context.json"
    
    print("=" * 60)
    print("Creating core_context.json")
    print("=" * 60)
    
    # Create merged context
    core_context = create_core_context(docs_dir)
    
    # Write to output file
    print(f"\nWriting to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(core_context, f, indent=2, ensure_ascii=False)
    
    print("\n" + "=" * 60)
    print(f"✓ Successfully created {output_file}")
    print("=" * 60)
    
    # Print summary
    print("\nSummary:")
    if "database" in core_context:
        db = core_context['database']
        tables_count = len(db.get('tables', {}))
        enums_count = len(db.get('enums', {}))
        print(f"  - Database: {tables_count} tables, {enums_count} enums")
    if "requirements" in core_context:
        print(f"  - Requirements: {len(core_context['requirements'])} files")
    if "system_context" in core_context:
        print(f"  - System context: included")


if __name__ == "__main__":
    main()
