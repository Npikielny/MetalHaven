//
//  SampleMat.h
//  MetalHaven
//
//  Created by Noah Pikielny on 1/21/24.
//

#ifndef SampleMat_h
#define SampleMat_h

#import "../../../Scene/Lighting/Lighting.h"
#import "../../../Scene/Materials/Material.h"

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

MaterialSample sampleBSDF(Ray ray, Intersection intersection, device HaltonSampler & sampler, constant MaterialDescription * matTypes, constant char * mats);

void sampleShadowRay(Ray ray,
                  Intersection intersection,
                  device Ray & shadowRay,
                  constant MaterialDescription * matTypes,
                  constant char * scene,
                  constant GeometryType * types,
                  device HaltonSampler & sampler,
                  constant AreaLight * lights,
                  constant float & totalArea,
                  bool mis
                  );

void generateShadowRay(Ray ray,
                       Intersection intersection,
                       device Ray & shadowRay,
                       constant MaterialDescription * matTypes,
                       constant char * scene,
                       constant GeometryType * types,
                       ShadingPoint shadingPoint,
                       float totalArea,
                       bool mis
                       );

void addShadowRay(device Ray & ray, Ray shadowRay, Intersection shadowTest);

bool roulette(device Ray & ray, device HaltonSampler & sampler);
#endif /* SampleMat_h */
