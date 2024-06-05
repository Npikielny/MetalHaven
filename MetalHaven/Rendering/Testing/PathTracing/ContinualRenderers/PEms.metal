//
//  PEms.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/25/24.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

void sampleShadowRay(Ray ray,
                  Intersection intersection,
                  device Ray & shadowRay,
                  constant MaterialDescription * matTypes,
                  constant char * scene,
                  constant GeometryType * types,
                  device HaltonSampler & sampler,
                  constant AreaLight * lights,
                  constant float & totalArea,
                  bool mis
                  ) {
    if (matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE) {
        LuminarySample l = sampleLuminaries(lights, totalArea, sampler, scene, types);
        float3 dir = (l.p - intersection.p);
        float d = length(dir);
        dir /= d;
        
        float attenuation = abs(dot(dir, intersection.n)) * max(0.f, dot(-dir, l.n));
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
        shadowRay.result = l.emission * attenuation * ray.throughput * totalArea;
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

void addShadowRay(device Ray & ray, Ray shadowRay, Intersection shadowTest) {
    if (abs(shadowTest.t - shadowRay.expected) <= 1e-4) {
        ray.result += shadowRay.result * shadowRay.mis;
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
        case WAITING: {
            addShadowRay(ray, shadowRay, shadowTest);
            ray.state = FINISHED;
        }
        case FINISHED: { return; }
        case TRACING: {
            if (dot(-ray.direction, intersection.n) > 0) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput;
            }
            
            MaterialSample o = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= o.sample;
            sampleShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea, false);
//            auto L = sampleLuminaries(lights, totalArea, sampler, scene, types);
//            float3 dir = normalize(L.p - intersection.p);
//            float3 n = normalize(L.p - vector_float3(1 - 0.1,  1.6 - 0.1 - 0.05, -1 + 0.1));
//            float attenuation = abs(dot(dir, intersection.n)) * abs(dot(-dir, n));// * max(0.f, dot(-dir, L.n));
//            ray.result += L.emission * ray.throughput * attenuation;
            
            ray.direction = o.dir;
            ray.eta *= o.eta;
            ray.origin = intersection.p;
            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE ? 1 : 0;
            ray.state = OLD;
            return;
        }
        case OLD: {
            float3 emission = max(0.f, -dot(ray.direction, intersection.n)) * getEmission(matTypes[intersection.materialId], materials);
            ray.result += emission * ray.throughput * ray.mis;
            addShadowRay(ray, shadowRay, shadowTest);
            
            if (roulette(ray, sampler))
                return;
            
//            auto L = sampleLuminaries(lights, totalArea, sampler, scene, types);
//            float3 dir = normalize(L.p - intersection.p);
//            float attenuation = abs(dot(dir, intersection.n)) * max(0.f, dot(-dir, L.n));
//            ray.result += L.emission * ray.throughput * attenuation;
            
            MaterialSample o = sampleBSDF(ray, intersection, sampler, matTypes, materials);
            ray.throughput *= o.sample;
            sampleShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea, false);
            ray.direction = o.dir;
            ray.eta *= o.eta;
            ray.origin = intersection.p;
            ray.mis = matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE ? 1 : 0;
            
        }
    }
}
