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
#endif /* MetalLighting_h */
