## Vertex buffers
 
  It is important to align the vertex buffers for use with the the direct render API. I found 8192 gave the best results, but 32 & 64, and 1024 also worked well. To see cache thrashing in action try setting the alignment to 16384 or 32768. The polys per second will drop by about half. 
  
  mat_transform seems to work best when the source and destination buffers
  are seperate.  Therefore we have a pre and post transform vertex buffer
  
  I'm quite aware of how wasteful this is.  It's a simple matter that this
  is how you have to treat the PVR to get decent poly drawing rates.
  
  What's needed is a way to collect long vertex [Strips, Fans, Polygons]
  and blast them to the store queue every 16 to 32 verts all the while
  maintaining the proper PVR_CMD_VERTEX and ...EOL requirements.  One
  way might be to keep a copy of the last vertex submitted and toss
  it to the PVR in the glEnd statement. You will have to keep track of
  verts whose z values go < 0 and either clip them to the view frustum or
  cull them entirely.  But you'll have to do this carefully because the PVR
  does not like degenerate triangles or strips.





  gyVidSpritListBegin(color);
gyVidSprite();
gyVidSprite();
gyVidSpriteListEnd();


  void gySpriteListbegin(const GYColor4 *const color) {
    register uint32_t *ptr = (uint32_t *)pvr_vertbuf_tail(_list);

    //Initialize store queue transfers to bypass the cache
    QACR0 = ((((uint32_t)ptr) >> 26) << 2) & 0x1c;
    QACR1 = ((((uint32_t)ptr) >> 26) << 2) & 0x1c;
    _start_ptr = _current_ptr = (uint32_t *) (0xe0000000 | (((uint32_t)ptr) & 0x03ffffe0));
    ptr = _current_ptr;
  
    //Commit hardware sprite header
    shInit(&header, (_shTex)? 16 : 15, _list, _shTex, NULL);
    shSpriteColor(&header, (void*)color);
    ptr += shCommit(&header, ptr);
    _current_ptr = ptr;
}


  void gyVidSprite(void) {
     static GYVector4 localVert[4]  = {
        {-0.5f, -0.5f, 1.0f, 1.0f},
        {0.5f, -0.5f, 1.0f, 1.0f},
        {0.5f, 0.5f, 1.0f, 1.0f},
        {-0.5f, 0.5f, 1.0f, 1.0f}
    };
    register uint32_t *ptr = _current_ptr;
    GYTexCoordFrame *texCoordFrame = (_texCoordSheet)? &_texCoordSheet->texCoord[frame] : NULL;
    GYTexCoord2 texCoord[3];

    //transform local vertices by internal SH4 matrix accumulator
    gyMatMultVec(localVert, &_worldVert[0], 4);
    
    //commit hardware sprite vertex
    ptr += 16; //64-byte vertex

    // Write texture coordinates if used
    if(texCoordFrame) {
        gyVidTexCoordArrayFromFrame(texCoord, texCoordFrame);
        *--ptr = texCoord[2].uv;
        *--ptr = texCoord[1].uv;
        *--ptr = texCoord[0].uv;
    }
    else ptr -= 3;

    // Write vertices
    *--ptr = 0;
    *(float*)--ptr = _worldVert[3].y;
    *(float*)--ptr = _worldVert[3].x;
    *(float*)--ptr = _worldVert[2].z;
    *(float*)--ptr = _worldVert[2].y;
    PREFETCH((void*)ptr);
    *(float*)--ptr = _worldVert[2].x;
    *(float*)--ptr = _worldVert[1].z;
    *(float*)--ptr = _worldVert[1].y;
    *(float*)--ptr = _worldVert[1].x;
    *(float*)--ptr = _worldVert[0].z;
    *(float*)--ptr = _worldVert[0].y;
    *(float*)--ptr = _worldVert[0].x;
    *--ptr = PVR_CMD_VERTEX_EOL;
    PREFETCH((void*)ptr);
    ptr += 16;

    _current_ptr = ptr;
}

Notice I'm not writing to any struct or any intermediate structure which must get memcopied or DMA'd to the PVR. It's just a direct write to the SQs for every vertex field in the same order of the struct. 
and I'm manually incrementing the pointer, filling up the list
I think this method of blasting through the SQs is faster for hardware sprites, because they're just little structures that need to get transferred to VRAM, not bigger batches of 3D verts where the DMA would be faster...