//
//  Lighting.c
//  MetalHaven
//
//  Created by Noah Pikielny on 3/18/24.
//

#include <stdio.h>
#import "Lighting.h"
#import "../Core3D.h"
#import <simd/simd.h>

//float3 sampleLuminaries(AreaLight * lights,
//                        float totalArea, // 1 / pdf
//                        HaltonSampler & sampler,
//                        char * scene,
//                        GeometryType * types,
//                        float3 & n) {
//    float sample1 = generateSample(sampler);
////    uint lightIndex = sampleLuminarySet(lights, totalArea, sample1);
////    AreaLight light = lights[lightIndex];
//    
////    return sampleLuminary(light, sampler, scene, types, n);
//    return 0.;
//}

LuminarySample sampleLuminaryTriangle(Triangle triangle, vector_float2 sample) {
    LuminarySample s;
    float rt = sqrt(1 - sample.x);
    float alpha = 1 - rt;
    float beta = sample.y * rt;
    
    s.p = triangle.v1 * alpha + triangle.v2 * beta + triangle.v3 * (1 - alpha - beta);
    vector_float3 v = triangle.v2 - triangle.v1;
    vector_float3 u = triangle.v3 - triangle.v2;
    
    s.n = simd_normalize(simd_cross(v, u));
    return s;
}

LuminarySample sampleLuminarySphere(Sphere sphere, vector_float2 sample) {
    LuminarySample s;
    vector_float3 dir = sampleSphere(sample);
    s.p = dir * sphere.size + sphere.position;
    s.n = dir;
    return s;
}

LuminarySample sampleLuminarySquare(Square square, vector_float2 sample) {
    LuminarySample s;
    vector_float3 v = square.v2 - square.v1;
    vector_float3 u = square.v3 - square.v2;
    s.n = simd_normalize(simd_cross(v, u));
    s.p = u * sample.x + v * sample.y + square.v1;
    return s;
}
