//
//  ImageShader.metal
//  ImageRenderer
//
//  Created by Til Blechschmidt on 06.11.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum AAPLVertexInputIndex {
    AAPLVertexInputIndexVertices     = 0,
    AAPLVertexInputIndexViewportSize = 1,
} AAPLVertexInputIndex;

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
typedef enum AAPLTextureIndex {
    AAPLTextureIndexBaseColor = 0,
} AAPLTextureIndex;

//  This structure defines the layout of each vertex in the array of vertices set as an input to the
//    Metal vertex shader.  Since this header is shared between the .metal shader and C code,
//    you can be sure that the layout of the vertex array in the code matches the layout that
//    the vertex shader expects

typedef struct {
    // Positions in pixel space. A value of 100 indicates 100 pixels from the origin/center.
    packed_float2 position;

    // 2D texture coordinate
    packed_float2 textureCoordinate;
} AAPLVertex;

// ----------

typedef struct {
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer
    // will interpolate its value with values of other vertices making up the triangle
    // and pass that interpolated value to the fragment shader for each fragment in
    // that triangle.
    float2 textureCoordinate;
} RasterizerData;

// Vertex Function
vertex RasterizerData vertexShader(
    uint vertexID [[ vertex_id ]],
    constant AAPLVertex *vertexArray [[ buffer(0) ]]
) {
    RasterizerData out;
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = vertexArray[vertexID].position.xy;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

// Fragment function
fragment float4 samplingShader(
    RasterizerData in [[stage_in]],
    texture2d<half> colorTexture [[ texture(0) ]]
) {
    constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);

    // return the color of the texture
    return float4(colorSample);
}
