//
//  Metropolis.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/20/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

[[kernel]]
void mlt(uint tid [[thread_position_in_grid]],
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
                 constant float & totalArea,
                 constant ShadingPoint * shadingPoints,
                 constant uint & shadingPointCount
                 ) {
    if (tid >= rayCount)
        return;
    device ShadingRay & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    device ShadingRay & shadowRay = shadowRays[tid];
    constant Intersection & shadowTest = shadowTests[tid];
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case FINISHED: { return; }
        case WAITING: {
            addShadowRay(ray, shadowRay, shadowTest);
            ray.state = FINISHED;
            return;
        }
        case OLD: {
            addShadowRay(ray, shadowRay, shadowTest);
            ray.state = FINISHED;
            shadowRay.state = FINISHED;
            shadowRay.expected = -INFINITY;
            return;
        }
        case TRACING: {
            ray.result += getEmission(matTypes[intersection.materialId], materials) * max(0.f, dot(-ray.ray.direction, intersection.n));
//
            auto next = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= next.sample;
            ray.mis = next.pdf / (next.pdf + 1 / totalArea);
            if (matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE) {
                ray.state = TRACING;
            } else {
                ray.state = OLD;
                generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, shadingPoints[0], totalArea, false);
            }
            ray.ray.direction = next.dir;
            ray.ray.origin = intersection.p;
            ray.eta *= next.eta;
            return;
        }
    }
}

[[kernel]]
void mlt2(uint tid [[thread_position_in_grid]],
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
                 constant float & totalArea,
                 constant ShadingPoint * shadingPoints,
                 constant uint & shadingPointCount
                 ) {
    if (tid >= rayCount)
        return;
    device ShadingRay & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    device ShadingRay & shadowRay = shadowRays[tid];
    constant Intersection & shadowTest = shadowTests[tid];
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case WAITING: { ray.state = FINISHED; }
        case FINISHED: {
            if (shadowRay.expected > 0 && shadowTest.t < INFINITY && (abs(shadowTest.t - shadowRay.expected) < 1e-4)) {
                ray.result += shadowRay.result;
            }
            shadowRay.state = FINISHED;
            shadowRay.expected = -INFINITY;
            return;
        }
        case TRACING: {
            if (dot(-ray.ray.direction, intersection.n) > 0) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput;
            }
            
            MaterialSample out = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            
            ray.throughput *= out.sample;
            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE ? out.pdf / (out.pdf + 1 / totalArea) : 1;
            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, shadingPoints[uint(generateSample(sampler) * shadingPointCount)], totalArea, true);
            ray.ray.origin = intersection.p;
            
            ray.state = OLD;
            ray.ray.direction = out.dir;
            ray.eta *= out.eta;
            
            return;
        }
        case OLD: {
            addShadowRay(ray, shadowRay, shadowTest);
            float3 emission = getEmission(matTypes[intersection.materialId], materials);
            ray.result += emission * ray.throughput * max(0.f, dot(-ray.ray.direction, intersection.n)) * ray.mis;
            
            if (roulette(ray, sampler))
                return;
            
            MaterialSample out = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE ? out.pdf / (out.pdf + 1 / totalArea) : 1;
            ray.throughput *= out.sample;
            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, shadingPoints[uint(generateSample(sampler) * shadingPointCount)], totalArea, true);
            
            ray.ray.origin = intersection.p;
            ray.ray.direction = out.dir;
            ray.eta *= out.eta;
        }
    }}

