#!/usr/bin/env python3
"""
Script to merge all database YAML files into a single db.json file.
Combines all YAML files from docs/database/ into docs/db.json
"""

import yaml
import json
from pathlib import Path
from typing import Dict, Any


def load_yaml_file(file_path: Path) -> Dict[str, Any]:
    """Load a YAML file and return its content."""
    with open(file_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def merge_database_schemas(database_dir: Path) -> Dict[str, Any]:
    """Merge all YAML files from database directory."""
    merged = {"tables": {}, "enums": {}, "indexes": {}, "relationships": {}}
    yaml_files = sorted(database_dir.glob("*.yaml"))

    print(f"Found {len(yaml_files)} YAML files to merge:\n")

    for yaml_file in yaml_files:
        print(f"  Loading {yaml_file.name}...")
        data = load_yaml_file(yaml_file)

        # Deep merge each section
        if "tables" in data:
            merged["tables"].update(data["tables"])
            print(f"    → Added {len(data['tables'])} tables")

        if "enums" in data:
            merged["enums"].update(data["enums"])
            print(f"    → Added {len(data['enums'])} enums")

        if "indexes" in data:
            merged["indexes"].update(data["indexes"])
            print(f"    → Added {len(data['indexes'])} indexes")

        if "relationships" in data:
            merged["relationships"].update(data["relationships"])
            print(f"    → Added {len(data['relationships'])} relationships")

    # Remove empty sections
    merged = {k: v for k, v in merged.items() if v}

    return merged


def main():
    """Main execution function."""
    # Define paths
    script_dir = Path(__file__).parent
    docs_dir = script_dir.parent
    database_dir = docs_dir / "database"
    output_file = docs_dir / "db.json"

    print("=" * 60)
    print("Creating db.json from database YAML files")
    print("=" * 60)
    print()

    # Check if database directory exists
    if not database_dir.exists():
        print(f"Error: {database_dir} not found")
        return

    # Merge all database schemas
    database_schema = merge_database_schemas(database_dir)

    # Write to output file
    print(f"\nWriting to {output_file}...")
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(database_schema, f, indent=2, ensure_ascii=False)

    print("\n" + "=" * 60)
    print(f"✓ Successfully created {output_file}")
    print("=" * 60)

    # Print summary
    print("\nSummary:")
    print(f"  - Tables: {len(database_schema.get('tables', {}))}")
    print(f"  - Enums: {len(database_schema.get('enums', {}))}")
    print(f"  - Indexes: {len(database_schema.get('indexes', {}))}")
    print(f"  - Relationships: {len(database_schema.get('relationships', {}))}")


if __name__ == "__main__":
    main()
