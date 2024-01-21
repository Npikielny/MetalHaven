//
//  RendererHelpers.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

#include <metal_stdlib>
#import "../Scene/Tracing/Tracing.h"
using namespace metal;

// MARK: Clearing Textures
constant float2 corners[] = {
    float2(-1, -1),
    float2(1, -1),
    float2(1, 1),
    
    float2(-1, -1),
    float2(1, 1),
    float2(-1, 1)
};

struct CornerVert {
    float4 position [[position]];
    float2 uv;
};

[[vertex]]
CornerVert getCornerVerts(uint vid [[vertex_id]]) {
    CornerVert vert;
    float2 p = corners[vid];
    vert.position = float4(p, 0, 1);
    vert.uv = p * 0.5 + 0.5;
    return vert;
}

[[fragment]]
float4 clearTexture(CornerVert in [[stage_in]]) {
    return float4(float3(0), 1);
}

constexpr metal::sampler sam(metal::min_filter::bicubic, metal::mag_filter::bicubic, metal::mip_filter::none);

[[fragment]]
float4 copyTexture(CornerVert in [[stage_in]],
                   constant float & rescale,
                   texture2d<float> tex) {
    return float4(tex.sample(sam, in.uv).xyz * rescale / 2, 1);
}

[[fragment]]
float4 dynamicTexture(CornerVert in [[stage_in]],
                   constant float & rescale,
                   texture2d<float> tex) {
    float3 c = tex.sample(sam, in.uv).xyz * rescale;
    return float4(c / (c + 1), 1);
}

// MARK: Rays and Intersections
[[kernel]]
void generateRays(uint tid [[thread_position_in_grid]],
                  constant uint2 & size,
                  device Ray * rays,
                  constant float3x3 & projection,
                  constant float3 & center,
                  constant float2 & offset) {
    if (tid >= size.x * size.y)
        return;
    uint x = tid % size.x;
    uint y = tid / size.x;
    
    float2 uv = (float2(x, y) + offset) / float2(size) * 2 - 1;
    
    float3 dir = normalize(projection * float3(uv, 1));
    
    rays[tid] = createRay(center, dir);
}

[[kernel]]
void generateNullIntersections(uint tid [[thread_position_in_grid]],
                               device Intersection * intersections) {
    intersections[tid] = createIntersection(INFINITY, 0, 0, 0, newFrame(0., 0., 0.));
}

// Accumulation
[[kernel]]
void accumulate(uint2 tid [[thread_position_in_grid]],
                constant Ray * rays,
                constant uint & samples,
                texture2d<float, access::read> in,
                texture2d<float, access::write> out) {
    Ray ray = rays[tid.x + tid.y * in.get_width()];
    float3 previous = in.read(tid).xyz;
    
    out.write(float4(previous + ray.result / float(samples), 1), tid);
}
