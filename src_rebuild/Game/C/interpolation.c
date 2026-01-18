#include "interpolation.h"
#include "cars.h"
#include <string.h>

float g_interpolationAlpha = 0.0f;
int g_enableInterpolation = 1;

InterpolatedCarState g_prevCarState[MAX_CARS];

// Linear interpolation helper
static inline int lerp_int(int a, int b, float t)
{
	return a + (int)((b - a) * t);
}

// Matrix linear interpolation (simple, not slerp)
static void lerp_matrix(MATRIX* out, MATRIX* a, MATRIX* b, float t)
{
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 3; j++)
		{
			out->m[i][j] = (short)lerp_int(a->m[i][j], b->m[i][j], t);
		}
	}
	
	// Translation
	out->t[0] = lerp_int(a->t[0], b->t[0], t);
	out->t[1] = lerp_int(a->t[1], b->t[1], t);
	out->t[2] = lerp_int(a->t[2], b->t[2], t);
}

// Update previous state - call this after StepGame()
void UpdateInterpolationState(void)
{
	for (int i = 0; i < MAX_CARS; i++)
	{
		if (car_data[i].controlType == CONTROL_TYPE_NONE)
			continue;
			
		// Store current position as previous
		g_prevCarState[i].position.vx = car_data[i].hd.where.t[0];
		g_prevCarState[i].position.vy = car_data[i].hd.where.t[1];
		g_prevCarState[i].position.vz = car_data[i].hd.where.t[2];
		
		// Store current rotation matrix
		memcpy(&g_prevCarState[i].rotation, &car_data[i].hd.where, sizeof(MATRIX));
	}
}

// Get interpolated car position
void GetInterpolatedCarPosition(int carIndex, VECTOR* outPos)
{
	if (!g_enableInterpolation || carIndex < 0 || carIndex >= MAX_CARS)
	{
		// No interpolation - use current position
		outPos->vx = car_data[carIndex].hd.where.t[0];
		outPos->vy = car_data[carIndex].hd.where.t[1];
		outPos->vz = car_data[carIndex].hd.where.t[2];
		return;
	}
	
	// Interpolate between previous and current
	outPos->vx = lerp_int(g_prevCarState[carIndex].position.vx, 
	                      car_data[carIndex].hd.where.t[0], 
	                      g_interpolationAlpha);
	outPos->vy = lerp_int(g_prevCarState[carIndex].position.vy, 
	                      car_data[carIndex].hd.where.t[1], 
	                      g_interpolationAlpha);
	outPos->vz = lerp_int(g_prevCarState[carIndex].position.vz, 
	                      car_data[carIndex].hd.where.t[2], 
	                      g_interpolationAlpha);
}

// Get interpolated car matrix (rotation + position)
void GetInterpolatedCarMatrix(int carIndex, MATRIX* outMatrix)
{
	if (!g_enableInterpolation || carIndex < 0 || carIndex >= MAX_CARS)
	{
		// No interpolation - use current matrix
		memcpy(outMatrix, &car_data[carIndex].hd.where, sizeof(MATRIX));
		return;
	}
	
	// Interpolate matrix
	lerp_matrix(outMatrix, &g_prevCarState[carIndex].rotation, 
	            &car_data[carIndex].hd.where, g_interpolationAlpha);
}
