//
//  Testing.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

#include <metal_stdlib>
#import "../../Scene/Tracing/Tracing.h"
using namespace metal;

[[kernel]]
void directionalTesting(uint tid [[thread_position_in_grid]],
             device ShadingRay * rays,
             device Intersection * intersections,
             constant Sphere * spheres,
             constant uint & sphereCount,
             device bool & notConverged) {
    device ShadingRay & ray = rays[tid];
    device Intersection & intersection = intersections[tid];
    
//    ray.result = float3(ray.direction * 0.5 + 0.5);
    ray.result = abs(ray.ray.direction);
    notConverged = false;
    for (uint i = 0; i < sphereCount; i ++) {
        Intersection inter = sphereIntersection(ray.ray, spheres[i]);
        if (inter.t < intersection.t) {
            intersection = inter;
        }
    }
    if (intersection.t != INFINITY) {
        ray.result = 1.0;
    }
}
