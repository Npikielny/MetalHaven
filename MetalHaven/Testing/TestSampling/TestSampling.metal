//
//  TestSampling.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

#include <metal_stdlib>
#import "../../Sampling/MetalSampling.hpp"
#import "../../Sampling/Sampling.h"
using namespace metal;

[[kernel]]
void generateSampler(uint2 tid [[thread_position_in_grid]],
                     texture2d<unsigned int>random,
                     device HaltonSampler * samplers) {
    uint width = random.get_width();
    if (tid.x >= width || tid.y >= random.get_height())
        return;
    
    device HaltonSampler & sampler = samplers[tid.x + tid.y * width];
    sampler.seed = random.read(tid).x;
    sampler.uses = 0;
}

[[kernel]]
void testSampling(uint2 tid [[thread_position_in_grid]],
                  texture2d<float, access::write> out,
                  device HaltonSampler * samplers) {
    if (tid.x >= out.get_width() || tid.y >= out.get_height())
        return;
//    uint index = tid.x + tid.y * out.get_width();
    device HaltonSampler & sampler = samplers[tid.x + tid.y *  out.get_width()];
    
    float3 s = sampleUniformHemisphere(generateVec(sampler));
    out.write(float4(abs(s), 1), tid);
    
//    float2 r = 0.;
////    r = generateVec(sampler);
//    int k = 10;
//    for (int i = 0; i < k; i ++) {
//        r += generateVec(sampler) / float(k);
//    }
//    
//    
//    out.write(float4(r, 0, 1), tid);
}

//float generateSample(thread Sampler * sampler) {
//    sampler->uses += 1;
//    return 1.0;
//}
