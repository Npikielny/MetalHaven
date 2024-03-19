//
//  2DSim.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 3/15/24.
//

#include <metal_stdlib>
#include "Fluid2D.h"
#import "../../../Rendering/Sampling/Sampling.h"
using namespace metal;

struct Particle2DVert {
    float4 position [[position]];
    float2 uv;
    float3 color;
};

constant float2 verts[6] = {
    float2(-1, -1),
    float2(1, 1),
    float2(-1, 1),
    
    float2(-1, -1),
    float2(1, -1),
    float2(1, 1)
};

[[vertex]]
Particle2DVert particle2DVerts(uint id [[vertex_id]],
                         constant Particle2D * particles) {
    Particle2DVert vert;
    Particle2D particle = particles[id / 6];
    vert.color = particle.color;
    float2 v = verts[id % 6];
    vert.position = float4(particle.position + v * particle.size, 0, 1);
    vert.uv = v;
    return vert;
}

[[fragment]]
float4 particle2DFragment(Particle2DVert in [[stage_in]]) {
    if (length(in.uv) > 1)
        discard_fragment();
//    float2 angle = float2(acos(in.position.y), asin(in.position.x));
//    float3 p = normalize(float3(sin(angle.y) * cos(angle.x),
//                      cos(angle.x),
//                      sin(angle.y) * sin(angle.x)
//                      ));
//    float3 lightingDir = normalize(float3(1, 1, 1));
    return float4(in.color/* * abs(dot(p, lightingDir))*/, 1);
}

constant uint bins [[function_constant(0)]];

[[kernel]]
void updateParticles2D(uint tid [[thread_position_in_grid]],
                       device Particle2D * particles,
                       constant uint & particleCount,
                       constant float & dt) {
    if (tid > particleCount)
        return;
    device Particle2D & particle = particles[tid];
    particle.force = float2(0, -9.807);
    particle.velocity += particle.force / 60;
    particle.position += particle.velocity / 60 / 60;
    
    if (abs(particle.position.x) >= 1 - particle.size) {
        particle.position.x = clamp(particle.position.x, -1.f + particle.size, 1.f - particle.size);
        particle.velocity.x = abs(particle.velocity.x) * sign(-particle.position.x) * 0.9;
    }
    
    if (abs(particle.position.y) >= 1 - particle.size) {
        particle.position.y = clamp(particle.position.y, -1.f + particle.size, 1.f - particle.size);
        particle.velocity.y = abs(particle.velocity.y) * sign(-particle.position.y) * 0.9;
    }
    
    uint2 box = uint2((particle.position + 1) / 2 * float(bins));
    float a = halton(box.x, box.y);
    float b = halton(box.y, box.x);
    float3 color = float3(a, b, max(1 - a - b, 0.f));
//    float3 color = float3(float2(box), 0) / float3(bins);
    particle.color = color;
}
