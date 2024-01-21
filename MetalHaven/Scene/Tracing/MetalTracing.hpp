//
//  MetalTracing.hpp
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

#ifndef MetalTracing_h
#define MetalTracing_h

#import "../Lighting/Lighting.h"
#import "../Geometry/Geometry.h"
#import "../../Sampling/Sampling.h"

Intersection trace(Ray ray,
                      constant char * scene,
                      constant GeometryType * types,
                      constant uint & objectCount);


uint sampleLuminarySet(constant AreaLight * lights,
                       float totalArea,
                       thread float & sample
                       );

float3 sampleLuminaryTriangle(Triangle triangle, float2 sample, thread float3 & n);
float3 sampleLuminarySphere(Sphere sphere, float2 sample, thread float3 & n);
float3 sampleLuminary(AreaLight light, device HaltonSampler & sampler, constant char * scene, constant GeometryType * types, thread float3 & n);
float3 sampleLuminaries(constant AreaLight * lights,
                        float totalArea, // 1 / pdf
                        device HaltonSampler & sampler,
                        constant char * scene,
                        constant GeometryType * types,
                        thread float3 & n
                        );
#endif /* MetalTracing_h */
