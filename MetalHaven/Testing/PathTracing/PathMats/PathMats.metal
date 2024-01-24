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

float fresnelMat(float cosThetaI, float extIOR, float intIOR) {
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
                Dielectric mat = *(constant Dielectric *)(materials + matTypes[intersection.materialId].index);
                float c = dot(-ray.direction, intersection.n);
                float f = fresnelMat(c, 1.000277f, mat.IOR);
                bool entering = dot(ray.direction, intersection.n) < 0;
                float eta1 = entering ? 1.000277f : mat.IOR;
                float eta2 = entering ? mat.IOR : 1.000277f;

                if (generateSample(sam) < f) {
                    // reflect
                    ray.direction = reflect(ray.direction, intersection.n);
                    ray.origin = intersection.p + ray.direction * 1e-4;
                } else {
                    // refract
                    float eta = (eta1 / eta2);
                    ray.direction = refract(ray.direction, intersection.n * (entering ? 1 : -1), eta);
                    ray.eta /= eta;
                }
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
