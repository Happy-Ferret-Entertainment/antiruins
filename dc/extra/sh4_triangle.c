// Returns 1 if point 'pt' is inside triangle with vertices 'v0', 'v1', and 'v2', and 0 if not
// Determines triangle center using barycentric coordinate transformation
// Adapted from: https://stackoverflow.com/questions/2049582/how-to-determine-if-a-point-is-in-a-2d-triangle
// Specifically the answer by user 'adreasdr' in addition to the comment by user 'urraka' on the answer from user 'Andreas Brinck'
#include "DreamHAL/inc/sh4_math.h"

/*
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
*/
