//
//  Lighting.h
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/23.
//

#ifndef Lighting_h
#define Lighting_h

#include <simd/simd.h>

enum LightingType {
    POINT_LIGHT = 0,
    DIRECTION_LIGHT = 1,
    AREA_LIGHT = 2,
};

typedef struct PointLight {
    vector_float3 position;
    vector_float3 color;
} PointLight;

//struct PointLight createPointLight(vector_float3 position, vector_float3 color) {
//    struct PointLight light;
//    light.position = position;
//    light.color = color;
//    return light;
//}

typedef struct AreaLight {
    vector_float3 color;
    unsigned int index; //  for type
    unsigned int start; // bytes
    float totalArea;
} AreaLight;

typedef struct DirectionLight {
    vector_float3 direction;
    vector_float3 color;
} DirectionLight;

typedef struct BasicMaterial {
    vector_float3 albedo;
    vector_float3 specular;
    vector_float3 emission;
} BasicMaterial;

typedef struct MirrorMat {
    vector_float3 reflectance;
} MirrorMat;

typedef struct Dielectric {
    vector_float3 reflectance;
    float IOR;
} Dielectric;

enum MaterialType {
    BASIC = 0,
    MIRROR = 1,
    DIELECTRIC = 2,
    MICROFACET = 3
};

typedef struct MaterialDescription {
    enum MaterialType type;
    unsigned int index;
} MaterialDescription;

typedef struct Microfacet {
    vector_float3 kd;
    float alpha;
} Microfacet;

float maxComponent(vector_float3 v);
#endif /* Lighting_h */
