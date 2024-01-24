//
//  PathMis.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../PathTracing.h"

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
            if (dot(-ray.direction, intersection.n) > 0) {
                ray.result += getEmission(desc, materials) * ray.throughput;
            }
            ray.throughput *= getReflectance(desc, materials) * abs(dot(-ray.direction, intersection.n));
            switch (matTypes[intersection.materialId].type) {
                case DIELECTRIC: {
                    Dielectric mat = *(constant Dielectric *)(materials + matTypes[intersection.materialId].index);
                    float c = dot(-ray.direction, intersection.n);
                    float f = fresnel(c, 1.000277f, mat.IOR);
                    bool entering = dot(ray.direction, intersection.n) < 0;
                    float eta1 = entering ? 1.000277f : mat.IOR;
                    float eta2 = entering ? mat.IOR : 1.000277f;

                    if (generateSample(sampler) < f) {
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
                    ray.state = TRACING;
                    indicator = true;
                    return;
                }
                case MIRROR: {
                    ray.direction = reflect(ray.direction, intersection.n);
                    ray.origin = intersection.p + ray.direction * 1e-4;
                    ray.state = TRACING;
                    indicator = true;
                    return;
                }
                case MICROFACET: {}
                case BASIC: {
                    ray.state = OLD;
                }
            }
        }
        case OLD: {
            // MARK: - EMS
            float invArea = 1 / totalArea;
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
            ray.direction = p.direction;
            ray.result += p.result * p.pdf / (p.pdf + invArea);
            intersection = p.intersection;
            auto desc = matTypes[intersection.materialId];
            if (desc.type == MIRROR || desc.type == DIELECTRIC) {
                ray.state = TRACING;
            } else {
                ray.throughput *= p.throughput;
            }

            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99);
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
