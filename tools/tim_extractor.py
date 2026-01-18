#!/usr/bin/env python3
"""
TIM Texture Extractor for Driver 2
Extracts PlayStation TIM textures and converts them to PNG format
"""

import struct
import os
import sys
from pathlib import Path
from typing import Tuple, Optional
import json

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Error: Required packages not installed")
    print("Please run: pip install Pillow numpy")
    sys.exit(1)


class TIMExtractor:
    """Extract and convert PlayStation TIM texture files"""
    
    # TIM format constants
    TIM_MAGIC = 0x10
    TIM_FLAG_CLUT = 0x08  # Has color lookup table (palette)
    
    def __init__(self, tim_path: str):
        self.tim_path = tim_path
        self.data = None
        self.clut_data = None
        self.pixel_data = None
        self.width = 0
        self.height = 0
        self.clut_width = 0
        self.clut_height = 0
        self.bpp = 0  # Bits per pixel
        
    def load(self) -> bool:
        """Load TIM file into memory"""
        try:
            with open(self.tim_path, 'rb') as f:
                self.data = f.read()
            return True
        except Exception as e:
            print(f"Error loading {self.tim_path}: {e}")
            return False
    
    def parse_header(self) -> bool:
        """Parse TIM file header"""
        if len(self.data) < 8:
            print("File too small to be a valid TIM")
            return False
        
        # Read TIMHDR
        magic, flags = struct.unpack_from('<II', self.data, 0)
        
        if magic != self.TIM_MAGIC:
            print(f"Invalid TIM magic: 0x{magic:08X} (expected 0x{self.TIM_MAGIC:08X})")
            return False
        
        # Determine bits per pixel from flags
        pmode = flags & 0x07
        if pmode == 0:
            self.bpp = 4  # 4-bit CLUT
        elif pmode == 1:
            self.bpp = 8  # 8-bit CLUT
        elif pmode == 2:
            self.bpp = 16  # 16-bit direct color
        elif pmode == 3:
            self.bpp = 24  # 24-bit direct color
        else:
            print(f"Unknown pixel mode: {pmode}")
            return False
        
        has_clut = (flags & self.TIM_FLAG_CLUT) != 0
        
        offset = 8
        
        # Parse CLUT if present
        if has_clut:
            if len(self.data) < offset + 12:
                print("File too small for CLUT header")
                return False
            
            clut_len, clut_x, clut_y, clut_w, clut_h = struct.unpack_from('<IhhHH', self.data, offset)
            self.clut_width = clut_w
            self.clut_height = clut_h
            
            offset += 12
            clut_data_size = clut_len - 12
            
            if len(self.data) < offset + clut_data_size:
                print("File too small for CLUT data")
                return False
            
            self.clut_data = self.data[offset:offset + clut_data_size]
            offset += clut_data_size
        
        # Parse pixel data
        if len(self.data) < offset + 12:
            print("File too small for pixel data header")
            return False
        
        pix_len, pix_x, pix_y, pix_w, pix_h = struct.unpack_from('<IhhHH', self.data, offset)
        
        # Width is in 16-bit units for indexed modes
        if self.bpp == 4:
            self.width = pix_w * 4  # 4 pixels per 16-bit word
        elif self.bpp == 8:
            self.width = pix_w * 2  # 2 pixels per 16-bit word
        else:
            self.width = pix_w
        
        self.height = pix_h
        
        offset += 12
        pix_data_size = pix_len - 12
        
        if len(self.data) < offset + pix_data_size:
            print("File too small for pixel data")
            return False
        
        self.pixel_data = self.data[offset:offset + pix_data_size]
        
        return True
    
    def decode_clut(self) -> np.ndarray:
        """Decode CLUT (palette) to RGBA"""
        if not self.clut_data:
            return None
        
        num_colors = len(self.clut_data) // 2
        palette = np.zeros((num_colors, 4), dtype=np.uint8)
        
        for i in range(num_colors):
            # Read 16-bit color (PSX 1555 format)
            color16 = struct.unpack_from('<H', self.clut_data, i * 2)[0]
            
            # Extract RGB components (5 bits each)
            r = (color16 & 0x1F) << 3
            g = ((color16 >> 5) & 0x1F) << 3
            b = ((color16 >> 10) & 0x1F) << 3
            
            # STP bit (semi-transparency)
            stp = (color16 >> 15) & 1
            
            # Alpha: 0 for black (0,0,0), 255 otherwise
            a = 0 if color16 == 0 else 255
            
            palette[i] = [r, g, b, a]
        
        return palette
    
    def decode_pixels(self, palette: np.ndarray) -> Optional[np.ndarray]:
        """Decode indexed pixel data using palette"""
        if not self.pixel_data or palette is None:
            return None
        
        image = np.zeros((self.height, self.width, 4), dtype=np.uint8)
        
        if self.bpp == 4:
            # 4-bit indexed
            for y in range(self.height):
                for x in range(0, self.width, 4):
                    byte_offset = (y * self.width + x) // 4
                    if byte_offset * 2 + 1 >= len(self.pixel_data):
                        break
                    
                    word = struct.unpack_from('<H', self.pixel_data, byte_offset * 2)[0]
                    
                    # Extract 4 pixels (4 bits each)
                    for i in range(4):
                        if x + i < self.width:
                            idx = (word >> (i * 4)) & 0x0F
                            if idx < len(palette):
                                image[y, x + i] = palette[idx]
        
        elif self.bpp == 8:
            # 8-bit indexed
            for y in range(self.height):
                for x in range(0, self.width, 2):
                    byte_offset = (y * self.width + x) // 2
                    if byte_offset * 2 + 1 >= len(self.pixel_data):
                        break
                    
                    word = struct.unpack_from('<H', self.pixel_data, byte_offset * 2)[0]
                    
                    # Extract 2 pixels (8 bits each)
                    idx0 = word & 0xFF
                    idx1 = (word >> 8) & 0xFF
                    
                    if x < self.width and idx0 < len(palette):
                        image[y, x] = palette[idx0]
                    if x + 1 < self.width and idx1 < len(palette):
                        image[y, x + 1] = palette[idx1]
        
        return image
    
    def extract_to_png(self, output_path: str) -> bool:
        """Extract TIM and save as PNG"""
        if not self.load():
            return False
        
        if not self.parse_header():
            return False
        
        print(f"TIM Info: {self.width}x{self.height}, {self.bpp}bpp")
        
        if self.bpp in [4, 8]:
            # Indexed color mode
            palette = self.decode_clut()
            if palette is None:
                print("Failed to decode palette")
                return False
            
            print(f"Palette: {len(palette)} colors")
            
            image_data = self.decode_pixels(palette)
            if image_data is None:
                print("Failed to decode pixels")
                return False
        else:
            print(f"Direct color mode ({self.bpp}bpp) not yet implemented")
            return False
        
        # Save as PNG
        img = Image.fromarray(image_data, 'RGBA')
        img.save(output_path)
        
        print(f"Saved: {output_path}")
        
        # Save metadata
        metadata = {
            'source': str(self.tim_path),
            'width': self.width,
            'height': self.height,
            'bpp': self.bpp,
            'palette_colors': len(palette) if palette is not None else 0
        }
        
        meta_path = output_path.replace('.png', '.json')
        with open(meta_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python tim_extractor.py <input.TIM> [output.png]")
        print("   or: python tim_extractor.py <directory>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    
    if os.path.isdir(input_path):
        # Batch mode: process all TIM files in directory
        tim_files = list(Path(input_path).rglob('*.TIM'))
        print(f"Found {len(tim_files)} TIM files")
        
        output_dir = Path(input_path) / 'extracted_textures'
        output_dir.mkdir(exist_ok=True)
        
        for tim_file in tim_files:
            print(f"\nProcessing: {tim_file}")
            
            # Preserve directory structure
            rel_path = tim_file.relative_to(input_path)
            output_path = output_dir / rel_path.with_suffix('.png')
            output_path.parent.mkdir(parents=True, exist_ok=True)
            
            extractor = TIMExtractor(str(tim_file))
            extractor.extract_to_png(str(output_path))
    
    else:
        # Single file mode
        if len(sys.argv) >= 3:
            output_path = sys.argv[2]
        else:
            output_path = input_path.replace('.TIM', '.png')
        
        extractor = TIMExtractor(input_path)
        if extractor.extract_to_png(output_path):
            print("Extraction successful!")
        else:
            print("Extraction failed!")
            sys.exit(1)


if __name__ == '__main__':
    main()
