//
//  Ray.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 7/19/23.
//

#include <metal_stdlib>
using namespace metal;
#import "Tracing.h"
#include "../Geometry/Geometry.h"

Ray createRay(float3 origin, float3 direction) {
    Ray r;
    r.origin = origin;
    r.direction = direction;
    r.state = TRACING;
    r.throughput = 1.0;
    r.result = 0.0;
    return r;
}

Ray cameraRay(float3 origin, float3x3 projection, float2 uv) {
    float3 pos = projection * float3(uv * 2 - 1, 1);
    return createRay(origin, pos);
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

float sphereIntersect(Sphere sphere, Ray ray) {
    float3 diff = ray.origin - sphere.position;
    float b = dot(ray.direction, diff);
    float c = dot(diff, diff) - sphere.size * sphere.size;
    float detSQ = b * b - c;
    
    if (detSQ < 0) {
        return INFINITY;
    }
    float det = sqrt(detSQ);
    float t1 = -b - det;
    if (t1 >= 0) {
        return t1;
    }
    float t2 = -b + det;
    if (t2 >= 0) {
        return t2;
    }
    return INFINITY;
}
