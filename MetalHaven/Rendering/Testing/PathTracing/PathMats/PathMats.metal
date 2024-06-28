//
//  PathMats.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/16/23.
//

#include <metal_stdlib>
#import "../PathTracing.h"
using namespace metal;

float fresnel(float cosThetaI, float extIOR, float intIOR) {
    float etaI = extIOR, etaT = intIOR;

    if (extIOR == intIOR)
        return 0.0f;

    /* Swap the indices of refraction if the interaction starts
       at the inside of the object */
    if (cosThetaI < 0.0f) {
//        swap(etaI, etaT);
        float temp = etaI;
        etaI = etaT;
        etaI = temp;
        cosThetaI = -cosThetaI;
    }

    /* Using Snell's law, calculate the squared sine of the
       angle between the normal and the transmitted ray */
    float eta = etaI / etaT,
          sinThetaTSqr = eta*eta * (1-cosThetaI*cosThetaI);

    if (sinThetaTSqr > 1.0f)
        return 1.0f;  /* Total internal reflection! */

    float cosThetaT = sqrt(1.0f - sinThetaTSqr);

    float Rs = (etaI * cosThetaI - etaT * cosThetaT)
             / (etaI * cosThetaI + etaT * cosThetaT);
    float Rp = (etaT * cosThetaI - etaI * cosThetaT)
             / (etaT * cosThetaI + etaI * cosThetaT);

    return (Rs * Rs + Rp * Rp) / 2.0f;
}

BSDF bsdf(MaterialType type) {
    switch (type) {
        case BASIC:
        case MICROFACET: {
            return SOLID_ANGLE;
            break;
        }
        case MIRROR:
        case DIELECTRIC: {
            return DISCRETE;
            break;
        }
    }
}

struct Bounce {
//    float3 sample;
    BSDF bsdf;
    float3 wo;
    float eta = 1;
    float pdf;
};

Bounce sampleBSDF(float3 wi, Frame frame, MaterialDescription desc, constant char * materials, device HaltonSampler & sampler) {
    float3 n = frame.up;
    Bounce b;
    b.eta = 1;
    switch (desc.type) {
        case DIELECTRIC: {
            Dielectric mat = *(constant Dielectric *)(materials + desc.index);
//            b.sample = mat.reflectance;
            b.bsdf = DISCRETE;
            float c = dot(-wi, n);
            
            float f = fresnel(c, 1.000277f, mat.IOR);
            if (!isfinite(f) || isnan(f)) { // ray is tangent to surface
                b.wo = reflect(wi, n);
                b.pdf = 1;
                break;
            }
            bool entering = dot(wi, n) < 0;
            float eta1 = entering ? 1.000277f : mat.IOR;
            float eta2 = entering ? mat.IOR : 1.000277f;
            if (generateSample(sampler) < f) {
                // reflect
                b.wo = reflect(wi, n);
                b.pdf = f;
            } else {
                // refract
                float eta = (eta1 / eta2);
                b.wo = refract(wi, n * (entering ? 1 : -1), eta);
                b.eta = eta;
                b.pdf = 1 - f;
            }
            break;
        }
        case MIRROR: {
            MirrorMat m = *(constant MirrorMat *)(materials + desc.index);
//            b.sample = m.reflectance;
            b.bsdf = DISCRETE;
            b.wo = reflect(wi, n);
            b.pdf = 1;
            break;
        }
        case MICROFACET:
        case BASIC: {
            b.bsdf = SOLID_ANGLE;
            float3 wo = sampleCosineHemisphere(generateVec(sampler));
            b.wo = toWorld(wo, frame);
//            b.sample = getReflectance(desc, materials);
            b.pdf = cosineHemispherePdf(wo);
            break;
        }
    }
    return b;
}

PathSection matSample(ShadingRay in, Intersection intersection, constant char * materials, constant MaterialDescription * matTypes, constant char * scene, constant GeometryType * types, constant uint & objectCount, device HaltonSampler & sampler) {
    in.ray.origin = intersection.p;
    
//    float3 dir = sampleCosineHemisphere(generateVec(sampler));
    Bounce bounce = sampleBSDF(in.ray.direction, intersection.frame, matTypes[intersection.materialId], materials, sampler);
    in.ray.direction = bounce.wo;
    in.ray.origin += in.ray.direction * 1e-4;
//    in.throughput *= bounce.sample;
    Intersection next = trace(in.ray, scene, types, objectCount);
    MaterialDescription mat = matTypes[next.materialId];
    
    PathSection p;
    p.direction = in.ray.direction;
    p.intersection = next;
    p.pdf = bounce.pdf;
    p.result = -dot(in.ray.direction, next.n) > 0 ? in.throughput * getEmission(mat, materials) : 0.;
    p.bsdf = bounce.bsdf;
    p.eta = bounce.eta;
    p.throughput = getReflectance(matTypes[next.materialId], materials) * abs(dot(in.ray.direction, next.n));
    return p;
};


[[kernel]]
void pathMatsIntersection(uint tid [[thread_position_in_grid]],
                          device ShadingRay * rays,
                          device Intersection * intersections,
                          constant char * scene,
                          constant GeometryType * types,
                          constant uint & objectCount,
                          device bool & notConverged) {
    device ShadingRay & ray = rays[tid];
    if (ray.state == FINISHED) { return; }
    device Intersection & intersection = intersections[tid];
    intersection = trace(ray.ray, scene, types, objectCount);
    
    if (intersection.t != INFINITY) {
        notConverged = true;
    } else {
        ray.state = FINISHED;
    }
}

[[kernel]]
void pathMatsShading(uint tid [[thread_position_in_grid]],
                     device ShadingRay * rays,
                     constant uint & rayCount,
                     device Intersection * intersections,
                     constant char * materials,
                     constant MaterialDescription * matTypes,
                     device HaltonSampler * samplers) {
    if (tid > rayCount)
        return;
    
    device ShadingRay & ray = rays[tid];
    if (ray.state == FINISHED)
        return;
    Intersection intersection = intersections[tid];
    if (intersection.t < INFINITY) {
        MaterialDescription desc = matTypes[intersection.materialId];
        ray.result += getEmission(desc, materials) * ray.throughput * max(0.f, dot(-ray.ray.direction, intersection.n));
        ray.state = OLD;
        
        device HaltonSampler & sam = samplers[tid];
        float2 sample = generateVec(sam);
        switch (desc.type) {
            case MIRROR: {
                ray.ray.direction = reflect(ray.ray.direction, intersection.n);
                ray.ray.origin = intersection.p + ray.ray.direction * 1e-4;
                break;
            }
            case DIELECTRIC: {
                Dielectric mat = *(constant Dielectric *)(materials + matTypes[intersection.materialId].index);
                float c = dot(-ray.ray.direction, intersection.n);
                float f = fresnel(c, 1.000277f, mat.IOR);
                bool entering = dot(ray.ray.direction, intersection.n) < 0;
                float eta1 = entering ? 1.000277f : mat.IOR;
                float eta2 = entering ? mat.IOR : 1.000277f;

                if (generateSample(sam) < f) {
                    // reflect
                    ray.ray.direction = reflect(ray.ray.direction, intersection.n);
                    ray.ray.origin = intersection.p + ray.ray.direction * 1e-4;
                } else {
                    // refract
                    float eta = (eta1 / eta2);
                    ray.ray.direction = refract(ray.ray.direction, intersection.n * (entering ? 1 : -1), eta);
                    ray.eta /= eta;
                }
                ray.ray.origin = intersection.p + ray.ray.direction * 1e-4;
                break;
            }
            case BASIC: {
                float3 dir = sampleCosineHemisphere(sample);
                
                ray.ray.direction = toWorld(dir, intersection.frame);
        //        float cos = abs(dot(ray.direction, intersection.n));
                ray.throughput *= /*cos **/ getReflectance(desc, materials);// / uniformHemispherePdf(dir);// * abs(cos);
                ray.ray.origin = intersection.p + ray.ray.direction * 1e-4;
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
