//
//  PMats.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/25/24.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

void sampleMat(device Ray & ray, Intersection intersection, device HaltonSampler & sampler, constant MaterialDescription * matTypes, constant char * mats) {
    MaterialDescription type = matTypes[intersection.materialId];
    float cos = dot(-ray.direction, intersection.n);
    if (cos > 0) {
        ray.result += getEmission(type, mats) * ray.throughput;
    }
    ray.throughput *= abs(cos) * getReflectance(type, mats);
    
//    float3 dir = sampleUniformHemisphere(generateVec(sampler));
    float3 dir = sampleCosineHemisphere(generateVec(sampler));
    float3 next = toWorld(dir, intersection.frame);
//    ray.direction = dot(next, intersection.n) * dot(-ray.direction, intersection.n) > 0 ? next : -next;
    ray.direction = next;
//    ray.throughput *= abs(dot(intersection.n, ray.direction)) / uniformHemispherePdf(dir);
    ray.origin = intersection.p;
}

Out smat(Ray ray, Intersection intersection, device HaltonSampler & sampler, constant MaterialDescription * matTypes, constant char * mats) {
    MaterialDescription desc = matTypes[intersection.materialId];
    Out o;
    o.eta = 1;
    switch (desc.type) {
        case MIRROR: {
            o.sample = 1.;
            o.dir = reflect(ray.direction, intersection.n);
            o.pdf = 1;
            break;
        }
        case DIELECTRIC: {
            Dielectric mat = *(constant Dielectric *)(mats + desc.index);
            float c = dot(-ray.direction, intersection.n);
            float f = fresnel(c, 1.000277f, mat.IOR);
            bool entering = dot(ray.direction, intersection.n) < 0;
            float eta1 = entering ? 1.000277f : mat.IOR;
            float eta2 = entering ? mat.IOR : 1.000277f;
            
            if (generateSample(sampler) < f) {
                // reflect
                o.dir = reflect(ray.direction, intersection.n);
                o.sample = 1;
            } else {
                // refract
                float eta = (eta1 / eta2);
                o.dir = refract(ray.direction, intersection.n * (entering ? 1 : -1), eta);
                o.eta /= eta;
                o.sample = mat.reflectance;
            }
            o.pdf = 1;
            break;
        }
        case MICROFACET: {}
        case BASIC: {
            float3 dir = sampleCosineHemisphere(generateVec(sampler));
            o.dir = toWorld(dir,
                            intersection.frame);
            o.sample = getReflectance(desc, mats);
            o.pdf = cosineHemispherePdf(dir);
            break;
        }
        
    }
    return o;
}

[[kernel]]
void pathMatsIntegrator(uint tid [[thread_position_in_grid]],
                        constant uint & rayCount,
                        device Ray * rays,
                        constant Intersection * intersections,
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
    device HaltonSampler & sampler = samplers[tid];
    switch (ray.state) {
        case WAITING: { ray.state = FINISHED; }
        case FINISHED: { return; }
        case TRACING: {
            if (dot(-ray.direction, intersection.n) > 0) {
                float3 emission = getEmission(matTypes[intersection.materialId], materials);
                ray.result += emission * ray.throughput;
            }
            
            Out o = smat(ray, intersection, sampler, matTypes, materials);
            ray.direction = o.dir;
            ray.throughput *= o.sample;
            ray.eta *= o.eta;
            ray.origin = intersection.p;
            
            ray.state = OLD;
            return;
        }
        case OLD: {
            float3 emission = max(0.f, -dot(ray.direction, intersection.n)) * getEmission(matTypes[intersection.materialId], materials);
            ray.result += emission * ray.throughput;
            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
            if (generateSample(sampler) > cont) {
                ray.state = FINISHED;
                return;
            }
            
            Out o = smat(ray, intersection, sampler, matTypes, materials);
            ray.direction = o.dir;
            ray.throughput *= o.sample / cont;
            ray.eta *= o.eta;
            ray.origin = intersection.p;
        }
    }
}
