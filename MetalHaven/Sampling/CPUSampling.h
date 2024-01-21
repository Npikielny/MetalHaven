//
//  CPUSampling.h
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

#ifndef CPUSampling_h
#define CPUSampling_h

#import "Sampling.h"

float generateSample(HaltonSampler * sampler);
vector_float2 generateVec2(HaltonSampler * sampler);

#endif /* CPUSampling_h */
