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
        thread float3 && n = 0.;
        float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
        float3 dir = normalize(l - intersection.p);
        float visibility = max(0.f, dot(-dir, n));
        if (visibility <= 0) {
            shadowRay.expected = -1;
            shadowRay.state = FINISHED;
            return;
        }
        shadowRay.origin = intersection.p;
        shadowRay.direction = dir;
        float dist = distance(intersection.p, l);
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
        case FINISHED: { return; }
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


//
//[[kernel]]
//void pathMisIntegrator(uint tid [[thread_position_in_grid]],
//                       constant uint & rayCount,
//                       device Ray * rays,
//                       constant Intersection * intersections,
//                       device Ray * shadowRays,
//                       constant Intersection * shadowTests,
//                       constant char * scene,
//                       constant GeometryType * types,
//                       constant MaterialDescription * matTypes,
//                       constant char * materials,
//                       device HaltonSampler * samplers,
//                       constant AreaLight * lights,
//                       constant float & totalArea
//                       ) {
//    if (tid >= rayCount)
//        return;
//    device Ray & ray = rays[tid];
//    constant Intersection & intersection = intersections[tid];
//    device Ray & shadowRay = shadowRays[tid];
//    constant Intersection & shadowTest = shadowTests[tid];
//    device HaltonSampler & sampler = samplers[tid];
//    switch (ray.state) {
//        case FINISHED: { return; }
//        case TRACING: {
//            float3 emission = max(0.f, dot(-ray.direction, intersection.n)) * getEmission(matTypes[intersection.materialId], materials);
//            ray.result += emission * ray.throughput;
//            
//            ray.throughput *= getReflectance(matTypes[intersection.materialId], materials) * abs(dot(ray.direction, intersection.n));
//            ray.origin = intersection.p;
//            
//            ray.state = OLD;
//            
//            thread float3 && n = 0.;
//            float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//            float3 dir = normalize(l - intersection.p);
//            float visibility = max(dot(-dir, n), 0.f);
//            float dist = distance(l, intersection.p);
//            bool isValid = dot(dir, intersection.n) * dot(-ray.direction, intersection.n) > 0;
//            if (isValid && visibility > 0 && dist > 1e-4) {
//                shadowRay.origin = intersection.p;
//                shadowRay.direction = dir;
//                shadowRay.expected = dist;
//                shadowRay.throughput = ray.throughput * totalArea * visibility * abs(dot(intersection.n, dir)) / (dist * dist);
//                shadowRay.state = TRACING;
//            } else {
//                shadowRay.state = FINISHED;
//            }
//            ray.direction = toWorld(sampleCosineHemisphere(generateVec(sampler)), intersection.frame);
//            
//            return;
//        }
//        case OLD: {
//            if (shadowTest.t < INFINITY && abs(shadowTest.t - shadowRay.expected) < 1e-4) {
//                float3 emission = getEmission(matTypes[shadowTest.materialId], materials);
//                ray.result += emission * shadowRay.throughput;
//            }
//            
//            float cont = 0.99;
////            float cont = 0;min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
//            if (generateSample(sampler) > cont) {
//                ray.state = FINISHED;
//                shadowRay.state = FINISHED;
//                return;
//            }
//            
//            ray.throughput *= getReflectance(matTypes[intersection.materialId], materials) / cont;
//            ray.origin = intersection.p;
//            
//            thread float3 && n = 0.;
//            float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//            float3 dir = normalize(l - intersection.p);
//            float visibility = max(dot(-dir, n), 0.f);
//            float dist = distance(l, intersection.p);
//            bool isValid = dot(dir, intersection.n) * dot(-ray.direction, intersection.n) > 0;
//            if (isValid && visibility > 0 && dist > 1e-4) {
//                shadowRay.origin = intersection.p;
//                shadowRay.direction = dir;
//                shadowRay.expected = dist;
//                shadowRay.throughput = ray.throughput * totalArea * visibility * abs(dot(intersection.n, dir)) / (dist * dist);
//                shadowRay.state = TRACING;
//            } else {
//                shadowRay.state = FINISHED;
//            }
//            ray.direction = toWorld(sampleCosineHemisphere(generateVec(sampler)), intersection.frame);
//        }
//    }
//}
//
//
//
////
////[[kernel]]
////void pathMisIntegrator(uint tid [[thread_position_in_grid]],
////                       constant uint & rayCount,
////                       device Ray * rays,
////                       constant Intersection * intersections,
////                       device Ray * shadowRays,
////                       device Intersection * shadowTests,
////                       constant char * scene,
////                       constant GeometryType * types,
////                       constant MaterialDescription * matTypes,
////                       constant char * materials,
////                       device HaltonSampler * samplers,
////                       constant AreaLight * lights,
////                       constant float & totalArea
////                       ) {
////    if (tid >= rayCount)
////        return;
////    device Ray & ray = rays[tid];
////    constant Intersection & intersection = intersections[tid];
////    device HaltonSampler & sampler = samplers[tid];
////    switch (ray.state) {
////        case FINISHED: {
////            ray.result = float3(1, 0, 0);
////            return;
////        }
////        case TRACING: {
////            ray.result += max(0.f, -dot(ray.direction, intersection.n)) * getEmission(matTypes[intersection.materialId], materials) * ray.throughput;
////            ray.throughput *= getReflectance(matTypes[intersection.materialId], materials) * abs(dot(ray.direction, intersection.n));
////            
//////            thread float3 && n = 0.;
//////            float3 p = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
////            
//////            device Ray & shadowRay = shadowRays[tid];
//////            float3 dir = p - intersection.p;
//////            float l = length(dir);
//////            dir /= l;
//////            if (dot(dir, n) < 0 && dot(dir, intersection.n) * dot(-ray.direction, intersection.n) > 0) {
//////                shadowRay = createRay(intersection.p, dir);
//////                shadowRay.expected = l;
//////                
//////                float attentuation = abs(dot(dir, intersection.n)) / (l * l);
//////                
////////                float emsPdf = 1 / totalArea * attentuation;
////////                float3 wo = float3(dot(dir, intersection.frame.right),
////////                                   dot(dir, intersection.frame.up),
////////                                   dot(dir, intersection.frame.forward));
////////                float bsdfPdf = cosineHemispherePdf(wo);
////////                float misPdf = emsPdf / (bsdfPdf + emsPdf);
//////                
//////                shadowRay.throughput = ray.throughput * max(0.f, -dot(dir, n)) * totalArea * attentuation;
////////                shadowRay.mis = misPdf;
//////            } else {
//////                shadowRay.expected = -INFINITY;
//////                shadowRay.state = FINISHED;
//////            }
////            
////            
////            float3 wo = sampleCosineHemisphere(generateVec(sampler));
////            
////            float3 next = toWorld(wo, intersection.frame);
//////            float bpdf = cosineHemispherePdf(wo);
//////            ray.mis *= bpdf / (bpdf + 1 / totalArea);
////            ray.direction = next;
////            ray.origin = intersection.p;
////            ray.state = OLD;
////            
////            break;
////        }
////        case OLD: {
////            ray.result += max(0.f, -dot(ray.direction, intersection.n)) * getEmission(matTypes[intersection.materialId], materials) * ray.throughput * ray.mis;
////            
//////            Intersection shadowIntersection = shadowTests[tid];
//////            device Ray & shadowRay = shadowRays[tid];
//////            if (abs(shadowIntersection.t - shadowRay.expected) < 1e-4) {
//////                ray.result += getEmission(matTypes[shadowIntersection.materialId], materials) * shadowRay.throughput * shadowRay.mis;
//////            }
////            
//////            thread float3 && n = 0.;
//////            float3 p = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
//////            
//////            float3 dir = p - intersection.p;
//////            float l = length(dir);
//////            dir /= l;
//////            if (dot(dir, intersection.n) * dot(-ray.direction, intersection.n) > 0) {
//////                shadowRay = createRay(intersection.p, dir);
//////                shadowRay.expected = l;
//////                
//////                float attentuation = abs(dot(dir, intersection.n)) / (l * l);
//////                
////////                float emsPdf = 1 / totalArea * attentuation;
////////                float3 wo = float3(dot(dir, intersection.frame.right),
////////                                   dot(dir, intersection.frame.up),
////////                                   dot(dir, intersection.frame.forward));
////////                float bsdfPdf = cosineHemispherePdf(wo);
////////                float misPdf = emsPdf / (bsdfPdf + emsPdf);
//////                
//////                shadowRay.throughput = ray.throughput * max(0.f, -dot(dir, n)) * totalArea * attentuation;
//////                
////////                shadowRay.mis = misPdf;
//////            } else {
//////                shadowRay.expected = -INFINITY;
//////                shadowRay.state = FINISHED;
//////            }
//////            
////            
////            float3 wo = sampleCosineHemisphere(generateVec(sampler));
////            
////            float3 next = toWorld(wo, intersection.frame);
//////            float bpdf = cosineHemispherePdf(wo);
//////            ray.mis *= bpdf / (bpdf + 1 / totalArea);
////            ray.direction = next;
////            ray.origin = intersection.p;
////            ray.state = OLD;
////            
////            float cont = 0.95;
////            if (generateSample(sampler) > cont) {
////                ray.throughput /= cont;
//////                shadowRay.throughput /= cont;
////            } else {
////                ray.state = FINISHED;
//////                shadowRay.state = FINISHED;
////            }
////            return;
////        }
////    }
////}
