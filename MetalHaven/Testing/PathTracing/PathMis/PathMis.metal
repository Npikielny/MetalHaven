//
//  PathMis.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

struct PathSection {
    Ray ray;
    Intersection intersection;
    float pdf;
};

PathSection matSample(Ray in, Intersection intersection, constant char * materials, constant MaterialDescription * matTypes, constant char * scene, constant GeometryType * types, constant uint & objectCount, device HaltonSampler & sampler) {
    in.origin = intersection.p;
    float3 dir = sampleCosineHemisphere(generateVec(sampler));
    in.direction = toFrame(dir, intersection.frame);
    in.origin += in.direction * 1e-4;
    Intersection next = trace(in, scene, types, objectCount);
    MaterialDescription mat = matTypes[next.materialId];
    in.result += in.throughput * getEmission(mat, materials);
    in.throughput *= getReflectance(mat, materials);
    
    PathSection p;
    p.ray = in;
    p.intersection = next;
    p.pdf = cosineHemispherePdf(dir);
    return p;
};

[[kernel]]
void pathMis(uint tid [[thread_position_in_grid]],
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
             device bool & indicator
             ) {
    if (tid >= rayCount)
        return;
    
    device Ray & ray = rays[tid];
    device Intersection & intersection = intersections[tid];
    device HaltonSampler & sampler = samplers[tid];
    thread float3 && n = 0.;
    switch (ray.state) {
        case FINISHED: { return; }
        case TRACING: {
            intersection = trace(ray, scene, types, objectCount);
            if (intersection.t == INFINITY) {
                ray.state = FINISHED;
                return;
            }
            
            MaterialDescription desc = matTypes[intersection.materialId];
            ray.result += getEmission(desc, materials) * ray.throughput;
            ray.throughput *= getReflectance(desc, materials) * abs(dot(-ray.direction, intersection.n));
            if (matTypes[intersection.materialId].type == MIRROR) {
                ray.direction = reflect(ray.direction, intersection.n);
                ray.origin = intersection.p + ray.direction * 1e-4;
                ray.state = TRACING;
                break;
            } else {
                ray.state = OLD;
            }
        }
        case OLD: {
            // MARK: - MATS
            float2 sample = generateVec(sampler);
            float3 dir = sampleCosineHemisphere(sample);
            
            ray.direction = toFrame(dir, intersection.frame);
//            float cos = abs(dot(ray.direction, intersection.n));
            ray.origin = intersection.p + ray.direction * 1e-4;
            ray.throughput *= abs(dot(ray.direction, intersection.n));
//            ray.result += (ray.direction * 0.5 + 0.5) * 0.01;// * ray.throughput;
            
            Intersection next = trace(ray, scene, types, objectCount);
            if (matTypes[next.materialId].type == MIRROR) {
                ray.direction = reflect(ray.direction, intersection.n);
                ray.origin = intersection.p + ray.direction * 1e-4;
                ray.state = TRACING;
                break;
            }
            BasicMaterial nextMat = *(constant BasicMaterial *)(materials + matTypes[next.materialId].index);
            float3 matResult = nextMat.emission * ray.throughput;// * cos;
            float matPdf = cosineHemispherePdf(dir);
            float invArea = 1 / totalArea;
            if (length(nextMat.emission) > 0) {
                matPdf = matPdf / (matPdf + invArea * next.t * next.t / abs(dot(next.n, ray.direction)));
                ray.result += matResult * matPdf;
            }
            
            // MARK: - EMS
            float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
            float3 lumDir = normalize(l - intersection.p);
            Ray luminaryRay = createRay(intersection.p + lumDir * 1e-4, lumDir);
            bool isValid = dot(ray.direction, intersection.n) * dot(lumDir, intersection.n) > 0; // makes sure we're not doing a luminary sample that passes through the surface
            Intersection shadowTest = trace(luminaryRay, scene, types, objectCount);
            if (isValid && abs(distance(luminaryRay.origin, l) - abs(shadowTest.t)) < 1e-4)  {
                float3 emsResult = ray.throughput * getEmission(matTypes[shadowTest.materialId], materials) * abscos(luminaryRay.direction, intersection.n) * abscos(luminaryRay.direction, n) / (shadowTest.t * shadowTest.t) * totalArea;
                
                
                float3 pt = float3(dot(intersection.frame.right, luminaryRay.direction),
                                   dot(intersection.frame.forward, luminaryRay.direction),
                                   dot(intersection.frame.up, luminaryRay.direction));
                
                
                float emsPdf = invArea * abscos(luminaryRay.direction, intersection.n) / shadowTest.t / shadowTest.t;
                emsPdf = emsPdf / (emsPdf + cosineHemispherePdf(pt));
                ray.result += emsResult * emsPdf;
            }
            
            ray.throughput *= nextMat.albedo; //* matPdf;// * cos;
            intersection = next;
            
            if (ray.state == OLD) {
                float cont = min(maxComponent(ray.throughput), 0.99);
                if (generateSample(sampler) > cont) {
                    ray.state = FINISHED;
                    return;
                } else {
                    ray.throughput /= cont;
                }
            }
        }
            break;
    }
    indicator = true;
}
