//
//  HybridBidir.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/18/24.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

void generateShadowRayHybrid(device Ray & shadowRay,
                             constant Intersection & shadowTest,
                             device Ray & ray,
                             Intersection intersection,
                             constant MaterialDescription * matTypes,
                             constant char * materials,
                             device HaltonSampler & sampler,
                             constant float & totalArea,
                             constant ShadingPoint * shadingPoints,
                             constant uint & shadingPointCount
                             ) {
    if (matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE) {
//        ray.mis = 0;
        ShadingPoint point = shadingPoints[uint(generateSample(sampler) * float(shadingPointCount))];
        float3 dir = point.intersection.p - intersection.p;
        float d = length(dir);
        if (d == 0) {
            shadowRay.expected = -1;
            shadowRay.state = FINISHED;
        }
        shadowRay.state = TRACING;
        dir /= d;
        
        shadowRay.origin = intersection.p;
        shadowRay.direction = dir;
        shadowRay.expected = d;
        float attenuation = abs(dot(dir, point.intersection.n));
        
        float epdf = attenuation / totalArea / (d * d);
        float bsdfPdf = cosineHemispherePdf(float3(dot(dir, intersection.frame.right),
                                                   dot(dir, intersection.frame.up),
                                                   dot(dir, intersection.frame.forward)
                                                   ));
        if (bsdfPdf == 0 || epdf == 0) {
            shadowRay.state = FINISHED;
            shadowRay.expected = -INFINITY;
            return;
        }
        float mis = epdf / (epdf + bsdfPdf);
//        float mis = 1;
        shadowRay.result = point.irradiance * attenuation * abs(dot(dir, intersection.n)) * ray.throughput * mis;
    } else {
        shadowRay.expected = -1;
        shadowRay.state = FINISHED;
        ray.mis = 1;
    }
}

[[kernel]]
void hybridBidir(uint tid [[thread_position_in_grid]],
                 constant uint & rayCount,
                 device Ray * rays,
                 constant Intersection * intersections,
                 device Ray * shadowRays,
                 constant Intersection * shadowTests,
                 constant char * scene,
                 constant GeometryType * types,
                 constant MaterialDescription * matTypes,
                 constant char * materials,
                 device HaltonSampler * samplers,
                 constant AreaLight * lights,
                 constant float & totalArea,
                 constant ShadingPoint * shadingPoints,
                 constant uint & shadingPointCount
                 ) {
    if (tid >= rayCount)
        return;
    device Ray & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    device Ray & shadowRay = shadowRays[tid];
    constant Intersection & shadowTest = shadowTests[tid];
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case FINISHED: { return; }
        case WAITING: {
            if (abs(shadowTest.t - shadowRay.expected) < 1e-4) {
                ray.result += shadowRay.result;
            }
            shadowRay.state = FINISHED;
            ray.state = FINISHED;
            return;
        }
        case OLD: {
            if (abs(shadowTest.t - shadowRay.expected) < 1e-4) {
                ray.result += shadowRay.result;
            }
            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.direction, intersection.n)) * ray.throughput * ray.mis;
            
            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                shadowRay.state = FINISHED;
                shadowRay.expected = -INFINITY;
                return;
            }
            ray.throughput /= cont;
            
            auto next = smat(ray, intersection, sampler, matTypes, materials);
            ray.direction = next.dir;
            ray.origin = intersection.p;
            ray.eta *= next.eta;
            ray.throughput *= next.sample;
            ray.mis = next.pdf / (next.pdf + 1 / totalArea);
            
            generateShadowRayHybrid(shadowRay, shadowTest, ray, intersection, matTypes, materials, sampler, totalArea, shadingPoints, shadingPointCount);
            
            return;
        }
        case TRACING: {
            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.direction, intersection.n));
            
            auto next = smat(ray, intersection, sampler, matTypes, materials);
            ray.direction = next.dir;
            ray.origin = intersection.p;
            ray.eta *= next.eta;
            ray.throughput *= next.sample;
            ray.mis = next.pdf / (next.pdf + 1 / totalArea);
            
            generateShadowRayHybrid(shadowRay, shadowTest, ray, intersection, matTypes, materials, sampler, totalArea, shadingPoints, shadingPointCount);
            
            ray.state = OLD;
            return;
        }
    }
}
