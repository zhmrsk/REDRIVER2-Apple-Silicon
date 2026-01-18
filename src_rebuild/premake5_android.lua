-- REDRIVER2 Android Build Configuration

require "premake_modules/usage"
require "premake_modules/androidndk/androidndk"

SDL2_DIR = os.getenv("SDL2_DIR") or "dependencies/SDL2"
OPENAL_DIR = os.getenv("OPENAL_DIR") or "dependencies/openal-soft"
JPEG_DIR = os.getenv("JPEG_DIR") or "dependencies/jpeg"
GAME_REGION = os.getenv("GAME_REGION") or "NTSC_VERSION"

workspace "REDRIVER2_Android"
    location "project_androidndk"
    configurations { "Debug", "Release" }
    platforms { "arm64" }
    
    defines { "VERSION", GAME_REGION }
    
    filter "platforms:arm64"
        architecture "ARM64"
    
    filter "system:android"
        defines {
            "__ANDROID__",
            "PLATFORM_ANDROID",
            "RENDERER_OGLES",
            "USE_OPENGL",
            "OGLES_VERSION=3",
            "ES3_SHADERS",
            "NO_IMGUI"
        }
        buildoptions {
            "-std=c++11",
            "-Wno-c++11-narrowing",
            "-x c++"  -- Force C++ compilation for all files
        }
    
    filter "configurations:Debug"
        defines { "_DEBUG", "DEBUG" }
        symbols "On"
    
    filter "configurations:Release"
        defines { "NDEBUG" }
        optimize "Speed"

include "premake5_psycross.lua"

project "REDRIVER2"
    kind "SharedLib"
    language "C++"
    targetdir "bin/%{cfg.buildcfg}"
    
    includedirs {
        "Game",
        "PsyCross/include",
        "PsyCross/include/psx",
        "utils"
    }
    
    files {
        "Game/**.h",
        "Game/**.c",
        "utils/**.h",
        "utils/**.cpp",
        "utils/**.c",
        "redriver2_psxpc.cpp",
        -- Android specific files
        "platform/Android/app/src/main/cpp/android_main.cpp",
        "platform/Android/app/src/main/cpp/PsyX_input_android.cpp",
        "platform/Android/app/src/main/cpp/PsyX_touch_android.cpp",
        "platform/Android/app/src/main/cpp/PsyX_touch_gameplay.cpp"
    }
    
    links {
        "PsyCross",
        "SDL2",
        "GLESv3",
        "log",
        "android"
    }
    
    -- Compile .c files as C++ to avoid typedef conflicts
    filter { "files:**.c" }
        compileas "C++"
    
    filter {}
