//
//  MetalLighting.hpp
//  MetalHaven
//
//  Created by Noah Pikielny on 1/19/24.
//

#ifndef MetalLighting_h
#define MetalLighting_h

vector_float3 getEmission(MaterialDescription desc, constant char * ptr);
vector_float3 getReflectance(MaterialDescription desc, constant char * ptr);
LuminarySample sampleLuminary(AreaLight light, device HaltonSampler & sampler, constant char * scene, constant GeometryType * types);
uint sampleLuminarySet(constant AreaLight * lights,
                       float totalArea,
                       thread float & sample
                       );
LuminarySample sampleLuminaries(constant AreaLight * lights,
                        float totalArea, // 1 / pdf
                        device HaltonSampler & sampler,
                        constant char * scene,
                        constant GeometryType * types
                                );
#endif /* MetalLighting_h */
