#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
D2MS Mission Text Editor
Extracts text from .D2MS files, allows editing, and re-injects back
"""
import sys
import os

def extract_text_from_d2ms(d2ms_path):
    """Extract text strings from .D2MS file"""
    with open(d2ms_path, 'rb') as f:
        data = f.read()
    
    # Find null-terminated strings (assuming CP1251 encoding)
    # Text starts after binary data, usually contains Cyrillic
    strings = []
    current_string = bytearray()
    
    # Start searching from a reasonable offset (skip binary header/data)
    start_offset = 100  # Adjust if needed
    
    for i in range(start_offset, len(data)):
        byte = data[i]
        
        if byte == 0:  # Null terminator
            if len(current_string) > 0:
                try:
                    # Try to decode as CP1251
                    decoded = current_string.decode('cp1251')
                    # Filter out garbage (only keep printable text)
                    if decoded.strip() and any(c.isalpha() for c in decoded):
                        strings.append((i - len(current_string), decoded))
                except:
                    pass
                current_string = bytearray()
        else:
            current_string.append(byte)
    
    return strings

def list_mission_strings(mission_dir):
    """List all mission files and their strings"""
    print(f"\n📋 Mission Text Editor\n{'='*50}")
    
    d2ms_files = sorted([f for f in os.listdir(mission_dir) if f.endswith('.D2MS')])
    
    for mission_file in d2ms_files:
        filepath = os.path.join(mission_dir, mission_file)
        print(f"\n🎯 {mission_file}")
        print("-" * 50)
        
        strings = extract_text_from_d2ms(filepath)
        
        if strings:
            for idx, (offset, text) in enumerate(strings, 1):
                print(f"  [{idx}] {text}")
        else:
            print("  (no text found)")

def extract_to_txt(d2ms_path, txt_path):
    """Extract strings to UTF-8 text file for editing"""
    strings = extract_text_from_d2ms(d2ms_path)
    
    with open(txt_path, 'w', encoding='utf-8') as f:
        f.write(f"# Mission: {os.path.basename(d2ms_path)}\n")
        f.write("# Edit the lines below, one per line\n")
        f.write("# Lines starting with # are ignored\n")
        f.write("#" * 50 + "\n\n")
        
        for _, text in strings:
            f.write(text + "\n")
    
    print(f"✅ Extracted {len(strings)} strings to: {txt_path}")
    print("   Edit this file, then use --inject to put changes back")

def inject_from_txt(txt_path, d2ms_path, output_path=None):
    """Inject edited strings back into .D2MS file"""
    # Read edited strings
    with open(txt_path, 'r', encoding='utf-8') as f:
        edited_strings = [line.strip() for line in f 
                         if line.strip() and not line.startswith('#')]
    
    # Read original mission file
    with open(d2ms_path, 'rb') as f:
        data = bytearray(f.read())
    
    # Extract original strings with offsets
    original_strings = extract_text_from_d2ms(d2ms_path)
    
    if len(edited_strings) != len(original_strings):
        print(f"⚠️  Warning: String count mismatch!")
        print(f"   Original: {len(original_strings)}, Edited: {len(edited_strings)}")
        print("   Using min count...")
    
    # Replace strings in binary data
    for i in range(min(len(edited_strings), len(original_strings))):
        offset, original_text = original_strings[i]
        new_text = edited_strings[i]
        
        # Encode to CP1251
        new_bytes = new_text.encode('cp1251') + b'\x00'
        original_bytes = original_text.encode('cp1251') + b'\x00'
        
        # Replace in binary data
        # Find exact position and replace
        data[offset:offset+len(original_bytes)] = new_bytes[:len(original_bytes)]
    
    # Write to output
    if not output_path:
        output_path = d2ms_path
    
    with open(output_path, 'wb') as f:
        f.write(data)
    
    print(f"✅ Injected {min(len(edited_strings), len(original_strings))} strings")
    print(f"   Output: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("""
Usage:
  List all mission strings:
    python d2ms_editor.py --list <mission_dir>
  
  Extract mission to editable file:
    python d2ms_editor.py --extract <mission.D2MS> <output.txt>
  
  Inject edited strings back:
    python d2ms_editor.py --inject <edited.txt> <mission.D2MS> [output.D2MS]

Examples:
  python d2ms_editor.py --list data/DRIVER2/MISSIONS/UA
  python d2ms_editor.py --extract data/DRIVER2/MISSIONS/UA/M1.D2MS M1_edit.txt
  python d2ms_editor.py --inject M1_edit.txt data/DRIVER2/MISSIONS/UA/M1.D2MS
        """)
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "--list":
        mission_dir = sys.argv[2]
        list_mission_strings(mission_dir)
    
    elif command == "--extract":
        d2ms_path = sys.argv[2]
        txt_path = sys.argv[3]
        extract_to_txt(d2ms_path, txt_path)
    
    elif command == "--inject":
        txt_path = sys.argv[2]
        d2ms_path = sys.argv[3]
        output_path = sys.argv[4] if len(sys.argv) > 4 else None
        inject_from_txt(txt_path, d2ms_path, output_path)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
