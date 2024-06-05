//
//  VisualizeNormals.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/23/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

[[kernel]]
void visualizeNormals(uint tid [[thread_position_in_grid]],
                      constant uint & rayCount,
                      device Ray * rays,
                      constant Intersection * intersections,
                      constant char * scene,
                      constant GeometryType * types,
                      constant MaterialDescription * matTypes,
                      constant char * materials,
                      device HaltonSampler * samplers,
                      constant AreaLight * lights,
                      constant float & totalArea
                      ) {
    if (tid >= rayCount)
        return;
    device Ray & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    if (intersection.t == INFINITY)
        return;
//    ray.result = max(0.f, dot(-ray.direction, intersection.n)) * (intersection.n * 0.5 + 0.5);
//    ray.result = intersection.p;
    ray.result = 1;
//    ray.result = max(0.f, dot(-ray.direction, normalize(intersection.n))) * (normalize(intersection.n) * normalize(intersection.n));
//    ray.result = abs(dot(-ray.direction, intersection.n)) * (intersection.n * 0.5 + 0.5);
    ray.state = FINISHED;
}


