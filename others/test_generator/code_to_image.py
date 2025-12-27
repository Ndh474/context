"""
Code to Image Generator
Render Java test methods as syntax-highlighted images.

Usage:
    python code_to_image.py --file path/to/TestFile.java --output output_folder
    python code_to_image.py --file path/to/TestFile.java --method "methodName" --output output_folder
"""

import argparse
import re
import os
import textwrap
from pathlib import Path

from pygments import highlight
from pygments.lexers import JavaLexer
from pygments.formatters import ImageFormatter
from pygments.styles import get_style_by_name


def dedent_code(code: str) -> str:
    """
    Remove common leading whitespace from all lines.
    Handles case where first line (@Test) has no indent but rest of code does.
    """
    lines = code.split('\n')
    if len(lines) <= 1:
        return code
    
    # Find minimum indentation from lines AFTER the first line (ignoring empty lines)
    min_indent = float('inf')
    for line in lines[1:]:  # Skip first line
        if line.strip():  # Non-empty line
            indent = len(line) - len(line.lstrip())
            if indent > 0:  # Only consider lines with some indent
                min_indent = min(min_indent, indent)
    
    if min_indent == float('inf') or min_indent == 0:
        return code
    
    # Remove common indentation from all lines except first
    dedented_lines = [lines[0]]  # Keep first line as-is
    for line in lines[1:]:
        if line.strip():
            # Remove min_indent spaces if line has enough
            if len(line) >= min_indent and line[:min_indent].strip() == '':
                dedented_lines.append(line[min_indent:])
            else:
                dedented_lines.append(line.lstrip())
        else:
            dedented_lines.append('')
    
    return '\n'.join(dedented_lines)


def extract_test_methods(java_code: str) -> list[dict]:
    """
    Extract all test methods from Java test file.
    
    Returns list of dicts with:
    - name: method name
    - display_name: @DisplayName value if present
    - code: full method code including annotations
    - nested_class: parent @Nested class name if any
    """
    methods = []
    
    # Pattern to match @Test methods with optional @DisplayName
    # Captures: annotations + method signature + body
    pattern = r'''
        # Capture leading annotations (@Test, @DisplayName, etc.)
        ((?:\s*@\w+(?:\([^)]*\))?\s*)+)
        # Method signature: void methodName()
        (void\s+(\w+)\s*\([^)]*\)\s*\{)
    '''
    
    # Find all @Nested classes first
    nested_pattern = r'@Nested\s+(?:@DisplayName\s*\(\s*"([^"]+)"\s*\)\s+)?class\s+(\w+)\s*\{'
    nested_classes = {}
    
    for match in re.finditer(nested_pattern, java_code):
        display_name = match.group(1) or match.group(2)
        class_name = match.group(2)
        nested_classes[match.start()] = {
            'name': class_name,
            'display_name': display_name,
            'start': match.start()
        }
    
    # Find all @Test methods
    # Pattern handles: @Test @DisplayName("...") void methodName() throws Exception {
    test_pattern = r'(@Test\s+(?:@DisplayName\s*\(\s*"([^"]+)"\s*\)\s+)?)(void\s+(\w+)\s*\([^)]*\)(?:\s+throws\s+\w+(?:\s*,\s*\w+)*)?\s*\{)'
    
    for match in re.finditer(test_pattern, java_code):
        method_start = match.start()
        annotations = match.group(1)
        display_name = match.group(2)
        method_name = match.group(4)
        
        # Find method body by counting braces
        body_start = match.end() - 1  # Position of opening {
        brace_count = 1
        pos = body_start + 1
        
        while brace_count > 0 and pos < len(java_code):
            if java_code[pos] == '{':
                brace_count += 1
            elif java_code[pos] == '}':
                brace_count -= 1
            pos += 1
        
        method_code = java_code[method_start:pos]
        
        # Find which nested class this method belongs to
        nested_class = None
        for nc_start, nc_info in sorted(nested_classes.items(), reverse=True):
            if nc_start < method_start:
                nested_class = nc_info['name']
                break
        
        methods.append({
            'name': method_name,
            'display_name': display_name or method_name,
            'code': dedent_code(method_code.strip()),
            'nested_class': nested_class
        })
    
    return methods


def render_code_to_image(
    code: str,
    output_path: str,
    font_size: int = 14,
    line_numbers: bool = True,
    style: str = 'monokai'
) -> str:
    """
    Render code string to PNG image with syntax highlighting.
    
    Args:
        code: Source code string
        output_path: Output PNG file path
        font_size: Font size for code
        line_numbers: Show line numbers
        style: Pygments style name (monokai, vs, github-dark, etc.)
    
    Returns:
        Output file path
    """
    lexer = JavaLexer()
    
    formatter = ImageFormatter(
        font_name='Consolas',
        font_size=font_size,
        line_numbers=line_numbers,
        style=get_style_by_name(style),
        line_pad=4,
        image_pad=10
    )
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Render to image
    with open(output_path, 'wb') as f:
        highlight(code, lexer, formatter, outfile=f)
    
    return output_path


def generate_images_for_test_file(
    java_file: str,
    output_dir: str,
    method_filter: str = None,
    font_size: int = 14,
    style: str = 'monokai',
    line_numbers: bool = True
) -> list[dict]:
    """
    Generate images for all test methods in a Java test file.
    
    Args:
        java_file: Path to Java test file
        output_dir: Output directory for images
        method_filter: Optional method name to filter (generate only this method)
        font_size: Font size
        style: Pygments style
        line_numbers: Show line numbers
    
    Returns:
        List of generated image info dicts
    """
    with open(java_file, 'r', encoding='utf-8') as f:
        java_code = f.read()
    
    methods = extract_test_methods(java_code)
    
    if method_filter:
        methods = [m for m in methods if m['name'] == method_filter]
    
    results = []
    
    for idx, method in enumerate(methods, 1):
        # Generate filename: nestedClass_methodName.png or methodName.png
        if method['nested_class']:
            filename = f"{method['nested_class']}_{method['name']}.png"
        else:
            filename = f"{method['name']}.png"
        
        output_path = os.path.join(output_dir, filename)
        
        render_code_to_image(
            code=method['code'],
            output_path=output_path,
            font_size=font_size,
            style=style,
            line_numbers=line_numbers
        )
        
        results.append({
            'method_name': method['name'],
            'display_name': method['display_name'],
            'nested_class': method['nested_class'],
            'image_path': output_path
        })
        
        print(f"[{idx}/{len(methods)}] Generated: {filename}")
    
    return results


def main():
    parser = argparse.ArgumentParser(
        description='Generate syntax-highlighted images from Java test methods'
    )
    parser.add_argument('--file', required=True, help='Path to Java test file')
    parser.add_argument('--output', required=True, help='Output directory for images')
    parser.add_argument('--method', help='Generate image for specific method only')
    parser.add_argument('--font-size', type=int, default=14, help='Font size (default: 14)')
    parser.add_argument('--style', default='monokai', help='Pygments style (default: monokai)')
    parser.add_argument('--no-line-numbers', action='store_true', help='Disable line numbers')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.file):
        print(f"[ERROR] File not found: {args.file}")
        return 1
    
    results = generate_images_for_test_file(
        java_file=args.file,
        output_dir=args.output,
        method_filter=args.method,
        font_size=args.font_size,
        style=args.style,
        line_numbers=not args.no_line_numbers
    )
    
    print(f"\n[OK] Generated {len(results)} images in '{args.output}'")
    return 0


if __name__ == '__main__':
    exit(main())
