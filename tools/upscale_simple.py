#!/usr/bin/env python3
"""
Simple 4x Texture Upscaler
Uses high-quality Lanczos resampling as fallback if Real-ESRGAN not available
"""

import os
import sys
from pathlib import Path
from PIL import Image

def upscale_image_lanczos(input_path: str, output_path: str, scale: int = 4):
    """Upscale image using Lanczos resampling (high quality)"""
    try:
        img = Image.open(input_path)
        
        new_width = img.width * scale
        new_height = img.height * scale
        
        print(f"Upscaling: {input_path}")
        print(f"  {img.width}x{img.height} -> {new_width}x{new_height}")
        
        # Lanczos is best quality for upscaling
        upscaled = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create output directory
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        
        upscaled.save(output_path)
        print(f"  ✓ Saved: {output_path}")
        
        return True
    
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def upscale_directory(input_dir: str, output_dir: str, scale: int = 4):
    """Batch upscale all PNG files"""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    png_files = list(input_path.rglob('*.png'))
    
    if not png_files:
        print(f"No PNG files found in {input_dir}")
        return
    
    print(f"Found {len(png_files)} PNG files")
    print(f"Scale: {scale}x (Lanczos resampling)")
    print(f"Output: {output_dir}\n")
    
    success = 0
    failed = 0
    
    for i, png_file in enumerate(png_files, 1):
        print(f"\n[{i}/{len(png_files)}]")
        
        rel_path = png_file.relative_to(input_path)
        output_file = output_path / rel_path
        
        if upscale_image_lanczos(str(png_file), str(output_file), scale):
            success += 1
        else:
            failed += 1
    
    print(f"\n{'='*60}")
    print(f"Complete! Success: {success}, Failed: {failed}")
    print(f"{'='*60}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python upscale_simple.py <input> <output> [scale]")
        print("\nExamples:")
        print("  Single file: python upscale_simple.py input.png output.png 4")
        print("  Directory:   python upscale_simple.py extracted/ upscaled/ 4")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    scale = int(sys.argv[3]) if len(sys.argv) >= 4 else 4
    
    if os.path.isdir(input_path):
        upscale_directory(input_path, output_path, scale)
    elif os.path.isfile(input_path):
        upscale_image_lanczos(input_path, output_path, scale)
    else:
        print(f"Error: {input_path} not found")
        sys.exit(1)

if __name__ == '__main__':
    main()
