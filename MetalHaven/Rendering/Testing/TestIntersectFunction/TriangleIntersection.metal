//
//  TriangleIntersection.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/13/24.
//

#include <metal_stdlib>
#include "../PathTracing/PathTracing.h"
using namespace metal;

[[kernel]]
void integrateTriangle(uint tid [[thread_position_in_grid]],
               device ShadingRay * rays,
               constant uint & rayCount) {
    if (tid >= rayCount)
        return;
    device ShadingRay & ray = rays[tid];
    ray.result = float3(0, 0, 1);
}
