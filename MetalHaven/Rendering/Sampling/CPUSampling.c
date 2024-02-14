//
//  CPUSampling.c
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

#include "CPUSampling.h"
#import "Sampling.h"
#include <simd/simd.h>

float generateSample(HaltonSampler * sampler) {
    float random = halton(sampler->seed, sampler->uses);
    sampler->uses += 1;
    return random;
}

vector_float2 generateVec2(HaltonSampler * sampler) {
    return vector2(generateSample(sampler), generateSample(sampler));
}
