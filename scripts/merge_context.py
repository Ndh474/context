#!/usr/bin/env python3
"""
FUACS Context Merger
Merges all YAML documentation files into a single comprehensive context file.
"""

import yaml
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List
import sys


class ContextMerger:
    def __init__(self, root_dir: str = "."):
        self.root_dir = Path(root_dir)
        self.merged_data = {
            "fuacs_complete_context": {
                "metadata": {
                    "generated_at": datetime.now().isoformat(),
                    "version": "1.0",
                    "description": "Complete FUACS system context - merged from all documentation files"
                }
            }
        }
    
    def load_yaml_file(self, file_path: Path) -> Dict[str, Any]:
        """Load and parse a YAML file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
                return data if data else {}
        except Exception as e:
            print(f"Error loading {file_path}: {e}")
            return {}
    
    def merge_folder(self, folder_name: str, namespace: str) -> Dict[str, Any]:
        """Merge all YAML files in a folder into a single dictionary."""
        folder_path = self.root_dir / folder_name
        
        if not folder_path.exists():
            print(f"Warning: Folder {folder_path} does not exist")
            return {}
        
        merged = {}
        yaml_files = sorted(folder_path.glob("*.yaml"))
        
        for yaml_file in yaml_files:
            print(f"Processing: {yaml_file}")
            data = self.load_yaml_file(yaml_file)
            
            # Merge data
            if data:
                # Get the root key from the file (e.g., 'tech_stack_and_architecture')
                for key, value in data.items():
                    if key in merged:
                        # If key exists, merge dictionaries
                        if isinstance(merged[key], dict) and isinstance(value, dict):
                            merged[key].update(value)
                        else:
                            merged[key] = value
                    else:
                        merged[key] = value
        
        return merged
    
    def merge_system_context(self) -> Dict[str, Any]:
        """Load the main system_context.yaml file."""
        system_context_path = self.root_dir / "system_context.yaml"
        
        if system_context_path.exists():
            print(f"Processing: {system_context_path}")
            data = self.load_yaml_file(system_context_path)
            
            return data
        else:
            print(f"Warning: {system_context_path} does not exist")
            return {}
    
    def merge_all(self) -> Dict[str, Any]:
        """Merge all documentation files."""
        print("=" * 60)
        print("FUACS Context Merger")
        print("=" * 60)
        
        # 1. Merge system_context.yaml
        print("\n[1/5] Merging system_context.yaml...")
        system_context = self.merge_system_context()
        if system_context:
            self.merged_data["fuacs_complete_context"]["system_context"] = system_context.get("system_context", system_context)
        
        # 2. Merge database folder
        print("\n[2/5] Merging database/ folder...")
        database_data = self.merge_folder("database", "database")
        if database_data:
            self.merged_data["fuacs_complete_context"]["database"] = database_data
        
        # 3. Merge backend folder
        print("\n[3/5] Merging backend/ folder...")
        backend_data = self.merge_folder("backend", "backend")
        if backend_data:
            self.merged_data["fuacs_complete_context"]["backend"] = backend_data
        
        # 4. Merge frontend folder
        print("\n[4/5] Merging frontend/ folder...")
        frontend_data = self.merge_folder("frontend", "frontend")
        if frontend_data:
            self.merged_data["fuacs_complete_context"]["frontend"] = frontend_data
        
        # 5. Merge requirements folder
        print("\n[5/5] Merging requirements/ folder...")
        requirements_data = self.merge_folder("requirements", "requirements")
        if requirements_data:
            self.merged_data["fuacs_complete_context"]["requirements"] = requirements_data
        
        return self.merged_data
    
    def save_merged_context(self, output_path: str = "final_context.yaml"):
        """Save the merged context to a YAML file."""
        output_file = Path(output_path)
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                yaml.dump(
                    self.merged_data,
                    f,
                    default_flow_style=False,
                    allow_unicode=True,
                    sort_keys=False,
                    width=120,
                    indent=2
                )
            
            print("\n" + "=" * 60)
            print(f"✓ Successfully merged context to: {output_file}")
            print("=" * 60)
            
            return True
        except Exception as e:
            print(f"\n✗ Error saving merged context: {e}")
            return False


def main():
    """Main entry point."""
    try:
        merger = ContextMerger(root_dir=".")
        merger.merge_all()
        success = merger.save_merged_context("final_context.yaml")
        
        sys.exit(0 if success else 1)
    
    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
