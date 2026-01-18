#!/bin/bash
set -e

echo "☕ Creating minimal JRE using jlink..."

CORRETTO_HOME="amazon-corretto-17.jdk/Contents/Home"
TARGET_JRE="jre_minimal"

if [ ! -d "$CORRETTO_HOME" ]; then
    echo "❌ Corretto JDK not found. Please run download first."
    exit 1
fi

# Remove old minimal JRE
rm -rf "$TARGET_JRE"

# Use jlink to create minimal runtime with only required modules
echo "🔗 Running jlink with minimal modules..."
"$CORRETTO_HOME/bin/jlink" \
    --add-modules java.base,java.desktop,java.logging,java.xml \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=2 \
    --output "$TARGET_JRE"

echo ""
echo "✅ Minimal JRE created with jlink"

# Calculate size
TARGET_SIZE=$(du -sh "$TARGET_JRE" | cut -f1)
echo "📊 JRE size: $TARGET_SIZE"

# Show breakdown
echo ""
echo "📁 Size breakdown:"
du -sh "$TARGET_JRE"/* | sort -hr

# Test if it works
echo ""
echo "🧪 Testing minimal JRE..."
if "$TARGET_JRE/bin/java" -version 2>&1 | head -n 1; then
    echo "✅ Minimal JRE works!"
    
    # Test with jpsxdec
    if [ -f "data/install/jpsxdec.jar" ]; then
        echo ""
        echo "🧪 Testing with jpsxdec..."
        if "$TARGET_JRE/bin/java" -jar data/install/jpsxdec.jar --help 2>&1 | head -n 5; then
            echo "✅ jpsxdec works with minimal JRE!"
        else
            echo "⚠️  jpsxdec test failed"
        fi
    fi
else
    echo "❌ Minimal JRE test failed"
    exit 1
fi

# Cleanup
echo ""
echo "🗑️  Cleaning up Corretto download..."
rm -rf amazon-corretto-17.jdk corretto-jre.tar.gz

echo "✅ Done!"
