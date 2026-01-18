import os
import struct

from ua_subtitles_map import SUBTITLE_MAP

BASE_ASSETS_DIR = "github_assets/DRIVER2"
TARGET_BASE_DIR = "src_rebuild/bin/Release_dev/REDRIVER2.app/Contents/Resources/data/DRIVER2"

# Map relative paths to scan
SCAN_DIRS = ["XA", "FMV/0", "FMV/1", "FMV/9"]

def patch_file(rel_path):
    src_path = os.path.join(BASE_ASSETS_DIR, rel_path)
    
    if not os.path.exists(src_path):
        # skipping missing file
        return

    with open(src_path, "rb") as f:
        data = f.read()
    
    if len(data) < 4:
        return
        
    num_subtitles = struct.unpack('<i', data[:4])[0]
    
    # We will reconstruct the file data
    new_data = bytearray(data[:4])
    offset = 4
    SUB_SIZE = 56
    
    patched = 0
    
    for i in range(num_subtitles):
        if offset + SUB_SIZE > len(data):
            break
            
        chunk = data[offset : offset+SUB_SIZE]
        text_bytes = chunk[:48]
        start, end = struct.unpack('<ii', chunk[48:])
        
        try:
            text = text_bytes.split(b'\0')[0].decode('latin1')
        except:
            text = ""
            
        # Translate
        new_text = SUBTITLE_MAP.get(text, text)
        if new_text != text:
            patched += 1
        
        # Encode to CP1251
        try:
            encoded_text = new_text.encode('cp1251')
        except:
            encoded_text = new_text.encode('latin1', errors='ignore')
            
        # Pad with 0
        if len(encoded_text) > 47:
            encoded_text = encoded_text[:47]
        
        final_bytes = encoded_text + b'\0' * (48 - len(encoded_text))
        
        new_data.extend(final_bytes)
        new_data.extend(struct.pack('<ii', start, end))
        
        offset += SUB_SIZE
        
    # Construct output path: TARGET_BASE_DIR / <dir> / UA_<filename>
    dirname, filename = os.path.split(rel_path)
    
    # We want UA_ prefix on the filename
    target_rel_path = os.path.join(dirname, "UA_" + filename)
    target_full_path = os.path.join(TARGET_BASE_DIR, target_rel_path)
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(target_full_path), exist_ok=True)

    with open(target_full_path, "wb") as f:
        f.write(new_data)
        
    if patched > 0:
        print(f"Generated {target_rel_path} (Patched {patched} strings)")

def audit_missing():
    print("\n--- MISSING SBN STRINGS ---")
    missing = set()
    
    for d in SCAN_DIRS:
        scan_dir = os.path.join(BASE_ASSETS_DIR, d)
        if not os.path.exists(scan_dir): continue
        
        for fname in os.listdir(scan_dir):
            if not fname.endswith('.SBN'): continue
            
            path = os.path.join(scan_dir, fname)
            with open(path, "rb") as f:
                data = f.read()
                
            if len(data) < 4: continue
            num_subtitles = struct.unpack('<i', data[:4])[0]
            offset = 4
            SUB_SIZE = 56
            
            for i in range(num_subtitles):
                if offset + SUB_SIZE > len(data): break
                chunk = data[offset : offset+SUB_SIZE]
                text_bytes = chunk[:48]
                try:
                    text = text_bytes.split(b'\0')[0].decode('latin1')
                except:
                    text = ""
                
                if text and text not in SUBTITLE_MAP:
                    missing.add(text)
                offset += SUB_SIZE
            
    for s in sorted(list(missing)):
        print(f'"{s}": "",')

def process_all():
    print(f"Scanning directories: {SCAN_DIRS}")
    count = 0
    for d in SCAN_DIRS:
        scan_dir = os.path.join(BASE_ASSETS_DIR, d)
        if not os.path.exists(scan_dir):
            print(f"Warning: {scan_dir} not found")
            continue
            
        for fname in sorted(os.listdir(scan_dir)):
            if fname.endswith('.SBN'):
                rel_path = os.path.join(d, fname)
                patch_file(rel_path)
                count += 1
    print(f"Processed {count} SBN files.")

if __name__ == "__main__":
    # audit_missing() # Run audit if needed to dump missing strings
    process_all()
