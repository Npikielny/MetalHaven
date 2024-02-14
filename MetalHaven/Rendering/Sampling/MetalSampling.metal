//
//  MetalSampling.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

#import "Sampling.h"
#include <metal_stdlib>
#import <simd/simd.h>
using namespace metal;

constant unsigned int primes[] = {
    2,   3,  5,  7,
    11, 13, 17, 19,
    23, 29, 31, 37,
    41, 43, 47, 53,
    59, 61, 67, 71,
    73, 79, 83//, 89
};

// Returns the i'th element of the Halton sequence using the d'th prime number as a
// base. The Halton sequence is a low-discrepancy sequence: the values appear
// random, but are more evenly distributed than a purely random sequence. Each random
// value the system uses to render the image uses a different independent dimension, `d`,
// and each sample (frame) uses a different index `i`. To decorrelate each pixel,
// you can apply a random offset to `i`.
float halton(unsigned int i, unsigned int d) {
    d = d % 23;
    unsigned int b = primes[d];
    
    float f = 1.0f;
    float invB = 1.0f / b;
    
    float r = 0;
    
    while (i > 0) {
        f = f * invB;
        r = r + f * (i % b);
        i = i / b;
    }
    
    return r;
}

float generateSample(device HaltonSampler & sampler) {
    float random = halton(sampler.uses, sampler.seed);
    sampler.uses += 1;
    sampler.seed += 1;
    return random;
}

vector_float2 generateVec(device HaltonSampler & sampler) {
    return { generateSample(sampler), generateSample(sampler) };
}

HaltonSampler createSampler(uint seed) {
    HaltonSampler s;
    s.seed = seed;
    s.uses = 1;
    return s;
}

vector_float2 sampleUniformSquare(vector_float2 sample) {
    return sample;
}


vector_float2 sampleUniformDisk(vector_float2 sample) {
    float radius = pow(sample.y, 0.5);
    vector_float2 out = { radius * cos(sample.x * M_PI_F * 2.f), radius * sin(sample.x * M_PI_F * 2.f) };
    return out;
}

float uniformDiskPdf(vector_float2 point) {
    return sqrt(point.x * point.x + point.y * point.y) <= 1 ? 1 / M_PI_F : 0;
}

vector_float3 sampleUniformHemisphere(vector_float2 sample) {
    float phi = sample.x * M_PI_F * 2.f;
    float theta = acos(1 - sample.y);
    vector_float3 out = {
        cos(phi) * sin(theta),
        cos(theta),
        sin(phi) * sin(theta),
    };
    return out;
}
float uniformHemispherePdf(vector_float3 point) {
    return point.y < 0 ? 0 : 1 / M_PI_F / 2.f;
}

vector_float3 sampleCosineHemisphere(vector_float2 sample) {
    float phi = sample.x * M_PI_F * 2.f;
    float theta = asin(sqrt(sample.y));
    
    vector_float3 out = {
        cos(phi) * sin(theta),
        cos(theta),
        sin(phi) * sin(theta)
    };
    return out;
}

float cosineHemispherePdf(vector_float3 point) {
    return point.y < 0 ? 0 : point.y / M_PI_F / 2.f;
}

vector_float3 sampleSphere(vector_float2 sample) {
    float phi = sample.x * M_PI_F * 2;
    float theta = acos(1 - 2 * sample.y);
    vector_float3 out = {
        cos(phi) * sin(theta),
        sin(phi) * sin(theta),
        cos(theta)};
    return out;
}

float spherePdf(vector_float3 point) {
    return 1.f / M_PI_F / 4.0f;
}
