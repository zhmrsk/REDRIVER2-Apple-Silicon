#!/bin/bash
set -e

echo "Building clean release of Driver 2..."

# Paths - automatically detect project root from script location
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJECT_ROOT/src_rebuild"
BUILD_DIR="$SRC_DIR/bin/Release_dev"
APP_NAME="REDRIVER2.app"
APP_PATH="$BUILD_DIR/$APP_NAME"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
EXECUTABLE="$APP_PATH/Contents/MacOS/REDRIVER2"

cd "$SRC_DIR"

# Step 1: Clean old builds
echo "Cleaning old builds..."
rm -rf "$BUILD_DIR/$APP_NAME"
rm -rf "project_gmake_macosx"

# Step 2: Generate project with premake5
echo "Generating project files..."
premake5 gmake

# Step 3: Build Release_dev for arm64
echo "Building Release_dev configuration for arm64..."
cd project_gmake_macosx
make config=release_dev_arm64 -j$(sysctl -n hw.ncpu)

# Step 4: Verify app was created
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not created at $APP_PATH"
    exit 1
fi

echo "App bundle created successfully"

# Step 5: Create Frameworks directory
echo "Creating Frameworks directory..."
mkdir -p "$FRAMEWORKS_DIR"

# Step 6: Bundle libraries
echo "Bundling dynamic libraries..."

# Function to copy library and fix paths
bundle_library() {
    local lib_name=$1
    local lib_path="/opt/homebrew/lib/$lib_name"
    
    if [ -f "$lib_path" ]; then
        echo "  Copying $lib_name..."
        cp "$lib_path" "$FRAMEWORKS_DIR/"
        chmod +w "$FRAMEWORKS_DIR/$lib_name"
        
        # Fix the library's own ID
        install_name_tool -id "@executable_path/../Frameworks/$lib_name" "$FRAMEWORKS_DIR/$lib_name"
        
        # Fix dependencies in the library
        otool -L "$FRAMEWORKS_DIR/$lib_name" | grep -E "/opt/homebrew" | awk '{print $1}' | while read dep; do
            dep_name=$(basename "$dep")
            if [ -f "/opt/homebrew/lib/$dep_name" ]; then
                install_name_tool -change "$dep" "@executable_path/../Frameworks/$dep_name" "$FRAMEWORKS_DIR/$lib_name"
            fi
        done
    fi
}

# Bundle main libraries
bundle_library "libSDL2-2.0.0.dylib"
bundle_library "libsndfile.1.dylib"
bundle_library "libjpeg.8.dylib"

# Copy libopenal from opt directory
OPENAL_PATH="/opt/homebrew/opt/openal-soft/lib/libopenal.1.dylib"
if [ -f "$OPENAL_PATH" ]; then
    echo "  Copying libopenal.1.dylib..."
    cp "$OPENAL_PATH" "$FRAMEWORKS_DIR/"
    chmod +w "$FRAMEWORKS_DIR/libopenal.1.dylib"
    install_name_tool -id "@executable_path/../Frameworks/libopenal.1.dylib" "$FRAMEWORKS_DIR/libopenal.1.dylib"
fi

# Bundle transitive dependencies
bundle_library "libogg.0.dylib"
bundle_library "libvorbis.0.dylib"
bundle_library "libvorbisenc.2.dylib"
bundle_library "libFLAC.14.dylib"
bundle_library "libopus.0.dylib"
bundle_library "libmpg123.0.dylib"
bundle_library "libmp3lame.0.dylib"

# Step 7: Fix executable paths
echo "🔧 Fixing executable library paths..."
install_name_tool -change "/opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib" "@executable_path/../Frameworks/libSDL2-2.0.0.dylib" "$EXECUTABLE" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/libsndfile/lib/libsndfile.1.dylib" "@executable_path/../Frameworks/libsndfile.1.dylib" "$EXECUTABLE" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/openal-soft/lib/libopenal.1.dylib" "@executable_path/../Frameworks/libopenal.1.dylib" "$EXECUTABLE" 2>/dev/null || true
install_name_tool -change "/opt/homebrew/opt/jpeg-turbo/lib/libjpeg.8.dylib" "@executable_path/../Frameworks/libjpeg.8.dylib" "$EXECUTABLE" 2>/dev/null || true

# Also fix PsyCross library if it exists
PSYCROSS_LIB="$BUILD_DIR/libPsyCross.a"
if [ -f "$PSYCROSS_LIB" ]; then
    echo "PsyCross is a static library, no path fixing needed"
fi

# Step 7.6: Compile Launcher
echo "Compiling Launcher..."
swiftc "$SRC_DIR/launcher/Launcher.swift" \
    -target arm64-apple-macos11.0 \
    -o "$APP_PATH/Contents/MacOS/Launcher"
chmod +x "$APP_PATH/Contents/MacOS/Launcher"

# Step 7.7: Copy App Icon
echo "  Copying App Icon..."
cp "$PROJECT_ROOT/Icon.icns" "$APP_PATH/Contents/Resources/Driver2.icns"

# Step 7.8: Fix Info.plist
echo " Fixing Info.plist..."
cp "$PROJECT_ROOT/Info.plist.template" "$APP_PATH/Contents/Info.plist"

# Step 8: Clean and prepare data folder
echo "📁 Preparing data folder..."
rm -rf "$APP_PATH/Contents/Resources/data"
mkdir -p "$APP_PATH/Contents/Resources/data"

# Copy unified DRIVER2 assets (already merged: original + localization)
echo "📋 Copying unified DRIVER2 assets..."
if [ -d "$PROJECT_ROOT/data/DRIVER2" ]; then
    cp -R "$PROJECT_ROOT/data/DRIVER2" "$APP_PATH/Contents/Resources/data/"
    
    TOTAL_FILES=$(find "$APP_PATH/Contents/Resources/data/DRIVER2" -type f | wc -l | tr -d ' ')
    LANG_COUNT=$(find "$APP_PATH/Contents/Resources/data/DRIVER2/LANG" -name "*.LTXT" 2>/dev/null | wc -l | tr -d ' ')
    SBN_COUNT=$(find "$APP_PATH/Contents/Resources/data/DRIVER2" -name "*_*.SBN" 2>/dev/null | wc -l | tr -d ' ')
    MISSION_COUNT=$(find "$APP_PATH/Contents/Resources/data/DRIVER2/MISSIONS" -name "*.D2MS" 2>/dev/null | wc -l | tr -d ' ')
    
    echo "  ✅ Copied $TOTAL_FILES files"
    echo "  📝 Languages: $LANG_COUNT files"
    echo "  🎬 Subtitles: $SBN_COUNT files"
    echo "  🎯 Missions: $MISSION_COUNT files"
else
    echo "❌ ERROR: data/DRIVER2 not found!"
    echo "   Run: ./cleanup_for_production.sh to consolidate assets"
    exit 1
fi

# Copy essential config and tools
echo "📋 Copying config files..."
cp "$PROJECT_ROOT/data/config.ini" "$APP_PATH/Contents/Resources/data/" 2>/dev/null || true
mkdir -p "$APP_PATH/Contents/Resources/data/install"
cp "$PROJECT_ROOT/data/install"/* "$APP_PATH/Contents/Resources/data/install/" 2>/dev/null || true

# Bundle Minimal JRE - SKIPPED (Using system Java)
# echo "Bundling minimal JRE..."
# if [ -d "$PROJECT_ROOT/jre_minimal" ]; then
#     mkdir -p "$APP_PATH/Contents/Resources/jre"
#     cp -R "$PROJECT_ROOT/jre_minimal/"* "$APP_PATH/Contents/Resources/jre/"
#     
#     JRE_SIZE=$(du -sh "$APP_PATH/Contents/Resources/jre" | cut -f1)
#     echo " Bundled JRE ($JRE_SIZE)"
# else
#     echo " Warning: jre_minimal not found. Run ./create_minimal_jre.sh first"
#     exit 1
# fi

# Remove other junk
find "$APP_PATH/Contents/Resources" -name ".DS_Store" -delete
find "$APP_PATH/Contents/Resources" -name "*.log" -delete
find "$APP_PATH/Contents/Resources" -name "imgui.ini" -delete

# Step 9: Proper Code Signing (Inside-Out)
echo "Signing bundle..."
ENTITLEMENTS="$SRC_DIR/entitlements.plist"

# 1. Sign Frameworks
find "$FRAMEWORKS_DIR" -type f -name "*.dylib" -o -name "*.framework" | while read lib; do
    codesign --force --sign - --timestamp=none --preserve-metadata=identifier,entitlements,flags "$lib"
done

# 2. Sign Libraries in JRE (if present)
if [ -d "$APP_PATH/Contents/Resources/jre" ]; then
    find "$APP_PATH/Contents/Resources/jre" -type f -name "*.dylib" | while read lib; do
        codesign --force --sign - --timestamp=none --preserve-metadata=identifier,entitlements,flags "$lib"
    done
    find "$APP_PATH/Contents/Resources/jre/bin" -type f | while read bin; do
        codesign --force --sign - --timestamp=none --preserve-metadata=identifier,entitlements,flags "$bin"
    done
fi

# 3. Sign Executables
codesign --force --sign - --timestamp=none --entitlements "$ENTITLEMENTS" --options runtime "$APP_PATH/Contents/MacOS/Launcher"
codesign --force --sign - --timestamp=none --entitlements "$ENTITLEMENTS" --options runtime "$EXECUTABLE"

# 4. Sign App Bundle
codesign --force --sign - --timestamp=none --entitlements "$ENTITLEMENTS" --options runtime "$APP_PATH"

# 5. Verify Signature
codesign --verify --deep --strict --verbose=2 "$APP_PATH" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Signature verified"
else
    echo "⚠️  Signature verification warning (expected for ad-hoc)"
fi

# Step 10: Verify
echo ""
echo "Build complete!"
echo ""
echo "Build information:"
echo "Location: $APP_PATH"
echo "Size: $(du -sh "$APP_PATH" | cut -f1)"
echo ""
echo "Library dependencies:"
otool -L "$EXECUTABLE" | grep -v ":" | grep -v "System" | grep -v "@executable_path"
echo ""
echo "Bundled frameworks:"
ls -lh "$FRAMEWORKS_DIR" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "To run: open \"$APP_PATH\""
