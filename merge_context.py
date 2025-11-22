#!/usr/bin/env python3
"""
Script to merge system_context.json, db.json, and use_cases.json into core_context.json
"""

import json
from pathlib import Path
from datetime import datetime


def load_json_file(file_path: Path) -> dict:
    """Load and parse a JSON file."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found - {file_path}")
        raise
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {file_path} - {e}")
        raise


def merge_context_files(
    system_context_path: Path,
    db_path: Path,
    use_cases_path: Path,
    business_rules_path: Path,
    output_path: Path,
) -> None:
    """Merge four context files into a single core_context.json."""

    print("Loading source files...")
    system_context = load_json_file(system_context_path)
    db_context = load_json_file(db_path)
    use_cases = load_json_file(use_cases_path)
    business_rules = load_json_file(business_rules_path)

    print("Merging content...")

    # Build the merged structure
    core_context = {
        "metadata": {
            "generated_at": datetime.now().isoformat(),
            "description": "Comprehensive FUACS system context combining project overview, database schema, and use cases",
            "version": "1.0.0",
            "source_files": [
                "system_context.json",
                "db.json",
                "use_cases.json",
                "business_rules.json",
            ],
        },
        "project_overview": {
            "project_info": system_context.get("system_context", {}).get(
                "project_info", {}
            ),
            "project_overview": system_context.get("system_context", {}).get(
                "project_overview", {}
            ),
            "platform_definitions": system_context.get("system_context", {}).get(
                "platform_definitions", {}
            ),
            "tech_stack": system_context.get("system_context", {}).get(
                "tech_stack", {}
            ),
            "internationalization": system_context.get("system_context", {}).get(
                "internationalization", {}
            ),
        },
        "authentication_and_authorization": {
            "authentication_and_role_mapping": system_context.get(
                "system_context", {}
            ).get("authentication_and_role_mapping", {}),
            "master_permission_catalog": system_context.get("system_context", {}).get(
                "master_permission_catalog", {}
            ),
            "role_definitions": system_context.get("system_context", {}).get(
                "role_definitions", {}
            ),
        },
        "database_schema": {
            "database": db_context.get("database", ""),
            "total_tables": db_context.get("total_tables", 0),
            "timezone_strategy": db_context.get("timezone_strategy", ""),
            "special_features": db_context.get("special_features", []),
            "table_groups": db_context.get("table_groups", {}),
            "tables": db_context.get("tables", {}),
            "foreign_keys_summary": db_context.get("foreign_keys_summary", {}),
        },
        "functional_catalog": {
            "function_catalog": system_context.get("system_context", {}).get(
                "function_catalog", {}
            ),
            "screen_catalog": system_context.get("system_context", {}).get(
                "screen_catalog", {}
            ),
            "api_catalog": system_context.get("system_context", {}).get(
                "api_catalog", {}
            ),
        },
        "use_cases": {
            "total_use_cases": use_cases.get("total_use_cases", 0),
            "use_cases": use_cases.get("use_cases", []),
        },
        "business_rules": {"business_rules": business_rules.get("business_rules", [])},
        "attendance_system": system_context.get("system_context", {}).get(
            "attendance_system", {}
        ),
        "recognition_service": system_context.get("system_context", {}).get(
            "recognition_service", {}
        ),
        "real_time_features": system_context.get("system_context", {}).get(
            "real_time_features", {}
        ),
        "technical_flows": system_context.get("system_context", {}).get(
            "technical_flows", {}
        ),
        "information_flows": system_context.get("system_context", {}).get(
            "information_flows", []
        ),
        "integrations": system_context.get("system_context", {}).get(
            "integrations", {}
        ),
        "data_policies": system_context.get("system_context", {}).get(
            "data_policies", {}
        ),
        "implementation_status": system_context.get("system_context", {}).get(
            "implementation_status", {}
        ),
        "architectural_decisions": system_context.get("system_context", {}).get(
            "architectural_decisions", {}
        ),
    }

    print(f"Writing merged content to {output_path}...")

    # Write with pretty formatting
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(core_context, f, indent=2, ensure_ascii=False)

    print(f"✓ Successfully created {output_path}")
    print(f"  - Total sections: {len(core_context)}")
    print(f"  - Database tables: {core_context['database_schema']['total_tables']}")
    print(f"  - Use cases: {core_context['use_cases']['total_use_cases']}")


def main():
    """Main execution function."""
    # Define file paths
    docs_dir = Path(__file__).parent
    system_context_path = docs_dir / "system_context.json"
    db_path = docs_dir / "database" / "db.json"
    use_cases_path = docs_dir / "requirements" / "use_cases.json"
    business_rules_path = docs_dir / "requirements" / "business_rules.json"
    output_path = docs_dir / "core_context.json"

    print("=" * 60)
    print("FUACS Core Context Merger")
    print("=" * 60)
    print()

    try:
        merge_context_files(
            system_context_path,
            db_path,
            use_cases_path,
            business_rules_path,
            output_path,
        )
        print()
        print("=" * 60)
        print("Merge completed successfully!")
        print("=" * 60)

    except Exception as e:
        print()
        print("=" * 60)
        print(f"Error during merge: {e}")
        print("=" * 60)
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
