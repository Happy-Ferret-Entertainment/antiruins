#ifndef COMMON_H
#define COMMON_H
/*
 * Filename: d:\Dev\Dreamcast\UB_SHARE\gamejam\game\src\common\common.h
 * Path: d:\Dev\Dreamcast\UB_SHARE\gamejam\game\src\common
 * Created Date: Saturday, June 29th 2019, 6:28:41 pm
 * Author: Hayden Kowalchuk
 *
 * Copyright (c) 2019 HaydenKow
 */
#ifdef _arch_dreamcast
#include <kos.h>
#include <dc/fmath.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>
#include <assert.h>

//#include "file_access.h"
//#include "types.h"
//#include "stack.h"
//#include "scene/scene.h"
//#include "common/log/log.h"

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#define ABS(a) (((a) < 0) ? -(a) : (a))
#define CLAMP(x, low, high) (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

//static const float Q_CIRCLE = M_PI / 2;
//static const float SX_CIRCLE = M_PI / 4;
#define DEG2RAD(x) (x * M_PI / 180)
#define RAD2DEG(x) (x * 180 / M_PI)
#define PI (3.1415926535897932f)
#ifdef _arch_dreamcast
#define SIN(x) fsin(x)
#define COS(x) fcos(x)
#elif !defined(PSP)
#define SIN(x) sinf(x)
#define COS(x) cosf(x)
#endif

/*
extern void Game_Main(int argc, char **argv);
extern void Host_SetupChunk(void);
void Host_Update(float time);
void Host_Frame(float time);

//Per system functions
extern double Sys_FloatTime(void);
extern unsigned int Sys_Frames(void);
extern void Sys_Quit(void);

extern void Game_InputHandler(char c);
extern void Host_Input(float time);

int SYS_SND_Destroy(void);
int SYS_SND_Setup(void);

#ifdef PSP
#define printf log_trace
#endif
*/

#endif /* COMMON_H */
