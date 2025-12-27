"""
Merge multiple DOCX files into one using docxcompose.

Usage:
    python merge_docx.py --files file1.docx file2.docx file3.docx --output merged.docx
    python merge_docx.py --dir test_output --output merged.docx
"""

import argparse
import os
from docx import Document
from docxcompose.composer import Composer


def merge_docx_files(input_files: list[str], output_file: str) -> str:
    """
    Merge multiple DOCX files into one using docxcompose.
    Properly handles images and formatting.
    """
    if not input_files:
        print("[ERROR] No input files provided")
        return None
    
    # Open first document as base
    base_doc = Document(input_files[0])
    composer = Composer(base_doc)
    
    print(f"[1/{len(input_files)}] Base: {os.path.basename(input_files[0])}")
    
    # Append remaining files
    for i, docx_file in enumerate(input_files[1:], 2):
        doc = Document(docx_file)
        composer.append(doc)
        print(f"[{i}/{len(input_files)}] Merged: {os.path.basename(docx_file)}")
    
    # Save merged document
    composer.save(output_file)
    
    print(f"\n[OK] Merged {len(input_files)} files into: {output_file}")
    return output_file


def main():
    parser = argparse.ArgumentParser(
        description='Merge multiple DOCX files into one'
    )
    parser.add_argument('--files', nargs='+', help='List of DOCX files to merge')
    parser.add_argument('--dir', help='Directory containing DOCX files to merge')
    parser.add_argument('--output', required=True, help='Output merged DOCX file')
    
    args = parser.parse_args()
    
    # Get input files
    input_files = []
    
    if args.files:
        input_files = args.files
    elif args.dir:
        if not os.path.isdir(args.dir):
            print(f"[ERROR] Directory not found: {args.dir}")
            return 1
        # Exclude output file and temp files
        output_basename = os.path.basename(args.output) if args.output else None
        input_files = sorted([
            os.path.join(args.dir, f) 
            for f in os.listdir(args.dir) 
            if f.lower().endswith('.docx') 
            and not f.startswith('~')
            and f != output_basename
            and f != 'Unit_Test.docx'
        ])
    else:
        print("[ERROR] Provide either --files or --dir")
        return 1
    
    if not input_files:
        print("[ERROR] No DOCX files found")
        return 1
    
    # Verify all files exist
    for f in input_files:
        if not os.path.exists(f):
            print(f"[ERROR] File not found: {f}")
            return 1
    
    print(f"Merging {len(input_files)} files:")
    for f in input_files:
        print(f"  - {os.path.basename(f)}")
    print()
    
    merge_docx_files(input_files, args.output)
    return 0


if __name__ == '__main__':
    exit(main())
