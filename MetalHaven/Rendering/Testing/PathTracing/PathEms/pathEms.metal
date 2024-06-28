//
//  pathEms.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/25/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

[[kernel]]
void pathEms(uint tid [[thread_position_in_grid]],
             device ShadingRay * rays,
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
             device bool & indicator
             ) {
    if (tid >= rayCount)
        return;
    
    device ShadingRay & ray = rays[tid];
    device Intersection & intersection = intersections[tid];
    
    switch (ray.state) {
        case WAITING: { ray.state = FINISHED; }
        case FINISHED: { return; }
        case TRACING: {
            intersection = trace(ray.ray, scene, types, objectCount);
            if (intersection.t == INFINITY) {
                ray.state = FINISHED;
                return;
            } else {
                float cos = -dot(ray.ray.direction, intersection.n);
                ray.result += ray.throughput * getEmission(matTypes[intersection.materialId], materials) * max(0.f, cos);
                ray.throughput *= abs(cos) * getReflectance(matTypes[intersection.materialId], materials);
                ray.state = OLD;
            }
            break;
        }
        case OLD: {
            device HaltonSampler & sampler = samplers[tid];
            thread float3 && n = 0.;
            PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
            if (p.bsdf == SOLID_ANGLE) {
                LuminarySample l = sampleLuminaries(lights, totalArea, sampler, scene, types);
                float3 dir = normalize(l.p - intersection.p);
                if (dot(-ray.ray.direction, intersection.n) * dot(dir, intersection.n) > 0 && dot(-dir, n) > 0) {
                    ShadingRay shadowRay = createShadingRay(intersection.p + dir * 1e-4, dir);
                    Intersection shadow = trace(shadowRay.ray, scene, types, objectCount);
                    if (abs(shadow.t - distance(shadowRay.ray.origin, l.p)) < 1e-4) {
                        float attenuation = max(0.f, -dot(dir, n)) * abs(dot(intersection.n, dir)) / shadow.t / shadow.t;
                        ray.result += ray.throughput * getEmission(matTypes[shadow.materialId], materials) * totalArea * attenuation;
                    }
                }
            } else {
                ray.result += p.result;
            }
            ray.throughput *= p.throughput;
            intersection = p.intersection;
            ray.ray.direction = p.direction;
        }
    }
    indicator = true;
}

//// MIS
//[[kernel]]
//void pathEms(uint tid [[thread_position_in_grid]],
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
//             device bool & indicator
//             ) {
//    if (tid >= rayCount)
//        return;
//    
//    device Ray & ray = rays[tid];
//    device Intersection & intersection = intersections[tid];
//    
//    switch (ray.state) {
//        case FINISHED: { return; }
//        case TRACING: {
//            intersection = trace(ray, scene, types, objectCount);
//            if (intersection.t == INFINITY) {
//                ray.state = FINISHED;
//                return;
//            } else {
//                float cos = -dot(ray.direction, intersection.n);
//                ray.result += ray.throughput * getEmission(matTypes[intersection.materialId], materials) * max(0.f, cos);
//                ray.throughput *= abs(cos) * getReflectance(matTypes[intersection.materialId], materials);
//                ray.state = OLD;
//            }
//            break;
//        }
//        case OLD: {
//            device HaltonSampler & sampler = samplers[tid];
//            thread float3 && n = 0.;
//            PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
//            if (p.bsdf == SOLID_ANGLE) {
//                float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//                float3 dir = normalize(l - intersection.p);
//                if (dot(-ray.direction, intersection.n) * dot(dir, intersection.n) > 0 && dot(-dir, n) > 0) {
//                    Ray shadowRay = createRay(intersection.p + dir * 1e-4, dir);
//                    Intersection shadow = trace(shadowRay, scene, types, objectCount);
//                    if (abs(shadow.t - distance(shadowRay.origin, l)) < 1e-4 * 2) {
//                        //                     BSDF prob
//                        float bsdfProb = max(0.f, cosineHemispherePdf(vector_float3(dot(intersection.frame.right, dir),
//                                                                                    dot(intersection.frame.up, dir),
//                                                                                    dot(intersection.frame.forward, dir)
//                                                                                    )));
//                        float attenuation = max(0.f, -dot(dir, n)) * abs(dot(intersection.n, dir)) / shadow.t / shadow.t;
//                        float emsProb = attenuation / totalArea;
//                        float mis = emsProb / (emsProb + bsdfProb);
//                        ray.result += ray.throughput * getEmission(matTypes[shadow.materialId], materials) * totalArea * attenuation * mis;
//                    }
//                }
//            }
//            
//            intersection = p.intersection;
//            ray.throughput *= p.throughput;
//            ray.direction = p.direction;
//            ray.eta *= p.eta;
//            if (ray.eta <= 0)
//                ray.eta = 1;
//            float mis = p.pdf / (p.pdf + (p.bsdf == SOLID_ANGLE ? 1 / totalArea : 0));
//            ray.result += p.result * mis;
//            
//            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99);
//            if (generateSample(sampler) < cont) {
//                ray.throughput /= cont;
//            } else {
//                ray.state = FINISHED;
//                return;
//            }
//        }
//    }
//    indicator = true;
//}

//[[kernel]]
//void pathEms(uint tid [[thread_position_in_grid]],
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
//             device bool & indicator
//             ) {
//    if (tid >= rayCount)
//        return;
//    
//    device Ray & ray = rays[tid];
//    device Intersection & intersection = intersections[tid];
//    
//    switch (ray.state) {
//        case FINISHED: { return; }
//        case TRACING: {
//            intersection = trace(ray, scene, types, objectCount);
//            if (intersection.t == INFINITY) {
//                ray.state = FINISHED;
//                return;
//            } else {
//                ray.throughput *= abs(dot(ray.direction, intersection.n)) * getReflectance(matTypes[intersection.materialId], materials);
//                ray.state = OLD;
//            }
//            break;
//        }
//        case OLD: {
//            device HaltonSampler & sampler = samplers[tid];
//            thread float3 && n = 0.;
////            thread float && sample = generateSample(sampler);
//            float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//            float3 dir = normalize(l - intersection.p);
//            Ray shadowRay = createRay(intersection.p + dir * 1e-4, dir);
//            Intersection shadow = trace(shadowRay, scene, types, objectCount);
//            if (abs(shadow.t - distance(shadowRay.origin, l)) < 1e-4 * 2) {
//                ray.result += ray.throughput * getEmission(matTypes[shadow.materialId], materials) * totalArea / (shadow.t * shadow.t) * max(0.f, -dot(dir, n)) / (shadow.t * shadow.t);
////                ray.result += ray.throughput * getEmission(matTypes[shadow.materialId], materials) / shadow.t / shadow.t * totalArea * abs(dot(dir, n));
//            }
//            
//            PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
//            intersection = p.intersection;
//            ray.throughput *= p.throughput;
////            ray.state = FINISHED;
////            ray.result += p.result;
//        }
//    }
//    indicator = true;
//}
