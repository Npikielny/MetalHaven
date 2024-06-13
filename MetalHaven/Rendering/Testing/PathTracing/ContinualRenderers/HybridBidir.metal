//
//  HybridBidir.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/18/24.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

void generateShadowRay(Ray ray,
                       Intersection intersection,
                       device Ray & shadowRay,
                       constant MaterialDescription * matTypes,
                       constant char * scene,
                       constant GeometryType * types,
                       ShadingPoint shadingPoint,
                       float totalArea,
                       bool mis
                       ) {
    if (matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE) {
        float3 dir = (shadingPoint.intersection.p - intersection.p);
        float d = length(dir);
        dir /= d;
        
        float attenuation = abs(dot(dir, intersection.n)) * max(0.f, dot(-dir, shadingPoint.intersection.n));
        if (attenuation == 0 || (dot(-ray.direction, intersection.n) * dot(dir, intersection.n)) < 0) {
            shadowRay.expected = -INFINITY;
            shadowRay.state = FINISHED;
            shadowRay.result = 0;
            return;
        }
        
        shadowRay.origin = intersection.p;
        shadowRay.direction = dir;
        shadowRay.expected = d;
        shadowRay.state = TRACING;
        shadowRay.result = shadingPoint.irradiance * attenuation * ray.throughput * totalArea;
        if (mis) {
            float epdf = attenuation / totalArea;
            float3 frameDir = toFrame(dir, intersection.frame);
            frameDir *= sign(dot(frameDir, intersection.n));
            float bpdf = cosineHemispherePdf(frameDir);
            shadowRay.mis = epdf / (epdf + bpdf);
        } else {
            shadowRay.mis = 1;
        }
    } else {
        shadowRay.expected = -INFINITY;
        shadowRay.state = FINISHED;
        shadowRay.result = 0;
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
            addShadowRay(ray, shadowRay, shadowTest);
            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.direction, intersection.n)) * ray.throughput * ray.mis;
            
            roulette(ray, sampler);
            
            auto next = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= next.sample;
            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, shadingPoints[int(shadingPointCount * generateSample(sampler))], totalArea, true);
            ray.direction = next.dir;
            ray.origin = intersection.p;
            ray.eta *= next.eta;
            if (matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE) {
                ray.mis = 1;
            } else {
                ray.mis = next.pdf / (next.pdf + 1 / totalArea);
            }
            return;
        }
        case TRACING: {
            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.direction, intersection.n));
            
            auto next = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= next.sample;
            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, shadingPoints[int(shadingPointCount * generateSample(sampler))], totalArea, true);
            ray.direction = next.dir;
            ray.origin = intersection.p;
            ray.eta *= next.eta;
            if (matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE) {
                ray.mis = 1;
            } else {
                ray.mis = next.pdf / (next.pdf + 1 / totalArea);
            }
            
            ray.state = OLD;
            return;
        }
    }
}

//[[kernel]]
//void hybrid(uint tid [[thread_position_in_grid]],
//            constant uint & rayCount,
//            device Ray * rays,
//            constant Intersection * intersections,
//            device Ray * samplingRays,
//            constant Intersection * samplingTests,
//            device Ray * emitterRays,
//            constant Intersection * emitterTests,
//            constant char * scene,
//            constant GeometryType * types,
//            constant MaterialDescription * matTypes,
//            constant char * materials,
//            device HaltonSampler * samplers,
//            constant AreaLight * lights,
//            constant float & totalArea,
//            constant ShadingPoint * shadingPoints,
//            constant uint & shadingPointCount
//            ) {
//    if (tid >= rayCount)
//        return;
//    device Ray & ray = rays[tid];
//    constant Intersection & intersection = intersections[tid];
//    
//    device Ray & sampleRay = samplingRays[tid];
//    constant Intersection & sampleTest = samplingTests[tid];
//    
//    device Ray & emitterRay = emitterRays[tid];
//    constant Intersection & emitterTest = emitterTests[tid];
//    
//    device HaltonSampler & sampler = samplers[tid];
//    switch (ray.state) {
//        case FINISHED: { return; }
//        case WAITING: {
//            if (abs(sampleTest.t - sampleRay.expected) < 1e-4) {
//                ray.result += sampleRay.result;
//            }
//            if (abs(emitterTest.t - emitterRay.expected) < 1e-4) {
//                ray.result += sampleRay.result;
//            }
//            sampleRay.state = FINISHED;
//            emitterRay.state = FINISHED;
//            ray.state = FINISHED;
//            return;
//        }
//        case OLD: {
//            addShadowRay(ray, sampleRay, sampleTest);
//            addShadowRay(ray, emitterRay, emitterTest);
//            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.direction, intersection.n)) * ray.throughput * ray.mis;
//            
//            roulette(ray, sampler);
//            
//            auto next = sampleBSDF(ray, intersection, sampler, matTypes, materials);
//            ray.throughput *= next.sample;
//            generateShadowRay(ray, intersection, sampleRay, matTypes, scene, types, shadingPoints[int(shadingPointCount * generateSample(sampler))], totalArea, true);
//            generateShadowRay(ray, intersection, emitterRay, matTypes, scene, types, shadingPoints[int(shadingPointCount * generateSample(sampler))], totalArea, true);
//            ray.direction = next.dir;
//            ray.origin = intersection.p;
//            ray.eta *= next.eta;
//            if (matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE) {
//                ray.mis = 1;
//            } else {
//                ray.mis = next.pdf / (next.pdf + 1 / totalArea);
//            }
//            return;
//        }
//        case TRACING: {
//            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.direction, intersection.n));
//            
//            auto next = sampleBSDF(ray, intersection, sampler, matTypes, materials);
//            ray.throughput *= next.sample;
//            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, shadingPoints[int(shadingPointCount * generateSample(sampler))], totalArea, true);
//            ray.direction = next.dir;
//            ray.origin = intersection.p;
//            ray.eta *= next.eta;
//            if (matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE) {
//                ray.mis = 1;
//            } else {
//                ray.mis = next.pdf / (next.pdf + 1 / totalArea);
//            }
//            
//            ray.state = OLD;
//            return;
//        }
//    }
//}
