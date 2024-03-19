//
//  Bidirectional.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/21/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

bool isValid(float3 in, float3 n, float3 out) {
    return dot(-in, n) * dot(n, out) > 0;
}
//
//[[kernel]]
//void bidirectional(uint tid [[thread_position_in_grid]],
//                   device Ray * rays,
//                   constant uint & rayCount,
//                   device Intersection * intersections,
//                   constant char * materials,
//                   constant MaterialDescription * matTypes,
//                   constant char * scene,
//                   constant GeometryType * types,
//                   constant uint & objectCount,
//                   device HaltonSampler * samplers,
//                   constant AreaLight * lights,
//                   constant float & totalArea,
//                   device bool & indicator) {
//    if (tid >= rayCount)
//        return;
//    
//    device Ray & ray = rays[tid];
//    if (ray.state == FINISHED)
//        return;
//    
//    Intersection first = trace(ray, scene, types, objectCount);
//    if (first.t == INFINITY)
//        return;
//    auto desc = matTypes[first.materialId];
//    float3 emission = getEmission(desc, materials);
//    if (length(emission) > 0) {
//        ray.result = emission;
//        return;
//    }
//    ray.throughput *= getReflectance(desc, materials) * abs(dot(ray.direction, first.n));
//    
//    device HaltonSampler & sampler = samplers[tid];
//    thread float3 && n = 0.;
//    float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//    ray.throughput *= totalArea;
//
//    float3 dir = sampleSphere(generateVec(sampler));
//    if (dot(dir, n) <= 0)
//        return;
//    Intersection bounce = trace(createRay(l + dir * 1e-4, dir), scene, types, objectCount);
//    ray.throughput *= abs(dot(n, dir)) / bounce.t / bounce.t * getReflectance(matTypes[bounce.materialId], materials);
//    
//    float3 connection = normalize(bounce.p - first.p);
//    
//    Ray shadowRay = createRay(first.p + connection * 1e-4, connection);
//    Intersection shadowTest = trace(shadowRay, scene, types, objectCount);
//    if (abs(distance(l, shadowRay.origin) - shadowTest.t) < 1e-4) {
//        ray.throughput *= abs(dot(connection, first.n)) * max(0.f, dot(-connection, n)) / (shadowTest.t * shadowTest.t);
//        ray.result += ray.throughput * getEmission(matTypes[shadowTest.materialId], materials);
//    }
//    
////    float3 dir = sampleSphere(generateVec(sampler));
////    if (dot(dir, n) < 0)
////        return;
////    
////    Intersection firstLight = trace(createRay(l + dir * 1e-4, dir), scene, types, objectCount);
////    ray.throughput *= totalArea * spherePdf(dir) / (firstLight.t * firstLight.t) * abs(dot(dir, firstLight.n));
////    
////    float3 connection = firstLight.p - first.p;
////    float d = length(connection);
////    connection /= d;
////    ray.throughput /= d * d * abs(dot(connection, firstLight.n) * dot(connection, first.n));
////    
////    ray.result += ray.throughput * light.color;
//    
////    device HaltonSampler & sampler = samplers[tid];
//}

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
    if (tid >= rayCount)
        return;
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
//    ray.throughput /= (intersection.t * intersection.t);
    
//    PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
//    ray.throughput *= p.throughput;
//    ray.direction = p.direction;
//    intersection = p.intersection;
    
    thread float && sample = generateSample(sampler);
    uint lightIndex = sampleLuminarySet(lights, totalArea, sample);
    AreaLight light = lights[lightIndex];
//    thread float3 && n = 0.;
//    float3 l = sampleLuminary(light, sampler, scene, types, n);
    LuminarySample l = sampleLuminary(light, sampler, scene, types);
    ray.throughput *= totalArea;
    
    float3 dir = sampleSphere(generateVec(sampler));
    ray.throughput /= spherePdf(dir);
    if (dot(dir, l.n) < 0.1)
        return;
    
//    Intersection lightBounce = trace(createRay(l + dir * 1e-4, dir), scene, types, objectCount);
//    ray.throughput *= max(0.f, dot(dir, n));// / lightBounce.t / lightBounce.t;
//    
//    float3 connection = normalize(lightBounce.p - intersection.p);
//    ray.throughput *= abs(dot(connection, intersection.n) * dot(connection, lightBounce.n));
//    
//    Ray shadowRay = createRay(intersection.p + connection * 1e-4, connection);
//    Intersection shadow = trace(shadowRay, scene, types, objectCount);
//    if (abs(shadow.t - distance(shadowRay.origin, lightBounce.t)) < 1e-4 * 4) {
//        ray.result += light.color * ray.throughput;// / shadow.t / shadow.t;
//    }
    
    Intersection first = trace(createRay(l.p + dir * 1e-4, dir), scene, types, objectCount);
    ray.throughput *= max(dot(dir, l.n), 0.f) * abs(dot(dir, first.n)) / (first.t * first.t);
    
    float3 connect = normalize(first.p - intersection.p);
    if (isValid(ray.direction, intersection.n, connect) && isValid(dir, first.n, -connect)) {
        ray.direction = connect;
        ray.origin += connect * 1e-4;
        Intersection shadow = trace(ray, scene, types, objectCount);
        if (abs(shadow.t - distance(ray.origin, first.p)) < 1e-4) {
            ray.throughput *= abs(dot(connect, intersection.n) * dot(connect, first.n)) / (shadow.t * shadow.t);

            ray.result += light.color * ray.throughput;
        }
    }
    ray.state = FINISHED;
}

//[[kernel]]
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

