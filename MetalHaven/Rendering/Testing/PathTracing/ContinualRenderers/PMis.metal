//
//  PMis.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/21/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

[[kernel]]
void pathMisIntegrator(uint tid [[thread_position_in_grid]],
                       constant uint & rayCount,
                       device ShadingRay * rays,
                       constant Intersection * intersections,
                       device ShadingRay * shadowRays,
                       constant Intersection * shadowTests,
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
    device ShadingRay & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    device ShadingRay & shadowRay = shadowRays[tid];
    constant Intersection & shadowTest = shadowTests[tid];
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case WAITING: {
            addShadowRay(ray, shadowRay, shadowTest);
            ray.state = FINISHED;
        }
        case FINISHED: { return; }
        case TRACING: {
            if (dot(-ray.ray.direction, intersection.n) > 0) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput;
            }
            
            MaterialSample o = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= o.sample;
            sampleShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea, false);
            ray.ray.direction = o.dir;
            ray.eta *= o.eta;
            ray.ray.origin = intersection.p;
            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE ? o.pdf / (1 / totalArea + o.pdf) : 1;
            ray.state = OLD;
            return;
        }
        case OLD: {
            float3 emission = max(0.f, -dot(ray.ray.direction, intersection.n)) * getEmission(matTypes[intersection.materialId], materials);
            ray.result += emission * ray.throughput * ray.mis;
            addShadowRay(ray, shadowRay, shadowTest);
            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                return;
            }
            
            MaterialSample o = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= o.sample / cont;
            sampleShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea, false);
            ray.ray.direction = o.dir;
            ray.eta *= o.eta;
            ray.ray.origin = intersection.p;
            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE ? o.pdf / (1 / totalArea + o.pdf) : 1;
        }
    }
}
