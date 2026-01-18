-- REDRIVER2 Build Configuration for macOS M1

require "premake_modules/usage"

-- Define paths
SDL2_DIR = os.getenv("SDL2_DIR") or "dependencies/SDL2"
OPENAL_DIR = os.getenv("OPENAL_DIR") or "dependencies/openal-soft"
JPEG_DIR = os.getenv("JPEG_DIR") or "dependencies/jpeg"

GAME_REGION = os.getenv("GAME_REGION") or "NTSC_VERSION"
GAME_VERSION = os.getenv("APPVEYOR_BUILD_VERSION") or nil

workspace "REDRIVER2"
    location "project_%{_ACTION}_%{os.target()}"
    configurations { "Debug", "Release", "Release_dev" }
    
    defines { "VERSION" } 
    
    platforms { "x64", "arm64" }

    filter "platforms:arm64"
        architecture "ARM64"

    filter "platforms:x64"
        architecture "x86_64"

    startproject "REDRIVER2"
    
    filter "system:macosx"
        includedirs {
            "/opt/homebrew/include",
            "/opt/homebrew/include/SDL2",
            "/opt/homebrew/include/AL",
            "/opt/homebrew/opt/openal-soft/include"
        }
        -- ВАЖНО: Указываем, где искать наши собранные библиотеки
        libdirs {
            "bin/Debug",
            "../bin/Debug",
            "/opt/homebrew/lib",
            "/opt/homebrew/opt/openal-soft/lib"
        }
        buildoptions {
            "-Wno-c++11-narrowing",
            "-mmacosx-version-min=11.0"
        }
        linkoptions {
            "-mmacosx-version-min=11.0"
        }
        removefiles {
            "**.rc",
            "platform/Emscripten/**"
        }
        links {
            "PsyCross",  -- Наша библиотека
            "SDL2",
            "sndfile",
            "openal",
            "OpenGL.framework",
            "Cocoa.framework",
            "IOKit.framework",
            "CoreVideo.framework",
            "Metal.framework",
            "MetalKit.framework",
            "QuartzCore.framework"
        }

    filter "configurations:Debug"
        defines { "_DEBUG", "DEBUG" }
        symbols "On"
        buildoptions { "-fsanitize=address" }
        linkoptions { "-fsanitize=address" }

    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "Speed"
        
    filter "configurations:Release_dev"
        defines { "NDEBUG" }
        optimize "Speed"

if os.target() == "windows" or os.target() == "emscripten" then
    include "premake_libjpeg.lua"
end

if os.target() ~= "emscripten" then
    include "premake5_font_tool.lua"
end

include "premake5_psycross.lua"

project "REDRIVER2"
    kind "WindowedApp"
    language "c++"
    targetdir "bin/%{cfg.buildcfg}"

    includedirs { 
        "Game",
        "PsyCross/include",
        "PsyCross/include/psx"
    }
    
    defines { GAME_REGION }
    defines { "BUILD_CONFIGURATION_STRING=\"%{cfg.buildcfg}\"" }
    
    files {
        "Game/**.h",
        "Game/**.c",
        "Game/stubs.c",
        "utils/**.h",
        "utils/**.cpp",
        "utils/**.c",
        "redriver2_psxpc.cpp"
    }

    filter "system:macosx"
        links { "jpeg" }
        targetextension ""
        
        postbuildcommands {
            "{MKDIR} %{cfg.targetdir}/REDRIVER2.app/Contents/MacOS",
            "{MKDIR} %{cfg.targetdir}/REDRIVER2.app/Contents/Resources",
            "{COPY} %{cfg.buildtarget.abspath} %{cfg.targetdir}/REDRIVER2.app/Contents/MacOS/REDRIVER2",
            "{COPY} ../platform/macosx/Info.plist %{cfg.targetdir}/REDRIVER2.app/Contents/Info.plist"
        }

    filter "configurations:Debug"
        targetsuffix "_dbg"
        defines { "DEBUG_OPTIONS", "COLLISION_DEBUG", "CUTSCENE_RECORDER" }
        symbols "On"

    filter "configurations:Release"
        optimize "Speed"
        
    filter "configurations:Release_dev"
        targetsuffix "_dev"
        defines { "DEBUG_OPTIONS", "COLLISION_DEBUG", "CUTSCENE_RECORDER" }
        optimize "Speed"

    filter { "files:**.c", "files:**.C" }
        compileas "C++"
