# -*- coding: utf-8 -*-
"""
Multi-language mission localization script.
Generates language-specific mission files for EN, FR, GE, IT, SP, UA.
"""
import struct
import os
import shutil
from ua_mission_failures_map import FAILURE_MAP

# Translation maps for other languages (empty for now - will use English)
FR_MISSION_MAP = {}
GE_MISSION_MAP = {}
IT_MISSION_MAP = {}
SP_MISSION_MAP = {}

LANGUAGE_MAPS = {
    'EN': {},  # English - no translation needed
    'FR': FR_MISSION_MAP,
    'GE': GE_MISSION_MAP,
    'IT': IT_MISSION_MAP,
    'SP': SP_MISSION_MAP,
    'UA': FAILURE_MAP
}

MISSIONS_BLK = "github_assets/DRIVER2/MISSIONS/MISSIONS.BLK"
OUTPUT_BASE = "localization_assets/MISSIONS"

def process_missions_for_language(lang_code, translation_map):
    """Process all missions for a specific language."""
    
    if not os.path.exists(MISSIONS_BLK):
        print(f"Error: {MISSIONS_BLK} not found.")
        return 0
    
    # Create output directory for this language
    output_dir = os.path.join(OUTPUT_BASE, lang_code)
    os.makedirs(output_dir, exist_ok=True)
    
    with open(MISSIONS_BLK, "rb") as f:
        blk_data = f.read()
    
    missions_processed = 0
    
    # Process all possible mission slots
    for i in range(256):
        offset_loc = i * 4
        if offset_loc + 4 > len(blk_data):
            break
            
        entry = struct.unpack('<I', blk_data[offset_loc:offset_loc+4])[0]
        
        if entry == 0:
            continue
            
        offset = entry & 0x7ffff
        length = entry >> 19
        
        if offset + length > len(blk_data):
            continue
            
        mission_data = bytearray(blk_data[offset : offset+length])
        
        if len(mission_data) < 132:
            continue
        
        # For English, just copy original
        if lang_code == 'EN':
            out_name = f"M{i}.D2MS"
            out_path = os.path.join(output_dir, out_name)
            with open(out_path, "wb") as f:
                f.write(mission_data)
            missions_processed += 1
            continue
        
        # For other languages, apply translations
        patched = 0
        
        for k, v in translation_map.items():
            k_bytes = k.encode('latin1')
            search_start = 0
            
            while True:
                idx = mission_data.find(k_bytes, search_start)
                if idx == -1:
                    break
                
                # Check if null-terminated string
                if idx + len(k_bytes) == len(mission_data) or mission_data[idx + len(k_bytes)] == 0:
                    # Encode translation
                    try:
                        v_encoded = v.encode('cp1251')
                    except:
                        v_encoded = v.encode('latin1', 'ignore')
                    
                    # Pad to original length
                    max_len = len(k_bytes)
                    if len(v_encoded) > max_len:
                        print(f"WARNING [{lang_code}]: translation '{v}' too long for '{k}'")
                        v_encoded = v_encoded[:max_len]
                    
                    final_bytes = v_encoded + b'\0' * (max_len - len(v_encoded))
                    mission_data[idx : idx+max_len] = final_bytes
                    patched += 1
                
                search_start = idx + 1
        
        # Write mission file
        out_name = f"M{i}.D2MS"
        out_path = os.path.join(output_dir, out_name)
        with open(out_path, "wb") as f:
            f.write(mission_data)
        missions_processed += 1
        
        if patched > 0 and lang_code == 'UA':
            print(f"  M{i}.D2MS: Patched {patched} strings")
    
    return missions_processed

def main():
    print("=== Multi-Language Mission Localization ===\n")
    
    # Ensure base output directory exists
    os.makedirs(OUTPUT_BASE, exist_ok=True)
    
    # Process each language
    for lang_code, translation_map in LANGUAGE_MAPS.items():
        print(f"Processing {lang_code}...")
        count = process_missions_for_language(lang_code, translation_map)
        print(f"  Created {count} mission files\n")
    
    print("=== Localization Complete ===")
    print(f"Mission files created in: {OUTPUT_BASE}/")
    print("Languages: EN, FR, GE, IT, SP, UA")

if __name__ == "__main__":
    main()
