//
//  RendererHelpers.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

#include <metal_stdlib>
#import "../Scene/Tracing/Tracing.h"

#import "../Scene/Tracing/Tracing.h"
#import "../Scene/Tracing/MetalTracing.hpp"
#import "../Scene/Geometry/Geometry.h"
#import "../Scene/Lighting/Lighting.h"
#import "../Scene/Lighting/MetalLighting.hpp"
#import "../Sampling/MetalSampling.hpp"

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

[[vertex]]
CornerVert getCornerVertsFlipped(uint vid [[vertex_id]]) {
    CornerVert vert;
    float2 p = corners[vid];
    vert.position = float4(p, 0, 1);
    vert.uv = p * 0.5 + 0.5;
    vert.uv.y = 1 - vert.uv.y;
    return vert;
}

[[fragment]]
float4 clearTexture(CornerVert in [[stage_in]]) {
    return float4(float3(0), 1);
}

[[kernel]]
void clearTextureKernel(uint2 tid [[thread_position_in_grid]],
                        texture2d<float, access::write>tex) {
    tex.write(float4(float3(0), 1), tid);
}

constexpr metal::sampler sam(metal::min_filter::bicubic, metal::mag_filter::bicubic, metal::mip_filter::none);

[[fragment]]
float4 uvFrag(CornerVert in [[stage_in]],
                   texture2d<float> tex) {
    return float4(tex.sample(sam, in.uv).xyz, 1);
}

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
                  device ShadingRay * rays,
                  constant float3x3 & projection,
                  constant float3 & center,
                  constant float2 & offset) {
    if (tid >= size.x * size.y)
        return;
    uint x = tid % size.x;
    uint y = tid / size.x;
    
    float2 uv = (float2(x, y) + offset) / float2(size) * 2 - 1;
    
    float3 dir = normalize(projection * float3(uv, 1));
    
    rays[tid] = createShadingRay(center, dir);
}

[[kernel]]
void generateNullIntersections(uint tid [[thread_position_in_grid]],
                               device Intersection * intersections) {
    intersections[tid] = createIntersection(INFINITY, 0, 0, 0, newFrame(0., 0., 0.));
}

// Accumulation
[[kernel]]
void accumulate(uint2 tid [[thread_position_in_grid]],
                constant ShadingRay * rays,
                constant uint & samples,
                texture2d<float, access::read> in,
                texture2d<float, access::write> out) {
    ShadingRay ray = rays[tid.x + tid.y * in.get_width()];
    float3 previous = in.read(tid).xyz;
    
    out.write(float4(previous + ray.result / float(samples), 1), tid);
}

[[kernel]]
void accumulateInto(uint2 tid [[thread_position_in_grid]],
                    texture2d<float, access::read> in,
                    texture2d<float, access::read_write> out,
                    constant uint & samples) {
    float3 r1 = in.read(tid).xyz;
    float3 r2 = out.read(tid).xyz * float(samples - 1);
    out.write(float4((r1 + r2) / float(samples), 1), tid);
}

[[kernel]]
void intersect(uint tid [[thread_position_in_grid]],
                       device ShadingRay * rays,
                       constant uint & rayCount,
                       device Intersection * intersections,
                       constant char * scene,
                       constant GeometryType * types,
                       constant uint & objectCount) {
    if (tid >= rayCount)
        return;
    device Intersection & intersection = intersections[tid];
    device ShadingRay & ray = rays[tid];
    switch (ray.state) {
        case WAITING:
        case FINISHED: { return; }
        case TRACING: {}
        case OLD: {
            ray.ray.origin += ray.ray.direction * 1e-4;
            intersection = trace(ray.ray, scene, types, objectCount);
            if (intersection.t == INFINITY) {
                ray.state = WAITING;
                return;
            }
            intersection.t += 1e-4;
        }
    }
}

[[kernel]]
void cleanAndAccumulate(uint tid [[thread_position_in_grid]],
                        device ShadingRay * rays,
                        constant uint & chunkOffset,
                        constant uint & rayCount,
                        device uint * samples,
                        constant uint & max,
                        constant float3x3 & projection,
                        constant float3 & center,
                        device HaltonSampler * samplers,
                        device bool & indicator,
                        constant float2 & offset,
                        texture2d<float, access::read_write> destination,
                        texture2d<float, access::write> temp) {
    uint width = destination.get_width();
    if (tid >= rayCount)
        return;
    uint s = samples[tid];
    if (s > max)
        return;
    device ShadingRay & ray = rays[tid];
    
    uint x = (tid + chunkOffset) % width;
    uint y = (tid + chunkOffset) / width;
    uint2 p = uint2(x, y);
    
    uint2 size = uint2(width, destination.get_height());
    
//    device HaltonSampler & sampler = samplers[tid];
    float3 result = destination.read(p).xyz;
    if (!isfinite(length(ray.result))) {
        ray.result = 0;
    }
    float3 sum = result + ray.result;
    float3 r = sum / float(s + 1);
    if (ray.state == FINISHED) {
        samples[tid] = s + 1;
        if (samples[tid] > max) {
            temp.write(float4(r / 3, 1), p);
//            temp.write(float4(sum / float(max), 1), p);
            destination.write(float4(sum / float(max), 1), p);
        } else {
            temp.write(float4(r / 2, 1), p);
            destination.write(float4(sum, 1), p);
        }
        float2 jitter = /*generateVec(sampler)*/offset / float2(size);
        
        float2 uv = float2(x, y) / float2(size) * 2 - 1 + jitter;
        
        float3 dir = normalize(projection * float3(uv, 1));
        rays[tid] = createShadingRay(center, dir);
    }
    
    indicator = true;
}
