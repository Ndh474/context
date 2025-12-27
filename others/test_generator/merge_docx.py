"""
Merge multiple DOCX files into one.

Usage:
    python merge_docx.py --files file1.docx file2.docx file3.docx --output merged.docx
    python merge_docx.py --dir test_output --output merged.docx
"""

import argparse
import os
from docx import Document
from docx.shared import Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH


def merge_docx_files(input_files: list[str], output_file: str) -> str:
    """
    Merge multiple DOCX files into one.
    
    Args:
        input_files: List of DOCX file paths to merge
        output_file: Output merged DOCX file path
    
    Returns:
        Output file path
    """
    if not input_files:
        print("[ERROR] No input files provided")
        return None
    
    # Create new document from first file
    merged_doc = Document(input_files[0])
    
    # Append remaining files
    for i, docx_file in enumerate(input_files[1:], 2):
        # Add page break before each new document
        merged_doc.add_page_break()
        
        # Open source document
        source_doc = Document(docx_file)
        
        # Copy all elements from source to merged
        for element in source_doc.element.body:
            merged_doc.element.body.append(element)
        
        print(f"[{i}/{len(input_files)}] Merged: {os.path.basename(docx_file)}")
    
    # Save merged document
    merged_doc.save(output_file)
    
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
        input_files = sorted([
            os.path.join(args.dir, f) 
            for f in os.listdir(args.dir) 
            if f.lower().endswith('.docx')
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
