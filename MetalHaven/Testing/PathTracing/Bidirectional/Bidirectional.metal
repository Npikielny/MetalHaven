//
//  Bidirectional.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/21/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"
//
//struct PathSection {
//    Ray ray;
//    Intersection intersection;
//};
//
//PathSection matSample(Ray in, Intersection intersection, constant char * materials, constant MaterialDescription * matTypes, constant char * scene, constant GeometryType * types, constant uint & objectCount, device HaltonSampler & sampler) {
//    in.origin = intersection.p;
//    float3 dir = sampleCosineHemisphere(generateVec(sampler));
//    in.direction = toFrame(dir, intersection.frame);
//    in.origin += in.direction * 1e-4;
//    Intersection next = trace(in, scene, types, objectCount);
//    MaterialDescription mat = matTypes[next.materialId];
//    in.result += in.throughput * getEmission(mat, materials);
//    in.throughput *= getReflectance(mat, materials);
//    
//    PathSection p;
//    p.ray = in;
//    p.intersection = next;
//    return p;
//};

[[kernel]]
void bidirectional(uint tid [[thread_position_in_grid]],
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
             device bool & indicator) {
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED)
        return;
    device HaltonSampler & sampler = samplers[tid];
    // path mats
    Intersection intersection = trace(ray, scene, types, objectCount);
    if (intersection.t == INFINITY)
        return;
    MaterialDescription mat = matTypes[intersection.materialId];
    ray.result = getEmission(mat, materials);
    ray.throughput *= getReflectance(mat, materials) * abs(dot(intersection.n, ray.direction));
    ray.origin = intersection.p;
    ray.result += ray.throughput * 0.1;
    
//    thread float && sample = generateSample(sampler);
//    uint lightIndex = sampleLuminarySet(lights, totalArea, sample);
//    AreaLight light = lights[lightIndex];
//    thread float3 && n = 0.;
//    float3 l = sampleLuminary(light, sampler, scene, types, n);
//    
//    float3 dir = normalize(l - ray.origin);
//    Intersection shadow = trace(createRay(ray.origin + dir * 1e-4, dir), scene, types, objectCount);
//    if (abs(shadow.t - distance(ray.origin, l)) < 1e-4) {
//        ray.throughput *= max(dot(intersection.n, dir), 0.f);
//        ray.result += ray.throughput * light.color / shadow.t / shadow.t;
//    }
//    
//    PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
//    ray = p.ray;
    ray.state = FINISHED;
}


//void bidirectional(uint tid [[thread_position_in_grid]],
//             device Ray * rays,
//             constant uint & rayCount,
//             device Intersection * intersections,
//             constant char * materials,
//             constant MaterialDescription * matTypes,
//             constant char * scene,
//             constant GeometryType * types,
//             constant uint & objectCount,
//             device HaltonSampler * samplers,
//             constant AreaLight * lights,
//             constant float & totalArea,
//             device bool & indicator) {
//    device Ray & ray = rays[tid];
//    if (ray.state == FINISHED)
//        return;
//    device HaltonSampler & sampler = samplers[tid];
//    // path mats
//    Intersection intersection = trace(ray, scene, types, objectCount);
//    if (intersection.t == INFINITY)
//        return;
//    MaterialDescription mat = matTypes[intersection.materialId];
//    ray.result = getEmission(mat, materials);
//    ray.throughput *= getReflectance(mat, materials);
//    ray.origin = intersection.p;
//    
//    thread float && sample = generateSample(sampler);
//    uint lightIndex = sampleLuminarySet(lights, totalArea, sample);
//    AreaLight light = lights[lightIndex];
//    thread float3 && n = 0.;
//    float3 l = sampleLuminary(light, sampler, scene, types, n);
//    ray.throughput *= totalArea;
//
//    float3 dir = sampleSphere(generateVec(sampler));
//    if (dot(dir, n) < 0)
//        return;
//    ray.throughput /= spherePdf(dir);
//    
//    Ray lightRay = createRay(l + dir * 1e-4, dir);
//    ray.throughput *= abs(dot(dir, n));
//    Intersection lightIntersection = trace(lightRay, scene, types, objectCount);
//    if (lightIntersection.t == INFINITY)
//        return;
//    ray.throughput *= getReflectance(matTypes[lightIntersection.materialId], materials) * abs(dot(lightIntersection.n, lightRay.direction)) / (lightIntersection.t * lightIntersection.t);
//    
//    float3 intDiff = lightIntersection.p - intersection.p;
//    bool isValid = dot(ray.direction, intersection.n) * dot(intDiff, intersection.n) > 0;
//    if (isValid) {
//        return;
//    }
//    ray.direction = normalize(intDiff);
//    ray.origin += ray.direction * 1e-4;
//    Intersection shadowTest = trace(ray, scene, types, objectCount);
//    if (abs(shadowTest.t - length(intDiff)) < 1e-3) {
//        intDiff = normalize(intDiff);
//        ray.throughput *= abs(dot(intersection.n, intDiff) * dot(intDiff, lightIntersection.n));
//        ray.throughput /= shadowTest.t / shadowTest.t / lightIntersection.t / lightIntersection.t;
//        
//        ray.result += ray.throughput * light.color;
//    }
//    
//    ray.state = FINISHED;
//}

