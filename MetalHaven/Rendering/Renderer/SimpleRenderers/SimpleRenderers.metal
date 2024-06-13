//
//  RayDirections.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

#include <metal_stdlib>
#import "../../Testing/PathTracing/PathTracing.h"
using namespace metal;

[[kernel]]
void rayDirections(uint2 tid [[thread_position_in_grid]],
                   device Ray * rays,
                   texture2d<float, access::write> tex) {
    if (tid.x >= tex.get_width() || tid.y >= tex.get_height())
        return;
    
    tex.write(float4(rays[tid.x + tid.y * tex.get_width()].direction * 0.5 + 0.5, 1), tid);
    
//    tex.write(float4(float2(tid) / float2(tex.get_width(), tex.get_height()), 0, 1), tid);
}

[[kernel]]
void getNormals(uint2 tid [[thread_position_in_grid]],
                device Ray * rays,
                constant char * scene,
                constant GeometryType *types,
                constant uint & objectCount,
                texture2d<float, access::write> tex) {
    if (tid.x >= tex.get_width() || tid.y >= tex.get_height())
        return;
    uint id = tid.x + tid.y * tex.get_width();
    Intersection intersection = trace(rays[id], scene, types, objectCount);
    tex.write(float4(intersection.t == INFINITY ? float3(0, 0, 0) : intersection.n * 0.5 + 0.5, 1), tid);
}

[[kernel]]
void getDirectLighting(uint2 tid [[thread_position_in_grid]],
                    constant Ray * rays,
                    constant char * scene,
                    constant GeometryType *types,
                    constant uint & objectCount,
                    constant char * materials,
                    constant MaterialDescription * matTypes,
                    texture2d<float, access::write> tex) {
    if (tid.x >= tex.get_width() || tid.y >= tex.get_height())
        return;
    uint id = tid.x + tid.y * tex.get_width();
    Ray ray = rays[id];
    Intersection intersection = trace(ray, scene, types, objectCount);
    if (intersection.t == INFINITY)
        return tex.write(0, tid);
    MaterialDescription matT = matTypes[intersection.materialId];
    tex.write(float4(getReflectance(matT, materials) * abs(dot(intersection.n, ray.direction)) + getEmission(matT, materials), 1), tid);
}
