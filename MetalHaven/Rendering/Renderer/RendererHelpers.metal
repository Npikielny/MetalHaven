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

[[kernel]]
void intersect(uint tid [[thread_position_in_grid]],
                       device Ray * rays,
                       constant uint & rayCount,
                       device Intersection * intersections,
                       constant char * scene,
                       constant GeometryType * types,
                       constant uint & objectCount) {
    if (tid >= rayCount)
        return;
    device Intersection & intersection = intersections[tid];
    device Ray & ray = rays[tid];
    switch (ray.state) {
        case FINISHED: { return; }
        case TRACING: {}
        case OLD: {
            ray.origin += ray.direction * 1e-4;
            intersection = trace(ray, scene, types, objectCount);
            if (intersection.t == INFINITY) {
                ray.state = FINISHED;
                return;
            }
            intersection.t += 1e-4;
        }
    }
}

[[kernel]]
void cleanAndAccumulate(uint tid [[thread_position_in_grid]],
                        device Ray * rays,
                        constant uint & chunkOffset,
                        constant uint & rayCount,
                        device uint * samples,
                        constant uint & max,
                        constant float3x3 & projection,
                        constant float3 & center,
                        device HaltonSampler * samplers,
                        device bool & indicator,
                        texture2d<float, access::read_write> destination,
                        texture2d<float, access::write> temp) {
    uint width = destination.get_width();
    if (tid >= rayCount)
        return;
    uint s = samples[tid];
    if (s > max)
        return;
    device Ray & ray = rays[tid];
//    switch (ray.state) {
//        case TRACING: {}
//        case OLD: { return; }
//        case FINISHED: { break; }
//    }
    
    uint x = (tid + chunkOffset) % width;
    uint y = (tid + chunkOffset) / width;
    uint2 p = uint2(x, y);
    
//    if (s >= max) {
//        float3 result = (ray.result + tex.read(p).xyz * float(max - 1))/float(max);
//        float4 r = float4(result, 1);
//        tex.write(r, p);
//        samples[tid] += 1;
//        return;
//    }
    uint2 size = uint2(width, destination.get_height());
    
    device HaltonSampler & sampler = samplers[tid];
    float2 jitter = (generateVec(sampler) * 2 - 1) / float2(size);
    
    float2 uv = float2(x, y) / float2(size) * 2 - 1 + jitter;
    
    float3 dir = normalize(projection * float3(uv, 1));
    
    float3 result = destination.read(p).xyz;
//    float3 result = ray.result;
//        float3 result = (ray.result + tex.read(p).xyz * float(s))/float(s + 1);
    float3 sum = result + ray.result / float(max);
    float3 r = sum * float(max) / float(s + 1);
    temp.write(float4(r / (r + 1), 1), p);
    if (ray.state == FINISHED) {
        samples[tid] = s + 1;
        if (samples[tid] > max) {
            destination.write(float4(sum / (sum + 1), 1), p);
        } else {
            destination.write(float4(sum, 1), p);
        }
        rays[tid] = createRay(center, dir);
    }
    
    indicator = true;
}
