#include "xaplay.h"

int XAPrepared() { return 0; }
void PauseXA() {}
void ResumeXA() {}
void PrepareXA() {}
void PlayXA(int num, int channel) {}
void GetXAData(int num) {}
void SetXAVolume(int vol) {}
void StopXA() {}
void UnprepareXA() {}
void PrintXASubtitles(int frame) {}

// FMV Stub
typedef struct RENDER_ARGS RENDER_ARGS;
int FMV_main(RENDER_ARGS* args) { return 1; }
