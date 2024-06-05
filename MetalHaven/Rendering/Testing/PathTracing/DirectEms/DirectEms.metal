//
//  PathEms.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/13/24.
//

#include <metal_stdlib>
#import "../PathTracing.h"

using namespace metal;
[[kernel]]
void directEms(uint tid [[thread_position_in_grid]],
             device Ray * rays,
             constant uint & rayCount,
             device Intersection * intersections,
             constant char * materials,
             constant MaterialDescription * matTypes,
             constant char * scene,
             constant GeometryType * types,
             constant uint & objectCount,
             device HaltonSampler * samplers,
             constant AreaLight * lights,
             constant float & totalArea,
             device bool & indicator
             ) {
    if (tid >= rayCount)
        return;
    
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED)
        return;
    
    device Intersection & intersection = intersections[tid];
    intersection = trace(ray, scene, types, objectCount);
    if (matTypes[intersection.materialId].type == MIRROR) {
        ray.direction = reflect(ray.direction, intersection.n);
        ray.origin = intersection.p + ray.direction * 1e-4;
        intersection = trace(ray, scene, types, objectCount);
    }
    if (intersection.t != INFINITY) {
        MaterialDescription descriptor = matTypes[intersection.materialId];
        ray.result += getEmission(descriptor, materials) * ray.throughput;
        ray.throughput *= getReflectance(descriptor, materials) * abscos(ray.direction, intersection.n);
        
//        ray.direction = reflect(ray.direction, intersection.n);
        ray.origin = intersection.p + intersection.n * 1e-4;// + ray.direction * 1e-4;
        
//        ray.result = ray.throughput;
        device HaltonSampler & sampler = samplers[tid];
        LuminarySample l = sampleLuminaries(lights, totalArea, sampler, scene, types);
//        float3 l = float3(0, 2.99, 8);
//        n = float3(0, -1, 0);
        
        
        float3 dir = normalize(l.p - ray.origin);
        bool isValid = dot(-ray.direction, intersection.n) * dot(intersection.n, dir) > 0;
        ray.direction = dir;

        ray.throughput *= totalArea * abs(dot(ray.direction, intersection.n) * max(0.f, -dot(ray.direction, l.n)));
        
        Intersection shadow = trace(ray, scene, types, objectCount);
        
//        bool isValid = dot(-ray.direction, shadow.n) * dot(n, out) > 0;
        
        if (isValid && abs(shadow.t - distance(l.p, ray.origin)) < 1e-4) {
            ray.result += ray.throughput * getEmission(matTypes[shadow.materialId], materials);
        }
        
        if (ray.state == OLD) {
            float cont = min(maxComponent(ray.throughput), 0.99);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                return;
            } else {
                ray.throughput /= cont;
            }
        }
        ray.state = OLD;
        PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
        intersection = p.intersection;
        ray.throughput *= p.throughput;
        ray.direction = p.direction;
        ray.origin = intersection.p + p.direction * 1e-4;
        
        indicator = true;
    } else {
        ray.state = FINISHED;
    }
}
