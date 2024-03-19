//
//  Fluid2D.h
//  MetalHaven
//
//  Created by Noah Pikielny on 3/15/24.
//

#ifndef Fluid2D_h
#define Fluid2D_h

#include <simd/simd.h>

struct Particle2D {
    vector_float2 position;
    vector_float2 velocity;
    vector_float2 force;
    float mass;
    vector_float3 color;
    float size;
};

#endif /* Fluid2D_h */
