//
//  PEms.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/25/24.
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
                       device HaltonSampler & sampler,
                       constant AreaLight * lights,
                       constant float & totalArea
                       ) {
    if (matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE) {
        LuminarySample l = sampleLuminaries(lights, totalArea, sampler, scene, types);
        float3 dir = normalize(l.p - intersection.p);
        shadowRay.origin = intersection.p;
        shadowRay.direction = dir;
        float dist = distance(intersection.p, l.p);
        shadowRay.expected = dist;
        shadowRay.throughput = ray.throughput * max(0.f, dot(-dir, l.n)) * abs(dot(dir, intersection.n)) / (dist * dist) * totalArea;
        shadowRay.state = TRACING;
    } else {
        shadowRay.expected = -1;
        shadowRay.state = FINISHED;
    }
}

[[kernel]]
void pathEmsIntegrator(uint tid [[thread_position_in_grid]],
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
                       constant float & totalArea
                       ) {
    if (tid >= rayCount)
        return;
    device Ray & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    device Ray & shadowRay = shadowRays[tid];
    constant Intersection & shadowTest = shadowTests[tid];
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case WAITING: { ray.state = FINISHED; }
        case FINISHED: {
            if (shadowRay.expected > 0 && shadowTest.t < INFINITY && (abs(shadowTest.t - shadowRay.expected) < 1e-4)) {
                float3 emission = getEmission(matTypes[shadowTest.materialId], materials);
                ray.result += emission * shadowRay.throughput;
            }
            return;
        }
        case TRACING: {
            if (dot(-ray.direction, intersection.n) > 0) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput;
            }
            
            Out out = smat(ray, intersection, sampler, matTypes, materials);
            
            ray.throughput *= out.sample;
            
            ray.origin = intersection.p;
            
            ray.state = OLD;
            ray.direction = out.dir;
            ray.eta *= out.eta;
            
            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea);
            
            return;
        }
        case OLD: {
            if (shadowTest.t < INFINITY && (abs(shadowTest.t - shadowRay.expected) < 1e-4)) {
                float3 emission = getEmission(matTypes[shadowTest.materialId], materials);
                ray.result += emission * shadowRay.throughput;
            } else if (shadowRay.expected == -1) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput * max(0.f, -dot(ray.direction, intersection.n));
            }
            
            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                shadowRay.state = FINISHED;
                shadowRay.expected = -1;
                return;
            }
            
            Out out = smat(ray, intersection, sampler, matTypes, materials);
            
            ray.throughput *= out.sample;
            ray.origin = intersection.p;
            
            generateShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea);
            
            ray.direction = out.dir;
            ray.eta *= out.eta;
        }
    }
}
