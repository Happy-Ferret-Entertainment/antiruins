#include "DreamHAL/inc/sh4_math.h"
#include <math.h>
#include "antiruins.h"

// Returns 1 if point 'pt' is inside triangle with vertices 'v0', 'v1', and 'v2', and 0 if not
// Determines triangle center using barycentric coordinate transformation
// Adapted from: https://stackoverflow.com/questions/2049582/how-to-determine-if-a-point-is-in-a-2d-triangle
// Specifically the answer by user 'adreasdr' in addition to the comment by user 'urraka' on the answer from user 'Andreas Brinck'
static inline __attribute__((always_inline)) int MATH_Point_Inside_Triangle3(float v0x, float v0y, float v1x, float v1y, float v2x, float v2y, float ptx, float pty)
{
  float sdot = MATH_fipr(v0y, -v0x, v2y - v0y, v0x - v2x, v2x, v2y, ptx, pty);
  float tdot = MATH_fipr(v0x, -v0y, v0y - v1y, v1x - v0x, v1y, v1x, ptx, pty);

  float areadot = MATH_fipr(-v1y, v0y, v0x, v1x, v2x, -v1x + v2x, v1y - v2y, v2y);

  // 'areadot' could be negative depending on the winding of the triangle
  if(areadot < 0.0f)
  {
    sdot *= -1.0f;
    tdot *= -1.0f;
    areadot *= -1.0f;
  }

  if( (sdot > 0.0f) && (tdot > 0.0f) && (areadot > (sdot + tdot)) )
  {
    return 1;
  }
  return 0;
}

// OLD VERSION!!!
static inline __attribute__((always_inline)) int MATH_Point_Inside_Triangle2(float v0x, float v0y, float v1x, float v1y, float v2x, float v2y, float ptx, float pty)
{
  /*
  float sdot = MATH_fipr(v0y, -v0x, v2y - v0y, v0x - v2x, v2x, v2y, ptx, pty);
  float tdot = MATH_fipr(v0x, -v0y, v0y - v1y, v1x - v0x, v1y, v1x, ptx, pty);

  float areadot = MATH_fipr(-v1y, v0y, v0x, v1x, v2x, -v1x + v2x, v1y - v2y, v2y);
  */

  float areadot = 0.5 *(-v1y*v2x + v0y*(-v1x + v2x) + v0x*(v1y - v2y) + v1x*v2y);
  float sdot = 1/(2*areadot)*(v0y * v2x - v0x * v2y + (v2y - v0y)* ptx + (v0x - v2x)* pty);
  float tdot = 1/(2*areadot)*(v0x * v1y - v0y * v1x + (v0y - v1y)* ptx + (v1x - v0x)* pty);

  // 'areadot' could be negative depending on the winding of the triangle
  /*
  if(areadot < 0.0f)
  {
    sdot *= -1.0f;
    tdot *= -1.0f;
    areadot *= -1.0f;
  }
  */

  //if( (sdot > 0.0f) && (tdot > 0.0f) && (areadot > (sdot + tdot)) )
  if( (sdot > 0.0f) && (tdot > 0.0f) && (1-sdot-tdot > 0) )
  {
    return 1;
  }

  return 0;
}

int sh4_distance(lua_State *L);
int sh4_sum_sq(lua_State *L);
int sh4_fsrra(lua_State *L);
int sh4_lerp(lua_State *L);
int sh4_sqrt(lua_State *L);
int sh4_sin(lua_State *L);
int sh4_cos(lua_State *L);
int sh4_abs(lua_State *L);
int sh4_vecNormalize(lua_State *L);
int sh4_vec2Normalize(lua_State *L);
int sh4_vecLength(lua_State *L);
int sh4_insideTriangle(lua_State *L);

int initMath() {

  lua_pushcfunction(luaData, sh4_sqrt);
  lua_setglobal(luaData, "sh4_sqrt");

  lua_pushcfunction(luaData, sh4_fsrra);
  lua_setglobal(luaData, "sh4_fsrra");

  lua_pushcfunction(luaData, sh4_lerp);
  lua_setglobal(luaData, "sh4_lerp");

  lua_pushcfunction(luaData, sh4_sum_sq);
  lua_setglobal(luaData, "sh4_sum_sq");

  lua_pushcfunction(luaData, sh4_abs);
  lua_setglobal(luaData, "sh4_abs");

  lua_pushcfunction(luaData, sh4_sin);
  lua_setglobal(luaData, "sh4_sin");

  lua_pushcfunction(luaData, sh4_cos);
  lua_setglobal(luaData, "sh4_cos");

  lua_pushcfunction(luaData, sh4_distance);
  lua_setglobal(luaData, "sh4_distance");

  lua_pushcfunction(luaData, sh4_insideTriangle);
  lua_setglobal(luaData, "sh4_insideTriangle");

  lua_pushcfunction(luaData, sh4_vecNormalize);
  lua_setglobal(luaData, "sh4_vecNormalize");

  lua_pushcfunction(luaData, sh4_vec2Normalize);
  lua_setglobal(luaData, "sh4_vec2Normalize");

  lua_pushcfunction(luaData, sh4_vecLength);
  lua_setglobal(luaData, "sh4_vecLength");

  return(1);
}

int sh4_distance(lua_State *L) {
  lua_pushnumber(L, MATH_Fast_Sqrt(MATH_Sum_of_Squares(
    0,
    (float)lua_tonumber(L, 1) - (float)lua_tonumber(L, 3),
    (float)lua_tonumber(L, 2) - (float)lua_tonumber(L, 4),
    0)));
  return(1);
}

// Sum of Square
int sh4_sum_sq(lua_State *L) {
  lua_pushnumber(L,
    MATH_Sum_of_Squares(
      0.0f,
      (float)lua_tonumber(L, 1),
      (float)lua_tonumber(L, 2),
      (float)lua_tonumber(L, 3)
    )
  );
  return(1);
}

// vector normalize
int sh4_vecLength(lua_State *L) {
  lua_pushnumber(L,
    MATH_Fast_Sqrt(
      MATH_Sum_of_Squares(
        0,
        (float)lua_tonumber(L, 1),
        (float)lua_tonumber(L, 2),
        (float)lua_tonumber(L, 3))));
  return(1);
}

// vector normalize
int sh4_vecNormalize(lua_State *L) {
  //float magnitude = 0;
  float x         = (float)lua_tonumber(L, 1);
  float y         = (float)lua_tonumber(L, 2);
  float z         = (float)lua_tonumber(L, 3);


   if(__builtin_expect(x || y || z, 1)) {
    float temp = MATH_Sum_of_Squares(x, y, z, 0); // temp = x^2 + y^2 + z^2 + 0^2
    float normalizer = MATH_fsrra(temp); // 1/sqrt(temp)
    x = normalizer * x;
    y = normalizer * y;
    z = normalizer * z;
    //magnitude = MATH_Fast_Invert(normalizer);
  }

  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, z);
  return(3);
}

// vector normalize
int sh4_vec2Normalize(lua_State *L) {
  //float magnitude = 0;
  float x         = (float)lua_tonumber(L, 1);
  float y         = (float)lua_tonumber(L, 2);


   if(__builtin_expect(x || y, 1)) {
    float temp = MATH_Sum_of_Squares(x, y, 0, 0); // temp = x^2 + y^2 + z^2 + 0^2
    float normalizer = MATH_fsrra(temp); // 1/sqrt(temp)
    x = normalizer * x;
    y = normalizer * y;
    //magnitude = MATH_Fast_Invert(normalizer);
  }

  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return(2);
}


// fsrra
int sh4_lerp(lua_State *L) {
  lua_pushnumber(L,
    MATH_lerp(
      (float)lua_tonumber(L, 1),
      (float)lua_tonumber(L, 2),
      (float)lua_tonumber(L, 3)
    )
  );
  return(1);
}

// fsrra
int sh4_fsrra(lua_State *L) {
  lua_pushnumber(L, MATH_fsrra((float)lua_tonumber(L, -1)));
  return(1);
}

// Square root
int sh4_sqrt(lua_State *L) {
  lua_pushnumber(L, MATH_Fast_Sqrt((float)lua_tonumber(L, -1)));
  return(1);
}

// abs
int sh4_abs(lua_State *L) {
  lua_pushnumber(L, MATH_fabs((float)lua_tonumber(L, -1)));
  return(1);
}

// Cos
int sh4_cos(lua_State *L) {
  RETURN_FSCA_STRUCT r = MATH_fsca_Float_Rad((float)lua_tonumber(L, -1));
  lua_pushnumber(L, r.cosine);
  return(1);
}

// Sin
int sh4_sin(lua_State *L) {
  RETURN_FSCA_STRUCT r = MATH_fsca_Float_Rad((float)lua_tonumber(L, -1));
  lua_pushnumber(L, r.sine);
  return(1);
}

// Sin
int sh4_insideTriangle(lua_State *L) {
  uint8_t r = MATH_Point_Inside_Triangle3(
    (float)lua_tonumber(L, 1),
    (float)lua_tonumber(L, 2),
    (float)lua_tonumber(L, 3),
    (float)lua_tonumber(L, 4),
    (float)lua_tonumber(L, 5),
    (float)lua_tonumber(L, 6),
    (float)lua_tonumber(L, 7),
    (float)lua_tonumber(L, 8)
  );
  /*
  printf("C > %0.1f - %0.1f - %0.1f - %0.1f - %0.1f - %0.1f - %0.1f - %0.1f \n",
    (float)lua_tonumber(L, 1),
    (float)lua_tonumber(L, 2),
    (float)lua_tonumber(L, 3),
    (float)lua_tonumber(L, 4),
    (float)lua_tonumber(L, 5),
    (float)lua_tonumber(L, 6),
    (float)lua_tonumber(L, 7),
    (float)lua_tonumber(L, 8));
  */
  lua_pushboolean(L, r);
  return(1);
}
