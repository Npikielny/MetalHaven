//
//  Geometry.h
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/23.
//

#ifndef Geometry_h
#define Geometry_h

#include <simd/simd.h>

enum GeometryType {
    NO_GEOMETRY = 0,
    SPHERE = 1,
    BOX = 2,
    TRIANGLE = 3,
    PLANE = 4
};

typedef struct Sphere {
    vector_float3 position;
    float size;
    int material;
} Sphere;

typedef struct Box {
    vector_float3 position;
    vector_float3 size;
    int material;
} Box;

typedef struct Triangle {
    vector_float3 v1;
    vector_float3 v2;
    vector_float3 v3;
    int material;
} Triangle;

typedef struct Plane {
    vector_float3 v1;
    vector_float3 v2;
    vector_float3 v3;
    int material;
} Plane;

Sphere createSphere(vector_float3 position, float size, int material);

#endif /* Geometry2D_h */
