//
//  PathMats.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/16/23.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

PathSection matSample(Ray in, Intersection intersection, constant char * materials, constant MaterialDescription * matTypes, constant char * scene, constant GeometryType * types, constant uint & objectCount, device HaltonSampler & sampler) {
    in.origin = intersection.p;
    float3 dir = sampleCosineHemisphere(generateVec(sampler));
    in.direction = toWorld(dir, intersection.frame);
    in.origin += in.direction * 1e-4;
    Intersection next = trace(in, scene, types, objectCount);
    MaterialDescription mat = matTypes[next.materialId];
    
    PathSection p;
    p.direction = in.direction;
    p.intersection = next;
    p.pdf = cosineHemispherePdf(dir);
    p.result = -dot(in.direction, next.n) > 0 ? in.throughput * getEmission(mat, materials) : 0.;
    p.throughput = getReflectance(mat, materials) * abs(dot(in.direction, next.n));
    return p;
};

[[kernel]]
void pathMatsIntersection(uint tid [[thread_position_in_grid]],
                          device Ray * rays,
                          device Intersection * intersections,
                          constant char * scene,
                          constant GeometryType * types,
                          constant uint & objectCount,
                          device bool & notConverged) {
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED) { return; }
    device Intersection & intersection = intersections[tid];
    intersection = trace(ray, scene, types, objectCount);
    
    if (intersection.t != INFINITY) {
        notConverged = true;
    } else {
        ray.state = FINISHED;
    }
}

[[kernel]]
void pathMatsShading(uint tid [[thread_position_in_grid]],
                     device Ray * rays,
                     constant uint & rayCount,
                     device Intersection * intersections,
                     constant char * materials,
                     constant MaterialDescription * matTypes,
                     device HaltonSampler * samplers) {
    if (tid > rayCount)
        return;
    
    device Ray & ray = rays[tid];
    if (ray.state == FINISHED)
        return;
    Intersection intersection = intersections[tid];
    if (intersection.t < INFINITY) {
        MaterialDescription desc = matTypes[intersection.materialId];
        ray.result += getEmission(desc, materials) * ray.throughput * max(0.f, dot(-ray.direction, intersection.n));
        ray.state = OLD;
        
        device HaltonSampler & sam = samplers[tid];
        float2 sample = generateVec(sam);
        switch (desc.type) {
            case MIRROR: {
                ray.direction = reflect(ray.direction, intersection.n);
                ray.origin = intersection.p + ray.direction * 1e-4;
                break;
            }
            case DIELECTRIC: {
//                ray.direction = refract(ray.direction, intersection.n, dot(-ray.direction, intersection.n) > 0 ? 1.5046 : 1.0002);
                
                // refract
                float eta1;
                float eta2;
                if (dot(-ray.direction, intersection.n) < 0) {
                    eta1 = 1.5046;
                    eta2 = 1.0002;
                } else {
                    eta2 = 1.5046;
                    eta1 = 1.0002;
                }
                
                float3 v = toWorld(-ray.direction, intersection.frame);
                
                float eta = eta1 / eta2;
                float c1 = v.y;
                float w = eta * c1;
                float c2m = (w - eta) * (w + eta);
                v = eta * -v + (w - sqrt(1.0f + c2m)) * float3(0, 1, 0);
                ray.direction = float3(dot(v, intersection.frame.right),
                                       dot(v, intersection.frame.up),
                                       dot(v, intersection.frame.forward));
                
                ray.origin = intersection.p + ray.direction * 1e-4;
                break;
            }
            case BASIC: {
                float3 dir = sampleCosineHemisphere(sample);
                
                ray.direction = toWorld(dir, intersection.frame);
        //        float cos = abs(dot(ray.direction, intersection.n));
                ray.throughput *= /*cos **/ getReflectance(desc, materials);// / uniformHemispherePdf(dir);// * abs(cos);
                ray.origin = intersection.p + ray.direction * 1e-4;
            }
        }
        
        if (ray.state == OLD) {
            float cont = min(maxComponent(ray.throughput), 0.99);
            if (generateSample(sam) > cont) {
                ray.state = FINISHED;
                return;
            } else {
                ray.throughput /= cont;
            }
        }
    } else {
        ray.state = FINISHED;
        return;
    }
    
}
