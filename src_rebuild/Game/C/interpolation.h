#ifndef INTERPOLATION_H
#define INTERPOLATION_H

#include "driver2.h"

// Interpolation alpha (0.0 to 1.0)
// Represents how far between the previous and current game state we are
extern float g_interpolationAlpha;

// Enable/disable interpolation
extern int g_enableInterpolation;

// Store previous car positions for interpolation
typedef struct {
	VECTOR position;
	MATRIX rotation;
} InterpolatedCarState;

extern InterpolatedCarState g_prevCarState[MAX_CARS];

// Update previous state (call after StepGame)
extern void UpdateInterpolationState(void);

// Get interpolated car position
extern void GetInterpolatedCarPosition(int carIndex, VECTOR* outPos);

// Get interpolated car matrix
extern void GetInterpolatedCarMatrix(int carIndex, MATRIX* outMatrix);

#endif
