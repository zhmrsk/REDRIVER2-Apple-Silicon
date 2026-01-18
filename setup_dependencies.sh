#!/bin/bash
set -e

echo "🔧 Setting up REDRIVER2 dependencies"
echo "====================================="
echo ""

# Check if we're in the right directory
if [ ! -d "src_rebuild" ]; then
    echo "❌ Error: Please run this script from the REDRIVER2 root directory"
    exit 1
fi

cd src_rebuild

# Create dependencies directory
mkdir -p dependencies
cd dependencies

echo "📦 Downloading dependencies..."
echo ""

# SDL2
echo "1️⃣  Downloading SDL2..."
if [ ! -d "SDL2" ]; then
    git clone --depth 1 --branch release-2.30.0 https://github.com/libsdl-org/SDL.git SDL2
    echo "   ✅ SDL2 downloaded"
else
    echo "   ⏭️  SDL2 already exists"
fi

# libsndfile
echo "2️⃣  Downloading libsndfile..."
if [ ! -d "libsndfile" ]; then
    git clone --depth 1 --branch 1.2.2 https://github.com/libsndfile/libsndfile.git
    echo "   ✅ libsndfile downloaded"
else
    echo "   ⏭️  libsndfile already exists"
fi

# openal-soft
echo "3️⃣  Downloading OpenAL Soft..."
if [ ! -d "openal-soft" ]; then
    git clone --depth 1 --branch 1.23.1 https://github.com/kcat/openal-soft.git
    echo "   ✅ OpenAL Soft downloaded"
else
    echo "   ⏭️  OpenAL Soft already exists"
fi

echo ""
echo "✅ All dependencies downloaded!"
echo ""
echo "📋 Next steps:"
echo "   1. Install system dependencies: brew install jpeg"
echo "   2. Generate project: cd .. && premake5 gmake"
echo "   3. Build: cd project_gmake_macosx && make config=release_dev_arm64"
echo ""
