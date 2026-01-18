#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#include "driver2.h"
#include "psx/types.h"
#include "psx/libgte.h"
#include "PsyX/common/pgxp_defs.h"

#ifdef __cplusplus
extern "C" {
#endif

// --- PGXP Stubs (REMOVED: Defined in PsyX_GTE.cpp) ---
/*
void PGXP_SetZOffsetScale(float offset, float scale) {}
unsigned short PGXP_EmitCacheData(PGXPVData* newData) { return 0; }
int PGXP_GetCacheData(PGXPVData* out, uint lookup, ushort indexhint) { return 0; }
unsigned short PGXP_GetIndex(int i) { return 0; }
void PGXP_ClearCache() {}
*/

// --- RotTransPers Stub ---
// REMOVED: Defined in LIBGTE.C
/*
int RotTransPers(SVECTOR* v0, int* sxy, long* p, long* flag)
{
    return 0; 
}
*/

// --- TransPers Stub ---
long TransPers(VECTOR *v0, int *sxy, long *p, long *flag)
{
    return 0;
}

// --- FS_FixPathSlashes Stub ---
/*
void FS_FixPathSlashes(char* pathbuff) 
{
    while (*pathbuff) {
        if (*pathbuff == '\\') *pathbuff = '/';
        pathbuff++;
    }
}
*/

// --- Глобальные переменные GTE (REMOVED: Defined in PsyX_GTE.cpp) ---
/*
PGXPVector3D g_FP_SXYZ0;
PGXPVector3D g_FP_SXYZ1;
PGXPVector3D g_FP_SXYZ2;
*/


#ifdef __cplusplus
}
#endif