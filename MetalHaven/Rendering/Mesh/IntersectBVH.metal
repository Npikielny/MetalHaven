//
//  IntersectBVH.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 6/27/24.
//

#include <metal_stdlib>
using namespace metal;

#import "../Testing/PathTracing/PathTracing.h"

struct BoundingBox {
    float3 min;
    float3 max;
    uint16_t start;
    uint16_t count;
    uint16_t mask; // last bit = Leaf or not -> rest is primitive id
//    uint32_t mask;
};

struct BoundingRay {
    Ray ray;
    float3 inv_dir;
    float tmin = 0;
    float tmax = INFINITY;
};

inline float vector_min(float3 v) {
    return (v.x < v.y && v.x < v.z) ? v.x : (v.y < v.z ? v.y : v.z);
}

inline float vector_max(float3 v) {
    return (v.x > v.y && v.x > v.z) ? v.x : (v.y > v.z ? v.y : v.z);
}

bool intersectNode(BoundingRay ray, BoundingBox box) {
    float3 t1 = (box.min - ray.ray.origin) * ray.inv_dir;
    float3 t2 = (box.max - ray.ray.origin) * ray.inv_dir;
    
    float3 tsmin = min(t1, t2);
    float tmin = vector_min(tsmin);
    float3 tsmax = max(t1, t2);
    float tmax = vector_min(tsmax);
    
//    float tmin = vector_min((box.min - ray.ray.origin) * ray.inv_dir);
//    float tmax = vector_max((box.max - ray.ray.origin) * ray.inv_dir);
    return tmin <= tmax;
}

Intersection intersectGeometry(Ray ray, uint startingId, uint start, uint count, constant char * geometry, constant GeometryType * types) {
    return trace(ray, geometry + start, types + startingId, count);
}

Intersection intersectBVH(Ray ray, constant BoundingBox * boxes, constant char * geometry, constant GeometryType * types) {
    int remaining = 1;
    int iters[25];
    BoundingBox cache[15];
    cache[0] = boxes[0];
    Intersection intersection;
    
    BoundingRay br;
    br.ray = ray;
    br.inv_dir = 1 / ray.direction;
    
    while (remaining > 0) {
        BoundingBox box = cache[remaining - 1];
        if (intersectNode(br, box)) {
            if ((box.mask & 1) == 1) {
                uint16_t id = box.mask >> 1;
                Intersection proposal = intersectGeometry(ray, id, box.start, box.count, geometry, types);
                if (proposal.t < intersection.t) {
                    intersection = proposal;
                }
                // pop the leaf -> fall through
            } else {
                // push onto stack
                cache[remaining] = boxes[box.start + iters[remaining - 1]];
                iters[remaining] = 0;
                remaining += 1;
                continue;
            }
        }
        // pop
        remaining -= 1;
        iters[remaining - 1] -= 1;
        remaining -= 1;
    }
    return intersection;
}


