//
//  Bidir.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/13/24.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

float sampleRay(device Ray & ray, constant Intersection & intersection, device HaltonSampler & sampler, constant MaterialDescription * matTypes, constant char * materials) {
    auto next = sampleBSDF(ray, intersection, sampler, matTypes, materials);
    ray.direction = next.dir;
    ray.origin = intersection.p;
    ray.throughput *= next.sample;
    return next.pdf;
}

bool roulette(device Ray & ray, device HaltonSampler & sampler) {
    float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
    if (generateSample(sampler) > cont) {
        ray.state = WAITING;
        return true;
    }
    ray.throughput /= cont;
    return false;
}

[[kernel]]
void bidir(uint tid [[thread_position_in_grid]],
           constant uint & rayCount,
           device Ray * rays,
           constant Intersection * intersections,
           device Ray * emitterRays,
           constant Intersection * emitterIntersections,
           device Ray * shadowRays,
           constant Intersection * shadowTests,
           constant char * scene,
           constant GeometryType * types,
           constant MaterialDescription * matTypes,
           constant char * materials,
           device HaltonSampler * samplers,
           constant AreaLight * lights,
           constant float & totalArea) {
    if (tid >= rayCount)
        return;
    device Ray & ray = rays[tid];
    constant Intersection & intersection = intersections[tid];
    device Ray & emitterRay = emitterRays[tid];
    constant Intersection & emitterIntersection = emitterIntersections[tid];
    device Ray & shadowRay = shadowRays[tid];
    constant Intersection & shadowTest = shadowTests[tid];
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case WAITING: {
            ray.state = FINISHED;
            if (shadowRay.expected > 0 && shadowTest.t >= shadowRay.expected - 1e-4) {
                ray.result += shadowRay.result;
            }
            return;
        }
        case FINISHED: {
            return;
        }
        case OLD: {
            float3 emission = getEmission(matTypes[intersection.materialId], materials);
            ray.result += emission * ray.mis * ray.throughput * max(0.f, dot(-ray.direction, intersection.n));
            if (shadowRay.expected > 0 && shadowTest.t >= shadowRay.expected - 1e-4) {
                ray.result += shadowRay.result;
            }
            sampleRay(emitterRay, emitterIntersection, sampler, matTypes, materials);
            sampleRay(ray, intersection, sampler, matTypes, materials);
            ray.expected = matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE ? -1 : 0;
            emitterRay.expected = matSamplingStrategy(matTypes[emitterIntersection.materialId].type) == DISCRETE ? -1 : 0;
            if (ray.expected == 0 && emitterRay.expected == 0) {
                float3 dir = emitterIntersection.p - intersection.p;
                float d = length(dir);
                dir /= d;
                float pdf = cosineHemispherePdf(vector_float3(dot(dir, intersection.frame.right),
                                                              dot(dir, intersection.frame.up),
                                                              dot(dir, intersection.frame.forward)
                                                              ));
                if (pdf > 0) {
                    //                float mis = pdf / pdf + (1 / totalArea);
                    shadowRay.result = ray.throughput * emitterRay.throughput * max(0.f, dot(dir, intersection.n)) * max(0.f, dot(-dir, emitterIntersection.n)) / (pdf == 0 ? 1 : pdf);
                    shadowRay.origin = intersection.p;
                    shadowRay.direction = dir;
                    shadowRay.expected = d;
                } else {
                    shadowRay.expected = -1;
                }
            }
            roulette(ray, sampler);
            break;
        }
        case TRACING: {
            float3 emission = getEmission(matTypes[intersection.materialId], materials);
            if (length(emission) > 0) {
                ray.result = emission;
                ray.state = FINISHED;
                return;
            }
            LuminarySample l = sampleLuminaries(lights, totalArea, sampler, scene, types);
            // will need to change to frame to change dirs!
            emitterRay = createRay(l.p, l.n);
            emitterRay.throughput *= totalArea;
            emitterRay.result = lights[0].color;
            
            ray.state = OLD;
            sampleRay(ray, intersection, sampler, matTypes, materials);
//            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE ? 1 : pdf / (pdf + 1 / totalArea);
            
            if (matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE) {
                float3 dir = l.p - intersection.p;
                float d = length(dir);
                dir /= d;
                float pdf = cosineHemispherePdf(vector_float3(dot(dir, intersection.frame.right),
                                                              dot(dir, intersection.frame.up),
                                                              dot(dir, intersection.frame.forward)
                                                              ));
                if (pdf > 0) {
                    //                float mis = pdf / pdf + (1 / totalArea);
                    shadowRay.result = ray.throughput * emitterRay.throughput * max(0.f, dot(dir, intersection.n)) * max(0.f, dot(-dir, l.n)) / (pdf == 0 ? 1 : pdf);
                    shadowRay.origin = intersection.p;
                    shadowRay.direction = dir;
                    shadowRay.expected = d;
                } else {
                    shadowRay.expected = -1;
                }
            } else {
                ray.mis = 1;
                shadowRay.expected = -1;
            }
            
            
            break;
        }
    }

}

