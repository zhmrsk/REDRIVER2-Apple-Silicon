import struct
import os
from ua_mission_failures_map import FAILURE_MAP

MISSIONS_BLK = "src_rebuild/bin/Release_dev/REDRIVER2.app/Contents/Resources/data/DRIVER2/MISSIONS/MISSIONS.BLK"
# OUTPUT_DIR = "github_assets/DRIVER2/MISSIONS"
OUTPUT_DIR = "src_rebuild/bin/Release_dev/REDRIVER2.app/Contents/Resources/data/DRIVER2/MISSIONS"

def process_missions():
    if not os.path.exists(MISSIONS_BLK):
        print(f"Error: {MISSIONS_BLK} not found.")
        return

    # Ensure output dir
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    with open(MISSIONS_BLK, "rb") as f:
        blk_data = f.read()

    print(f"BLK Size: {len(blk_data)}")
    
    # Process ALL possible mission slots
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
            
        # Dynamic header size
        header_size = struct.unpack('<I', mission_data[4:8])[0]
        # Scan from safe start
        absolute_strings_start = 0 
        
        if i == 70:
            print(f"DEBUG: Processing M70. Header size: {header_size}. Len: {len(mission_data)}")

        # Scan strings in this mission
        # We need to find matching strings and replace them IN PLACE
        # Logic: find occurrence of bytes matching the key string
        
        # Patch count
        patched = 0
        
        for k, v in FAILURE_MAP.items():
            # Encode key to latin1 bytes
            k_bytes = k.encode('latin1')
            
            # find all occurrences
            search_start = absolute_strings_start
            
            while True:
                idx = mission_data.find(k_bytes, search_start)
                if idx == -1:
                    break
                
                # Check if it matches length and is null terminated or we just replace common prefix?
                # We should replace exact matches preferably.
                # Check if byte after is 0?
                if idx + len(k_bytes) == len(mission_data) or mission_data[idx + len(k_bytes)] == 0:
                    # Valid string match
                    # Encode value
                    try:
                        v_encoded = v.encode('cp1251')
                    except:
                        v_encoded = v.encode('latin1', 'ignore')
                        
                    # Pad
                    max_len = len(k_bytes)
                    if len(v_encoded) > max_len:
                        print(f"WARNING: translation '{v}' too long for '{k}'")
                        v_encoded = v_encoded[:max_len]
                    
                    final_bytes = v_encoded + b'\0' * (max_len - len(v_encoded))
                    
                    # Patch
                    mission_data[idx : idx+max_len] = final_bytes
                    patched += 1
                else:
                    if i == 70:
                        print(f"DEBUG: Found '{k}' at {idx} but next byte is {mission_data[idx+len(k_bytes)]}")

                search_start = idx + 1
                
        if patched > 0:
            out_name = f"M{i}.D2MS"
            out_path = os.path.join(OUTPUT_DIR, out_name)
            # FORCE WRITE to APP BUNDLE directly
            with open(out_path, "wb") as f:
                f.write(mission_data)
            print(f"Extracted {out_name} (Patched {patched} strings)")

def audit_missing():
    print("\n--- MISSING MISSION STRINGS ---")
    if not os.path.exists(MISSIONS_BLK): return

    with open(MISSIONS_BLK, "rb") as f:
        blk_data = f.read()
        
    missing = set()
    
    for i in range(256):
        offset_loc = i * 4
        if offset_loc + 4 > len(blk_data): break
        entry = struct.unpack('<I', blk_data[offset_loc:offset_loc+4])[0]
        if entry == 0: continue
        offset = entry & 0x7ffff
        length = entry >> 19
        
        if offset + length > len(blk_data): continue
        mission_data = blk_data[offset : offset+length]
        if len(mission_data) < 132: continue
        
        # Simple string scan
        current_str = b""
        for byte in mission_data:
            if byte == 0:
                if len(current_str) > 0:
                    try:
                        s = current_str.decode('latin1')
                        if len(s) > 3 and any(c.isalpha() for c in s):
                             if s not in FAILURE_MAP and "D2MS" not in s:
                                 missing.add(s)
                    except: pass
                current_str = b""
            else:
                if 32 <= byte <= 126:
                    current_str += bytes([byte])
                else:
                    current_str = b"" # Reset on binary garbage

    for s in sorted(list(missing)):
        print(f'"{s}": "",')

if __name__ == "__main__":
    # audit_missing() # disable audit for now
    process_missions()
