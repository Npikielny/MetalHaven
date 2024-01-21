//
//  MetalSampling.h
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

#ifndef MetalSampling_h
#define MetalSampling_h

#include <metal_stdlib>
#include <simd/simd.h>
#include "Sampling.h"

using namespace metal;

float generateSample(device HaltonSampler & sampler);
vector_float2 generateVec(device HaltonSampler & sampler);

HaltonSampler createSampler(uint seed);

#endif /* MetalSampling_h */
