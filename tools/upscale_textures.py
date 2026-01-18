#!/usr/bin/env python3
"""
AI Texture Upscaler using Real-ESRGAN
Upscales extracted PNG textures 4x using AI
"""

import os
import sys
from pathlib import Path
import subprocess
import shutil

def check_realesrgan():
    """Check if Real-ESRGAN is available"""
    # Try to find realesrgan-ncnn-vulkan binary
    binary_names = ['realesrgan-ncnn-vulkan', 'realesrgan']
    
    for name in binary_names:
        if shutil.which(name):
            return name
    
    print("Error: Real-ESRGAN not found in PATH")
    print("\nPlease install Real-ESRGAN:")
    print("  macOS (Homebrew): brew install realesrgan")
    print("  Or download from: https://github.com/xinntao/Real-ESRGAN/releases")
    return None

def upscale_image(input_path: str, output_path: str, scale: int = 4, model: str = 'realesrgan-x4plus'):
    """Upscale a single image using Real-ESRGAN"""
    
    binary = check_realesrgan()
    if not binary:
        return False
    
    # Create output directory
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    # Run Real-ESRGAN
    cmd = [
        binary,
        '-i', input_path,
        '-o', output_path,
        '-s', str(scale),
        '-n', model
    ]
    
    print(f"Upscaling: {input_path}")
    print(f"  -> {output_path}")
    print(f"  Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print(f"  ✓ Success!")
            return True
        else:
            print(f"  ✗ Failed: {result.stderr}")
            return False
    
    except subprocess.TimeoutExpired:
        print(f"  ✗ Timeout (60s exceeded)")
        return False
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def upscale_directory(input_dir: str, output_dir: str, scale: int = 4):
    """Batch upscale all PNG files in directory"""
    
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    # Find all PNG files
    png_files = list(input_path.rglob('*.png'))
    
    if not png_files:
        print(f"No PNG files found in {input_dir}")
        return
    
    print(f"Found {len(png_files)} PNG files to upscale")
    print(f"Scale factor: {scale}x")
    print(f"Output directory: {output_dir}\n")
    
    success_count = 0
    fail_count = 0
    
    for i, png_file in enumerate(png_files, 1):
        print(f"\n[{i}/{len(png_files)}]")
        
        # Preserve directory structure
        rel_path = png_file.relative_to(input_path)
        output_file = output_path / rel_path
        
        if upscale_image(str(png_file), str(output_file), scale):
            success_count += 1
        else:
            fail_count += 1
    
    print(f"\n{'='*60}")
    print(f"Upscaling complete!")
    print(f"  Success: {success_count}")
    print(f"  Failed: {fail_count}")
    print(f"{'='*60}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python upscale_textures.py <input_dir> <output_dir> [scale]")
        print("\nExample:")
        print("  python upscale_textures.py extracted_textures upscaled_textures 4")
        sys.exit(1)
    
    input_dir = sys.argv[1]
    output_dir = sys.argv[2]
    scale = int(sys.argv[3]) if len(sys.argv) >= 4 else 4
    
    if not os.path.isdir(input_dir):
        print(f"Error: Input directory not found: {input_dir}")
        sys.exit(1)
    
    # Check if Real-ESRGAN is available
    if not check_realesrgan():
        sys.exit(1)
    
    upscale_directory(input_dir, output_dir, scale)

if __name__ == '__main__':
    main()
