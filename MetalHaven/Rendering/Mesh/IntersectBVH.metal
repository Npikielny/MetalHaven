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

bool intersectNode(Ray ray, BoundingBox box) {
    return true;
}

Intersection intersectGeometry(Ray ray, uint startingId, uint start, uint count, constant char * geometry, constant GeometryType * types) {
    return trace(ray, geometry + start, types + startingId, count);
}

struct BoundingRay {
    float3 origin;
    float3 direction;
    float tmin;
    float tmax;
};

Intersection intersectBVH(Ray ray, constant BoundingBox * boxes, constant char * geometry, constant GeometryType * types) {
    int remaining = 1;
    int iters[25];
    BoundingBox cache[25];
    cache[0] = boxes[0];
    Intersection intersection;
    while (remaining > 0) {
        BoundingBox box = cache[remaining - 1];
        if (intersectNode(ray, box)) {
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


