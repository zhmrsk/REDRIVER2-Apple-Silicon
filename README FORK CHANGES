# Fork Changes

This is a fork of [OpenDriver2/REDRIVER2](https://github.com/OpenDriver2/REDRIVER2) with the following enhancements:

## 🆕 New Features

### Ukrainian Localization
- Full Ukrainian language support for menus, subtitles, and mission briefings
- 12 language files (`.LTXT`)
- 258 subtitle files (`.SBN`)
- 534 mission files (`.D2MS`)
- Localization tools in `tools/localization/`

### macOS ARM64 Native Support
- Native Apple Silicon (M1/M2/M3) support
- Optimized for macOS 11.0+ (Big Sur and later)
- Custom launcher with FMV conversion
- Deployment target: macOS 11.0 minimum

### 64-bit Architecture Support
- Modified PsyCross library for 64-bit compilation
- Full compatibility with modern 64-bit systems
- Removed 32-bit legacy code

## 🔧 Bug Fixes

### Headlight Rendering
- Fixed headlight rendering in first-person view
- Headlights now display correctly as trapezoids from all camera angles
- Resolved perspective distortion issues

### Language Loading
- Improved language file loading system
- Added fallback mechanism for missing language files
- Better error handling for localization

### Launcher Improvements
- Parallel FMV conversion for faster processing
- Automatic cleanup of unnecessary files
- Progress tracking and error reporting
- Support for single-disc and dual-disc installations

## 📦 Build System

### macOS ARM64 Build
```bash
./build_macos_arm64.sh
```

This script:
- Builds for ARM64 architecture
- Bundles all required libraries
- Creates standalone `.app` bundle
- Includes minimal JRE for FMV conversion
- Signs the application

### Dependencies
- SDL2 (included in `src_rebuild/dependencies/`)
- OpenAL Soft (included)
- libsndfile (included)
- libjpeg (system or Homebrew)
- JRE 11+ (for FMV conversion, user must install)

## 🗂️ Project Structure

```
REDRIVER2/
├── src_rebuild/          # Source code
│   ├── Game/            # Game logic (with fixes)
│   ├── PsyCross/        # Modified for 64-bit
│   ├── launcher/        # macOS launcher
│   └── dependencies/    # Third-party libraries
├── data/                # Game data
│   ├── DRIVER2/         # Game assets + Ukrainian localization
│   ├── config.ini       # Game configuration
│   └── install/         # FMV conversion tools
├── tools/               # Development tools
│   ├── localization/    # Localization scripts
│   └── font_tool/       # Font generation
└── PSXToolchain/        # PSX build tools

```

## 🚀 Installation

### Prerequisites
1. macOS 11.0 or later (ARM64 recommended)
2. Xcode Command Line Tools
3. Homebrew (for dependencies)
4. Java 11+ (for FMV conversion)

### Building from Source
```bash
# Install dependencies
brew install sdl2 openal-soft libsndfile jpeg

# Generate project files
cd src_rebuild
premake5 gmake

# Build
cd project_gmake_macosx
make config=release_dev_arm64 -j$(sysctl -n hw.ncpu)

# Or use the build script
cd ../..
./build_macos_arm64.sh
```

### Extracting Game Assets
You need original Driver 2 PSX disc images (`.bin`/`.cue` or `.iso`):

1. Launch the app
2. Select disc images
3. Wait for extraction and FMV conversion
4. Play!

## 📝 Changelog

### Version 1.0 (Fork)
- ✅ Added Ukrainian localization
- ✅ Native ARM64 support for macOS
- ✅ 64-bit PsyCross library
- ✅ Fixed headlight rendering
- ✅ Improved language loading
- ✅ Enhanced launcher with parallel FMV conversion
- ✅ Deployment target: macOS 11.0+

## 🙏 Credits

- Original REDRIVER2 project: [OpenDriver2/REDRIVER2](https://github.com/OpenDriver2/REDRIVER2)
- Ukrainian localization: [Your Name]
- macOS ARM64 port: [Your Name]
- PsyCross 64-bit modifications: [Your Name]

## 📄 License

Same as original project - see [LICENSE](LICENSE) file.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For localization contributions, see `tools/localization/README.md`.
