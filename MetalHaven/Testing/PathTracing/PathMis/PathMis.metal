//
//  PathMis.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

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
            ray.throughput *= getReflectance(desc, materials) * abs(dot(-ray.direction, intersection.n));
            if (dot(-ray.direction, intersection.n) > 0) {
                ray.result += getEmission(desc, materials) * ray.throughput;
            }
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
            // MARK: - EMS
            float invArea = 1 / totalArea;
//            thread float && sample = generateSample(sampler);
//            uint index = sampleLuminarySet(lights, totalArea, sample);
//            AreaLight light = lights[index];
//            thread float3 && n = 0.;
//            float3 l = sampleLuminary(light, sampler, scene, types, n);
            float3 l = sampleLuminaries(lights, totalArea, sampler, scene, types, n);
            float3 lumDir = normalize(l - intersection.p);
            Ray luminaryRay = createRay(intersection.p + lumDir * 1e-4, lumDir);
            bool isValid = dot(-ray.direction, intersection.n) * dot(lumDir, intersection.n) > 0; // makes sure we're not doing a luminary sample that passes through the surface
//            bool isValid = true;
            Intersection shadowTest = trace(luminaryRay, scene, types, objectCount);
            if (isValid && -dot(lumDir, n) > 0 && abs(distance(luminaryRay.origin, l) - abs(shadowTest.t)) < 1e-4)  {
                float3 emsResult = ray.throughput * getEmission(matTypes[shadowTest.materialId], materials) * abscos(luminaryRay.direction, intersection.n) * abscos(luminaryRay.direction, n) / (shadowTest.t * shadowTest.t) * totalArea;
                
                
                float3 pt = float3(dot(intersection.frame.right, luminaryRay.direction),
                                   dot(intersection.frame.forward, luminaryRay.direction),
                                   dot(intersection.frame.up, luminaryRay.direction));
                
                
                float emsPdf = invArea * abscos(luminaryRay.direction, intersection.n) / shadowTest.t / shadowTest.t;
                emsPdf = emsPdf / (emsPdf + cosineHemispherePdf(pt));
                ray.result += emsResult * emsPdf;
            }
            
            // MARK: - MATS
            PathSection p = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, sampler);
            ray.throughput *= p.throughput;
            ray.direction = p.direction;
            ray.result += p.result * p.pdf / (p.pdf + invArea);
            intersection = p.intersection;

            float cont = min(maxComponent(ray.throughput), 0.99);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                return;
            } else {
                ray.throughput /= cont;
            }
        }
            break;
    }
    indicator = true;
}
