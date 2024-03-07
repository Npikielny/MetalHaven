//
//  SampleMat.h
//  MetalHaven
//
//  Created by Noah Pikielny on 1/21/24.
//

#ifndef SampleMat_h
#define SampleMat_h

#import "../../../Scene/Lighting/Lighting.h"

float fresnel(float cosThetaI, float extIOR, float intIOR);
struct PathSection {
    float3 direction;
    Intersection intersection;
    BSDF bsdf;
    float eta;
    float pdf;
    float3 result;
    float3 throughput;
};

PathSection matSample(Ray in, Intersection intersection, constant char * materials, constant MaterialDescription * matTypes, constant char * scene, constant GeometryType * types, constant uint & objectCount, device HaltonSampler & sampler);

struct Out {
    float3 sample;
    float3 dir;
    float eta;
    float pdf;
};

Out smat(Ray ray, Intersection intersection, device HaltonSampler & sampler, constant MaterialDescription * matTypes, constant char * mats);

#endif /* SampleMat_h */
