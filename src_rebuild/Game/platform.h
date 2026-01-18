#ifndef PLATFORM_H
#define PLATFORM_H

#ifdef __cplusplus
extern "C" {
#endif

extern void FS_FixPathSlashes(char* path);

#if defined(__EMSCRIPTEN__)
#include <emscripten/emscripten.h>
#include <emscripten/html5.h>
#endif

#include "psyx_compat.h"

#ifndef PSX
#include "../utils/fs.h"
#endif

#ifdef __GNUC__
#define _stricmp(s1, s2) strcasecmp(s1, s2)
#endif

#ifdef __cplusplus
}
#endif

#endif // PLATFORM_H