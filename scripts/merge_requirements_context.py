#!/usr/bin/env python3
"""
Script to merge requirements and system context into a single JSON file.
Combines:
- All JSON files from docs/requirements/
- docs/system_context.json
Into a single requirements_context.json file
"""

import json
from pathlib import Path
from typing import Dict, Any


def load_json_file(file_path: Path) -> Dict[str, Any]:
    """Load a JSON file and return its content."""
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def merge_requirements(requirements_dir: Path) -> Dict[str, Any]:
    """Merge all JSON files from requirements directory."""
    merged = {}
    json_files = sorted(requirements_dir.glob("*.json"))

    for json_file in json_files:
        print(f"  Loading {json_file.name}...")
        data = load_json_file(json_file)
        # Use filename (without extension) as key
        key = json_file.stem
        merged[key] = data

    return merged


def create_requirements_context(docs_dir: Path) -> Dict[str, Any]:
    """Create the requirements context by merging requirements and system context."""
    context = {}

    # 1. Load system context first (to put it at the top)
    print("Loading system context...")
    system_context_file = docs_dir / "system_context.json"
    if system_context_file.exists():
        system_context = load_json_file(system_context_file)
        context.update(system_context)
    else:
        print(f"  Warning: {system_context_file} not found")

    # 2. Merge requirements
    print("\nMerging requirements...")
    requirements_dir = docs_dir / "requirements"
    if requirements_dir.exists():
        context["requirements"] = merge_requirements(requirements_dir)
    else:
        print(f"  Warning: {requirements_dir} not found")

    return context


def main():
    """Main execution function."""
    # Define paths
    script_dir = Path(__file__).parent
    docs_dir = script_dir.parent
    output_file = docs_dir / "requirements_context.json"

    print("=" * 60)
    print("Creating requirements_context.json")
    print("=" * 60)

    # Create merged context
    requirements_context = create_requirements_context(docs_dir)

    # Write to output file
    print(f"\nWriting to {output_file}...")
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(requirements_context, f, indent=2, ensure_ascii=False)

    print("\n" + "=" * 60)
    print(f"✓ Successfully created {output_file}")
    print("=" * 60)

    # Print summary
    print("\nSummary:")
    if "requirements" in requirements_context:
        print(f"  - Requirements: {len(requirements_context['requirements'])} files")
        for key in requirements_context["requirements"].keys():
            print(f"    • {key}")
    if "system_context" in requirements_context:
        print(f"  - System context: included")


if __name__ == "__main__":
    main()
