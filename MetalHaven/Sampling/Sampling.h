//
//  Sampling.h
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

#ifndef Sampling_h
#define Sampling_h

#import <simd/simd.h>

typedef struct HaltonSampler {
    unsigned int seed;
    unsigned int uses;
} HaltonSampler;

float halton(unsigned int i, unsigned int d);

vector_float2 sampleUniformSquare(vector_float2 sample);

vector_float2 sampleUniformDisk(vector_float2 sample);
float uniformDiskPdf(vector_float2 point);

vector_float3 sampleUniformHemisphere(vector_float2 sample);
float uniformHemispherePdf(vector_float3 point);

vector_float3 sampleCosineHemisphere(vector_float2 sample);
float cosineHemispherePdf(vector_float3 point);

vector_float3 sampleSphere(vector_float2 sample);
float spherePdf(vector_float3 point);

vector_float2 sampleNormal(vector_float2 sample);
float normalPdf(vector_float2 point);

#endif /* Sampling_h */
