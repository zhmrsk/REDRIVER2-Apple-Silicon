#ifndef FS_H
#define FS_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
    #include <direct.h>
    #define HOME_ENV "USERPROFILE"
#elif defined(__APPLE__) || defined(__unix__)
    #include <sys/stat.h>
    #define HOME_ENV "HOME"
    #ifndef _mkdir
        #define _mkdir(str) mkdir(str, 0775)
    #endif
#endif

struct FS_FINDDATA;

void FS_FixPathSlashes(char* pathbuff);

const char* FS_FindFirst(const char* wildcard, FS_FINDDATA** findData);
const char* FS_FindNext(FS_FINDDATA* findData);
void        FS_FindClose(FS_FINDDATA* findData);
int         FS_FindIsDirectory(FS_FINDDATA* findData);

#ifdef __cplusplus
}
#endif

#endif // FS_H
