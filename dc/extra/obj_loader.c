/*
 * Filename: d:\Dev\Dreamcast\UB_SHARE\gamejam\game\src\common\obj_loader.c
 * Path: d:\Dev\Dreamcast\UB_SHARE\gamejam\game\src\common
 * Created Date: Friday, August 2nd 2019, 6:56:05 pm
 * Author: Hayden Kowalchuk
 *
 * Copyright (c) 2019 HaydenKow
 */

#define TINYOBJ_LOADER_C_IMPLEMENTATION
#include "extra/obj_loader_lib.h"
#include "extra/obj_loader.h"

extern char error_str[64];

static int LoadObjAndConvert(const char *filename, model_obj *obj);

model_obj OBJ_load(char *path)
{
  model_obj obj;
  LoadObjAndConvert(transform_path(path), &obj);
  return obj;
}

void OBJ_destroy(model_obj *obj)
{
  if (obj->tris)
  {
    free(obj->tris);
    memset(obj, 0, sizeof(model_obj));
  }
}

//extern int filelength(FILE *f);

static int LoadObjAndConvert(const char *path, model_obj *obj)
{
  tinyobj_attrib_t attrib;
  tinyobj_shape_t *shapes = NULL;
  size_t num_shapes = 0;
  tinyobj_material_t *materials = NULL;
  size_t num_materials = 0;

  float bmin[3], bmax[3];

  obj->num_faces = 0;
  obj->num_tris = 0;

  int data_len = 0;
  FILE *f = fopen(path, "r");

  if (!f)
  {
    printf(error_str, "[%s] Error opening %s: %s\n", __func__, path, strerror(errno));
    sprintf(error_str, "er: %s\n", path);
    return -1;
  }

  data_len = Sys_FileLength(f);
  if (data_len == 0)
  {
    return 0;
  }
  char *data = malloc(data_len);
  fread(data, data_len, 1, f);
  fclose(f);

  {
    unsigned int flags = TINYOBJ_FLAG_TRIANGULATE;
    int ret = tinyobj_parse_obj(&attrib, &shapes, &num_shapes, &materials,
                                &num_materials, data, data_len, flags);
    if (ret != TINYOBJ_SUCCESS)
    {
      return 0;
    }

    //printf("# of shapes    = %d\n", (int)num_shapes);
    //printf("# of materials = %d\n", (int)num_materials);

    {
      size_t i;
      for (i = 0; i < num_shapes; i++)
      {
        //printf("shape[%d] name = %s\n", i, shapes[i].name);
      }
    }
  }

  bmin[0] = bmin[1] = bmin[2] = FLT_MAX;
  bmax[0] = bmax[1] = bmax[2] = -FLT_MAX;

  float *vb;
  int face_offset = 0;
  size_t i;

  /* Assume triangulated face. */
  int num_triangles = attrib.num_face_num_verts;
  //printf("Num verts: %d\n", attrib.num_face_num_verts-1);

  int stride = 5; /* 8 = pos(3float), uv(2float), color(3float) */

  vb = (float *)malloc(sizeof(float) * stride * num_triangles * 3);

  for (i = 0; i < attrib.num_face_num_verts; i++)
  {

    assert(attrib.face_num_verts[i] % 3 == 0); /* assume all triangle faces. */

    for (int face = 0; face < (int)attrib.face_num_verts[i] / 3; face++)
    {
      int k;
      float v[3][5];
      float vt[3][2];
      //float uv[3][2];
      //float c[3];
      //float len2;

      tinyobj_vertex_index_t idx0 = attrib.faces[face_offset + 3 * face + 0];
      tinyobj_vertex_index_t idx1 = attrib.faces[face_offset + 3 * face + 1];
      tinyobj_vertex_index_t idx2 = attrib.faces[face_offset + 3 * face + 2];

      for (k = 0; k < 3; k++)
      {
        int f0 = idx0.v_idx;
        int f1 = idx1.v_idx;
        int f2 = idx2.v_idx;
        //printf("making face: %d// %d// %d//\n", f0+1,f1+1,f2+1);

        assert(f0 >= 0);
        assert(f1 >= 0);
        assert(f2 >= 0);

        v[0][k] = attrib.vertices[3 * (unsigned int)f0 + k];
        v[1][k] = attrib.vertices[3 * (unsigned int)f1 + k];
        v[2][k] = attrib.vertices[3 * (unsigned int)f2 + k];
        if (k < 2)
        {
          vt[0][k] = attrib.texcoords[2 * idx0.vt_idx + k];
          vt[1][k] = attrib.texcoords[2 * idx1.vt_idx + k];
          vt[2][k] = attrib.texcoords[2 * idx2.vt_idx + k];
        }
        bmin[k] = (v[0][k] < bmin[k]) ? v[0][k] : bmin[k];
        bmin[k] = (v[1][k] < bmin[k]) ? v[1][k] : bmin[k];
        bmin[k] = (v[2][k] < bmin[k]) ? v[2][k] : bmin[k];
        bmax[k] = (v[0][k] > bmax[k]) ? v[0][k] : bmax[k];
        bmax[k] = (v[1][k] > bmax[k]) ? v[1][k] : bmax[k];
        bmax[k] = (v[2][k] > bmax[k]) ? v[2][k] : bmax[k];
      }
#if 0 /* Not using Normals */
        if (attrib.num_normals > 0)
        {
          int f0 = idx0.vn_idx;
          int f1 = idx1.vn_idx;
          int f2 = idx2.vn_idx;

          if (f0 >= 0 && f1 >= 0 && f2 >= 0)
          {
            assert(f0 < (int)attrib.num_normals);
            assert(f1 < (int)attrib.num_normals);
            assert(f2 < (int)attrib.num_normals);
            for (k = 0; k < 3; k++)
            {
              n[0][k] = attrib.normals[3 * (int)f0 + k];
              n[1][k] = attrib.normals[3 * (int)f1 + k];
              n[2][k] = attrib.normals[3 * (int)f2 + k];
            }
          }
          else
          { /* normal index is not defined for this face */
            /* compute geometric normal */
            CalcNormal(n[0], v[0], v[1], v[2]);
            n[1][0] = n[0][0];
            n[1][1] = n[0][1];
            n[1][2] = n[0][2];
            n[2][0] = n[0][0];
            n[2][1] = n[0][1];
            n[2][2] = n[0][2];
          }

        }
        else
        {
          /* compute geometric normal */
          CalcNormal(n[0], v[0], v[1], v[2]);
          n[1][0] = n[0][0];
          n[1][1] = n[0][1];
          n[1][2] = n[0][2];
          n[2][0] = n[0][0];
          n[2][1] = n[0][1];
          n[2][2] = n[0][2];
        }
#endif

      for (k = 0; k < 3; k++)
      {
        //printf("i = %d & k = %d [%d %d %d]\n", i, k, (3 * stride * i) + k * stride + 0, (9 * i) + k * stride + 1, (3 * stride * i) + k * stride + 2);
        // Vertex Positions
        vb[(3 * stride * i) + k * stride + 0] = v[k][0];
        vb[(3 * stride * i) + k * stride + 1] = v[k][1];
        vb[(3 * stride * i) + k * stride + 2] = v[k][2];

        //Texture UVs
        vb[(3 * stride * i) + k * stride + 3] = vt[k][0];
        vb[(3 * stride * i) + k * stride + 4] = 1.0f - vt[k][1];

        //vb[(3 * i + k) * stride + 3] = n[k][0];
        //vb[(3 * i + k) * stride + 4] = n[k][1];
        //vb[(3 * i + k) * stride + 5] = n[k][2];
        //printf("v %f, %f, %f\n", v[k][0], v[k][1], v[k][2]);
#if 0
          /* Use normal as color. */
          c[0] = n[k][0];
          c[1] = n[k][1];
          c[2] = n[k][2];
          len2 = c[0] * c[0] + c[1] * c[1] + c[2] * c[2];
          if (len2 > 0.0f)
          {
            float len = (float)sqrt((double)len2);

            c[0] /= len;
            c[1] /= len;
            c[2] /= len;
          }


          vb[(3 * i + k) * stride + 6] = (c[0] * 0.5f + 0.5f);
          vb[(3 * i + k) * stride + 7] = (c[1] * 0.5f + 0.5f);
          vb[(3 * i + k) * stride + 8] = (c[2] * 0.5f + 0.5f);
#endif
      }
    }
    face_offset += (int)attrib.face_num_verts[i];
  }

  for (i = 1; i < (size_t)(num_triangles * 3); i += 3)
  {
    //printf("f  %d// %d// %d//\n",i, i+1, i+2);
  }

  if (num_triangles > 0)
  {
    obj->num_tris = (int)num_triangles * 3;
    obj->num_faces = (int)attrib.num_face_num_verts;
    obj->tris = (vec3 *)vb;
    memcpy(obj->min, bmin, sizeof(bmin));
    memcpy(obj->max, bmax, sizeof(bmax));
  }

#if 0
  printf("bmin = %f, %f, %f\n", (double)bmin[0], (double)bmin[1],
         (double)bmin[2]);
  printf("bmax = %f, %f, %f\n", (double)bmax[0], (double)bmax[1],
         (double)bmax[2]);
#endif

  free(data);

  tinyobj_attrib_free(&attrib);
  tinyobj_shapes_free(shapes, num_shapes);
  tinyobj_materials_free(materials, num_materials);
  return 1;
}
