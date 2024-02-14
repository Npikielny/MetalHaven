//
//  Tracing.c
//  MetalHaven
//
//  Created by Noah Pikielny on 1/12/24.
//

#include "Tracing.h"
#include <simd/simd.h>
#import "math.h"

vector_float3 toFrame(vector_float3 v, Frame frame) {
    return v.x * frame.right + v.y * frame.up + v.z * frame.forward;
}

Frame newFrame(vector_float3 up, vector_float3 forward, vector_float3 right) {
    Frame f;
    f.up = up;
    f.forward = forward;
    f.right = right;
    return f;
}

Frame newShadingFrame(vector_float3 normal, vector_float3 ray) {
    Frame f;
    f.up = normal;
    f.right = simd_cross(normal, ray);
    f.forward = simd_cross(f.right, f.up);
    return f;
}

float vectorCos(vector_float3 wi, vector_float3 n) {
    return fmaxf(simd_dot(wi, n), 0.f);
}

float abscos(vector_float3 wi, vector_float3 n) {
    return fabsf(simd_dot(wi, n));
}
