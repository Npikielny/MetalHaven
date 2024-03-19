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
               device Ray * rays,
               constant uint & rayCount) {
    if (tid >= rayCount)
        return;
    device Ray & ray = rays[tid];
    ray.result = float3(0, 0, 1);
}
