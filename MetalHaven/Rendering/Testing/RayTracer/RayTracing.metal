//
//  RayTracing.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

#include <metal_stdlib>
#import "../../Scene/Tracing/Tracing.h"
#import "../../Scene/Lighting/Lighting.h"
using namespace metal;

[[kernel]]
void rayTrace(uint tid [[thread_position_in_grid]],
              device Ray * rays,
              device Intersection * intersections,
              constant Sphere * spheres,
              constant uint & sphereCount,
              device bool & notConverged) {
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED) { return; }
    device Intersection & intersection = intersections[tid];
    
//    ray.result = float3(ray.direction * 0.5 + 0.5);
    for (uint i = 0; i < sphereCount; i ++) {
        Intersection inter = sphereIntersection(ray, spheres[i]);
        if (inter.t < intersection.t) {
            intersection = inter;
        }
    }
    if (intersection.t != INFINITY) {
        ray.direction = reflect(ray.direction, intersection.n);
        ray.origin = intersection.p + ray.direction * 1e-2;
        notConverged = true;
    }
}

[[kernel]]
void rayTaceShade(uint tid [[thread_position_in_grid]],
                  device Ray * rays,
                  device Intersection * intersections,
                  constant BasicMaterial * materials
                  ) {
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED) { return; }
    device Intersection & intersection = intersections[tid];
    if (intersection.t != INFINITY) {
        ray.state = OLD;
        BasicMaterial material = materials[intersection.materialId];
        ray.result += ray.throughput * material.emission;
        ray.throughput *= material.albedo;
        
        intersection = createIntersection(INFINITY, 0, 0, 0, newFrame(0, 0, 0));
    } else {
        ray.state = FINISHED;
        ray.result += ray.throughput * (ray.direction * 0.5 + 0.5);
        
//        BasicMaterial material = materials[intersection.materialId];
//        ray.result += ray.throughput * material.emission;
//        ray.throughput *= material.albedo;
    }
}
