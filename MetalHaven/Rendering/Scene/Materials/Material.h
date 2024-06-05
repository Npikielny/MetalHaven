//
//  Material.h
//  MetalHaven
//
//  Created by Noah Pikielny on 3/19/24.
//

#ifndef Material_h
#define Material_h

struct MaterialSample {
    vector_float3 sample;
    vector_float3 dir;
    float eta;
    float pdf;
};

float fresnel(float cosThetaI, float extIOR, float intIOR);
#endif /* Material_h */
