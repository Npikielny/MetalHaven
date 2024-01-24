//
//  SampleMat.h
//  MetalHaven
//
//  Created by Noah Pikielny on 1/21/24.
//

#ifndef SampleMat_h
#define SampleMat_h

struct PathSection {
    float3 direction;
    Intersection intersection;
    float pdf;
    float3 result;
    float3 throughput;
};

PathSection matSample(Ray in, Intersection intersection, constant char * materials, constant MaterialDescription * matTypes, constant char * scene, constant GeometryType * types, constant uint & objectCount, device HaltonSampler & sampler);

#endif /* SampleMat_h */
