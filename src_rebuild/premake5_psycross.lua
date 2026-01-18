-- Psy-Cross layer project definition

project "PsyCross"
    kind "StaticLib"
    language "C++"
    targetdir "bin/%{cfg.buildcfg}"

    defines { GAME_REGION }

    files {
        "PsyCross/**.h", 
        "PsyCross/**.H", 
        "PsyCross/**.c", 
        "PsyCross/**.C", 
        "PsyCross/**.cpp",
        "PsyCross/**.CPP",
    }

    removefiles {
        "PsyCross/external/imgui/backends/imgui_impl_allegro5.*",
        "PsyCross/external/imgui/backends/imgui_impl_android.*",
        "PsyCross/external/imgui/backends/imgui_impl_dx*",
        "PsyCross/external/imgui/backends/imgui_impl_glfw.*",
        "PsyCross/external/imgui/backends/imgui_impl_glut.*",
        "PsyCross/external/imgui/backends/imgui_impl_sdlrenderer*",
        "PsyCross/external/imgui/backends/imgui_impl_sdl3.*",
        "PsyCross/external/imgui/backends/imgui_impl_vulkan.*",
        "PsyCross/external/imgui/backends/imgui_impl_wgpu.*",
        "PsyCross/external/imgui/backends/imgui_impl_win32.*",
        "PsyCross/external/imgui/misc/freetype/**",
        "PsyCross/external/imgui/examples/**",
    }

    includedirs { 
        SDL2_DIR.."/include",
        OPENAL_DIR.."/include",
        "PsyCross/include",
        "PsyCross/external/imgui",
        "PsyCross/external/imgui/backends"
    }

    -- Windows Configuration
    filter "system:Windows"
        defines { "_WINDOWS" }
        links { "opengl32", "SDL2", "OpenAL32" }

    filter {"system:Windows", "platforms:x86"}
        libdirs { SDL2_DIR.."/lib/x86", OPENAL_DIR.."/libs/Win32" }

    filter {"system:Windows", "platforms:x64"}
        libdirs { SDL2_DIR.."/lib/x64", OPENAL_DIR.."/libs/Win64" }

    -- Linux Configuration
    filter "system:linux"
        includedirs { "/usr/include/SDL2" }
        links { "GL", "openal", "SDL2" }

    -- macOS Configuration with OpenGL
    filter "system:macosx"
        includedirs {
            "/opt/homebrew/include",
            "/opt/homebrew/include/SDL2",
            "/opt/homebrew/opt/openal-soft/include"
        }
        links {
            "OpenGL.framework",
            "SDL2",
            "OpenAL",
            "jpeg",
            "Cocoa.framework",
            "IOKit.framework",
            "CoreVideo.framework"
        }
        buildoptions {
            "-Wno-c++11-narrowing"
        }

    -- iOS Configuration
    filter "system:ios"
        systemversion "14.0"  -- Minimum iOS version
        xcodebuildsettings {
            ["IPHONEOS_DEPLOYMENT_TARGET"] = "14.0",
            ["TARGETED_DEVICE_FAMILY"] = "1,2",
            ["ONLY_ACTIVE_ARCH"] = "NO",
            ["VALID_ARCHS"] = "arm64"
        }
        buildoptions {
            "-Wno-c++11-narrowing"
        }

    -- Release Optimizations
    filter "configurations:Release"
        optimize "Speed"

    filter "configurations:Release_dev"
        optimize "Speed"

usage "PsyCross"
    links "PsyCross"
    includedirs {
        "PsyCross/include",
        "PsyCross/include/psx"
    }
