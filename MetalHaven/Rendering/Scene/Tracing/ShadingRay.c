//
//  Ray.c
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

#include <stdio.h>
#include <simd/simd.h>
#include "../Core3D.h"

Ray createRay(vector_float3 origin, vector_float3 direction) {
    Ray r;
    r.origin = origin;
    r.direction = direction;
    return r;
}

ShadingRay createShadingRay(vector_float3 origin, vector_float3 direction) {
    ShadingRay r;
    r.ray.origin = origin;
    r.ray.direction = direction;
    r.state = TRACING;
    r.throughput = 1.0;
    r.result = 0.0;
    r.eta = 1.0;
    r.expected = -INFINITY;
    r.mis = 1;
    return r;
}

Intersection createIntersection(float t, vector_float3 p, vector_float3 n, uint materialId, Frame frame) {
    Intersection i;
    i.t = t;
    i.p = p;
    i.n = n;
    i.materialId = materialId;
    i.frame = frame;
    
    return i;
}
