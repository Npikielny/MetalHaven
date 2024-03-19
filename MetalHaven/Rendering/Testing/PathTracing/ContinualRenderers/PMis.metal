//
//  PMis.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/21/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"


void generateMISShadowRay(Ray ray,
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
        float visibility = max(0.f, dot(-dir, l.n));
//        bool crossedSurface = dot(-ray.direction, intersection.n) * dot(dir, intersection.n) < 0;
        bool crossedSurface = dot(dir, intersection.n) < 0;
        if (visibility <= 0 || crossedSurface) {
            shadowRay.expected = -2;
            shadowRay.state = FINISHED;
            return;
        }
        shadowRay.origin = intersection.p;
        shadowRay.direction = dir;
        float dist = distance(intersection.p, l.p);
        shadowRay.expected = dist;
        float attenuation = visibility * abs(dot(dir, intersection.n)) / (dist * dist);
        shadowRay.throughput = ray.throughput * attenuation * totalArea;
        shadowRay.state = TRACING;
        float ePdf = attenuation / totalArea;
        float bPdf = cosineHemispherePdf(float3(dot(intersection.frame.right, dir),
                                                dot(intersection.frame.up, dir),
                                                dot(intersection.frame.forward, dir)));
        shadowRay.throughput *= ePdf / (ePdf + bPdf);
    } else {
        shadowRay.expected = -1;
        shadowRay.state = FINISHED;
    }
}

[[kernel]]
void pathMisIntegrator(uint tid [[thread_position_in_grid]],
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
            shadowRay.state = FINISHED;
            shadowRay.expected = -INFINITY;
            return;
        }
        case TRACING: {
            if (dot(-ray.direction, intersection.n) > 0) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput;
            }
            
            Out out = smat(ray, intersection, sampler, matTypes, materials);
            
            ray.throughput *= out.sample;
            ray.mis = out.pdf / (out.pdf + 1 / totalArea);
            
            ray.origin = intersection.p;
            
            ray.state = OLD;
            ray.direction = out.dir;
            ray.eta *= out.eta;
            
            generateMISShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea);
            
            return;
        }
        case OLD: {
            if (shadowTest.t < INFINITY && (abs(shadowTest.t - shadowRay.expected) < 1e-4)) {
                float3 emission = getEmission(matTypes[shadowTest.materialId], materials);
                ray.result += emission * shadowRay.throughput;
            }
            
            if (shadowRay.expected == -1) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput * max(0.f, dot(-ray.direction, intersection.n));
            } else {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += max(0.f, dot(-ray.direction, intersection.n)) * emission * ray.throughput * ray.mis;
            }
            
            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                shadowRay.state = FINISHED;
                shadowRay.expected = -INFINITY;
                return;
            }
            
            Out out = smat(ray, intersection, sampler, matTypes, materials);
            ray.mis = out.pdf / (out.pdf + 1 / totalArea);
            ray.throughput *= out.sample;
            ray.origin = intersection.p;
            
            generateMISShadowRay(ray, intersection, shadowRay, matTypes, scene, types, sampler, lights, totalArea);
            
            ray.direction = out.dir;
            ray.eta *= out.eta;
        }
    }
}
