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
void pathEms(uint tid [[thread_position_in_grid]],
             device Ray * rays,
             constant uint & rayCount,
             constant char * materials,
             constant MaterialDescription * matTypes,
             constant char * scene,
             constant GeometryType * types,
             constant uint & objectCount,
             device HaltonSampler * samplers,
             constant AreaLight * lights,
             constant float & totalArea
             ) {
    if (tid >= rayCount)
        return;
    
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED)
        return;
    
    Intersection primaryBounce = trace(ray, scene, types, objectCount);
    if (matTypes[primaryBounce.materialId].type == MIRROR) {
        ray.direction = reflect(ray.direction, primaryBounce.n);
        ray.origin = primaryBounce.p + ray.direction * 1e-4;
        primaryBounce = trace(ray, scene, types, objectCount);
    }
    if (primaryBounce.t != INFINITY) {
        MaterialDescription descriptor = matTypes[primaryBounce.materialId];
        ray.result += getEmission(descriptor, materials) * ray.throughput;
        ray.throughput *= getReflectance(descriptor, materials) * abscos(-ray.direction, primaryBounce.n);
        
        ray.direction = reflect(ray.direction, primaryBounce.n);
        ray.origin = primaryBounce.p + primaryBounce.n * 1e-4;// + ray.direction * 1e-4;
        
//        ray.result = ray.throughput;
        device HaltonSampler & sampler = samplers[tid];
        thread float3 && n = 0.;
        float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//        float3 l = float3(0, 2.99, 8);
//        n = float3(0, -1, 0);
        
        
        ray.direction = normalize(l - ray.origin);

        ray.throughput *= totalArea * abs(dot(ray.direction, primaryBounce.n) * abs(dot(-ray.direction, n)));
        
        Intersection shadow = trace(ray, scene, types, objectCount);
        if (abs(shadow.t - distance(l, ray.origin)) < 1e-4) {
            ray.result += ray.throughput / (shadow.t * shadow.t) * getEmission(matTypes[shadow.materialId], materials);
        }
    }
    ray.state = FINISHED;
}
