#!/usr/bin/env python3
"""
RAW Car Texture Extractor for Driver 2
Extracts car textures from CCARS.RAW, HCARS.RAW, VCARS.RAW, RCARS.RAW files
These are 640x256 VRAM dumps in 4-bit indexed color format
"""

import struct
import sys
from pathlib import Path
from PIL import Image
import numpy as np

def extract_raw_vram(raw_path: str, output_path: str, width: int = 640, height: int = 256):
    """
    Extract RAW VRAM texture to PNG
    RAW files are 4-bit indexed color (2 pixels per byte)
    Size: 640x256 = 163,840 pixels = 81,920 bytes (but files are 320KB = 327,680 bytes)
    """
    
    try:
        with open(raw_path, 'rb') as f:
            data = f.read()
        
        print(f"File size: {len(data)} bytes")
        
        # The file is actually 640x512 in 4-bit format
        # 640x512 / 2 = 163,840 bytes... but we have 327,680 bytes
        # So it's likely 640x512 pixels stored as 16-bit values (PSX VRAM format)
        
        # Try interpreting as 16-bit VRAM (1024x256 in 16-bit = 524,288 bytes)
        # Or 512x256 in 16-bit = 262,144 bytes
        # Actual: 327,680 bytes = 640x256 in 16-bit!
        
        width = 640
        height = 256
        
        # Create RGBA image
        image = np.zeros((height, width, 4), dtype=np.uint8)
        
        # Read as 16-bit pixels (PSX 1555 format)
        for y in range(height):
            for x in range(width):
                offset = (y * width + x) * 2
                
                if offset + 1 >= len(data):
                    break
                
                # Read 16-bit pixel
                pixel = struct.unpack_from('<H', data, offset)[0]
                
                # PSX 1555 format: ABBBBBGGGGGRRRRR
                r = (pixel & 0x1F) << 3
                g = ((pixel >> 5) & 0x1F) << 3
                b = ((pixel >> 10) & 0x1F) << 3
                a = 255 if pixel != 0 else 0
                
                image[y, x] = [r, g, b, a]
        
        # Save as PNG
        img = Image.fromarray(image, 'RGBA')
        img.save(output_path)
        
        print(f"✓ Extracted: {output_path}")
        print(f"  Size: {width}x{height}")
        
        return True
    
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_car_textures.py <input.RAW> [output.png]")
        print("\nExample:")
        print("  python extract_car_textures.py data/DRIVER2/DATA/CARS/CCARS.RAW chicago_cars.png")
        sys.exit(1)
    
    input_path = sys.argv[1]
    
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        output_path = input_path.replace('.RAW', '.png')
    
    extract_raw_vram(input_path, output_path)

if __name__ == '__main__':
    main()
