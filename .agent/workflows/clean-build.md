---
description: Clean build of REDRIVER2 (83MB with GitHub assets)
---

# Clean Build Workflow

This workflow creates a clean, distributable build of REDRIVER2 using the automated build script.

**What it does:**
- Compiles game binary and launcher
- Bundles optimized JRE (~45MB)
- Includes GitHub base assets (for game and reset functionality)
- Bundles all required libraries
- Signs the application
- **Size:** ~83MB

## Prerequisites

Ensure you have downloaded GitHub assets:
```bash
cd /Users/zhmursky/redriver2_dev/REDRIVER2
./download_github_assets.sh
```

Ensure you have created minimal JRE:
```bash
cd /Users/zhmursky/redriver2_dev/REDRIVER2
./create_minimal_jre.sh
```

## Build Steps

// turbo-all

1. **Run clean build script**
```bash
cd /Users/zhmursky/redriver2_dev/REDRIVER2
./build_clean_release.sh
```

## Expected Result

- **Location:** `/Users/zhmursky/redriver2_dev/REDRIVER2/src_rebuild/bin/Release_dev/REDRIVER2.app`
- **Size:** ~83MB
- **Contains:**
  - Game binary (REDRIVER2)
  - Launcher (Swift UI)
  - Optimized JRE (~45MB)
  - GitHub base assets (81 files in `data/DRIVER2`)
  - GitHub assets backup (81 files in `github_assets/DRIVER2` for reset)
  - All required frameworks
  - App icon

## What's Included

### Game Files
- `data/DRIVER2/` - Base game assets from GitHub (81 files)
- `data/config.ini` - Game configuration
- `data/install/jpsxdec.jar` - PSX disc extraction tool

### Reset Functionality
- `github_assets/DRIVER2/` - Backup of base assets for reset (81 files)

### Runtime
- `jre/` - Minimal Java Runtime Environment
- `Frameworks/` - Bundled libraries (SDL2, OpenAL, etc.)

## Usage

After build completes, you can:

**Run the app:**
```bash
open /Users/zhmursky/redriver2_dev/REDRIVER2/src_rebuild/bin/Release_dev/REDRIVER2.app
```

**Copy to Applications:**
```bash
cp -R /Users/zhmursky/redriver2_dev/REDRIVER2/src_rebuild/bin/Release_dev/REDRIVER2.app /Applications/
```

**Test reset functionality:**
1. Install game with disc images
2. Go to Options → Reset Installation
3. Verify all extracted files are deleted
4. Verify base assets remain
