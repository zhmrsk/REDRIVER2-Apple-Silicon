#!/bin/bash

# Bundle all required dylibs into app for portability
# This makes the app self-contained and portable

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_PATH="/Applications/REDRIVER2_RC.app"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
BINARY="$APP_PATH/Contents/MacOS/REDRIVER2"

echo -e "${GREEN}=== Bundling Libraries ===${NC}"

# Create Frameworks directory
mkdir -p "$FRAMEWORKS_DIR"

# List of required libraries (including transitive dependencies)
LIBS=(
    # Direct dependencies
    "/opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib"
    "/opt/homebrew/opt/libsndfile/lib/libsndfile.1.dylib"
    "/opt/homebrew/opt/openal-soft/lib/libopenal.1.dylib"
    "/opt/homebrew/opt/jpeg-turbo/lib/libjpeg.8.dylib"
    # libsndfile dependencies
    "/opt/homebrew/opt/libogg/lib/libogg.0.dylib"
    "/opt/homebrew/opt/libvorbis/lib/libvorbisenc.2.dylib"
    "/opt/homebrew/opt/libvorbis/lib/libvorbis.0.dylib"
    "/opt/homebrew/opt/flac/lib/libFLAC.14.dylib"
    "/opt/homebrew/opt/opus/lib/libopus.0.dylib"
    "/opt/homebrew/opt/mpg123/lib/libmpg123.0.dylib"
    "/opt/homebrew/opt/lame/lib/libmp3lame.0.dylib"
)

# Copy libraries
echo -e "${YELLOW}Copying libraries...${NC}"
for lib in "${LIBS[@]}"; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib")
        echo "  Copying $lib_name"
        cp "$lib" "$FRAMEWORKS_DIR/"
        chmod 644 "$FRAMEWORKS_DIR/$lib_name"
    else
        echo -e "${YELLOW}  Warning: $lib not found${NC}"
    fi
done

# Fix library paths in binary
echo -e "${YELLOW}Fixing library paths in binary...${NC}"
for lib in "${LIBS[@]}"; do
    lib_name=$(basename "$lib")
    if [ -f "$FRAMEWORKS_DIR/$lib_name" ]; then
        echo "  Fixing $lib_name"
        install_name_tool -change "$lib" "@executable_path/../Frameworks/$lib_name" "$BINARY"
    fi
done

# Fix dependencies in libraries themselves
echo -e "${YELLOW}Fixing library dependencies...${NC}"
for lib_file in "$FRAMEWORKS_DIR"/*.dylib; do
    lib_name=$(basename "$lib_file")
    echo "  Processing $lib_name"
    
    # Fix ID
    install_name_tool -id "@executable_path/../Frameworks/$lib_name" "$lib_file"
    
    # Fix dependencies
    for dep_lib in "${LIBS[@]}"; do
        dep_name=$(basename "$dep_lib")
        if otool -L "$lib_file" | grep -q "$dep_lib"; then
            install_name_tool -change "$dep_lib" "@executable_path/../Frameworks/$dep_name" "$lib_file"
        fi
    done
done

# Re-sign everything
echo -e "${YELLOW}Re-signing app...${NC}"
codesign --force --deep --sign - "$APP_PATH"

echo ""
echo -e "${GREEN}=== Bundling Complete ===${NC}"
echo "Libraries bundled:"
ls -lh "$FRAMEWORKS_DIR"

echo ""
echo "Verifying binary dependencies:"
otool -L "$BINARY" | grep -E "@executable_path|@rpath" || echo "All dependencies are system frameworks"
