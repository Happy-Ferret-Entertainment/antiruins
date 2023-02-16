#ifndef OBJ_LOADER_H
#define OBJ_LOADER_H
/*
 * Filename: d:\Dev\Dreamcast\UB_SHARE\gamejam\game\src\common\obj_loader.h
 * Path: d:\Dev\Dreamcast\UB_SHARE\gamejam\game\src\common
 * Created Date: Friday, August 2nd 2019, 6:56:14 pm
 * Author: Hayden Kowalchuk
 *
 * Copyright (c) 2019 HaydenKow
 */
#include "common.h"

typedef struct model_obj
{
    vec3* tris;
    int num_tris;
    int num_faces;
    float min[3];
    float max[3];
    unsigned int texture;
} model_obj;

model_obj   OBJ_load(char *path);
void        OBJ_destroy(model_obj *obj);

#endif /* OBJ_LOADER_H */
