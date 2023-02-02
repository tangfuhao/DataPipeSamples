//
//  ShaderTypes.h
//  YunNeutronDemo
//
//  Created by fuhao on 2022/7/26.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>



//在 Shader 和 C 共享相同的缓冲区索引值，以确保 Metal Shader 缓冲区输入和 Metal API 缓冲区相匹配
typedef enum BufferIndices {
    kBufferIndexMeshPositions    = 0,
    kBufferIndexMeshGenerics     = 1,
    kBufferIndexInstanceUniforms = 2,
    kBufferIndexSharedUniforms   = 3
} BufferIndices;


//在 Shader 和 C 共享属性索引值，以确保 Metal Shader 的顶点属性索引与 Metal API 的顶点描述符属性索引相匹配。
typedef enum VertexAttributes {
    kVertexAttributePosition  = 0,
    kVertexAttributeTexcoord  = 1,
    kVertexAttributeNormal    = 2
} VertexAttributes;


//在 Shader 和 C 共享纹理索引值，以确保 Metal Shader 的纹理索引与 Metal API 纹理集调用的索引相匹配
typedef enum TextureIndices {
    kTextureIndexColor    = 0,
    kTextureIndexY        = 1,
    kTextureIndexCbCr     = 2
} TextureIndices;




//在 Shader 和 C 共享相同的结构体，以确保在 Metal Shader 中访问的 data 布局与C代码中的 data 的布局相匹配。
typedef struct {
    // Camera Uniforms
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    
    // Lighting Properties
    vector_float3 ambientLightColor;
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;
    float materialShininess;
} SharedUniforms;


typedef struct {
    matrix_float4x4 modelMatrix;
} InstanceUniforms;

#endif /* ShaderTypes_h */
