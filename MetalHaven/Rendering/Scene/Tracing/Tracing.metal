//
//  Tracing.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/12/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../Lighting/Lighting.h"
#import "../Geometry/Geometry.h"
#import "../../Sampling/Sampling.h"
#import "../../Sampling/MetalSampling.hpp"
#include "Tracing.h"
#include "MetalTracing.hpp"

float vectorCos(vector_float3 wi, vector_float3 n) {
    return dot(wi, n);
}

float abscos(vector_float3 wi, vector_float3 n) {
    return abs(dot(wi, n));
}

vector_float3 toWorld(vector_float3 v, Frame frame) {
    return v.x * frame.right + v.y * frame.up + v.z * frame.forward;
//    return float3(dot(v, frame.right),
//                  dot(v, frame.forward),
//                  dot(v, frame.up)
//                  );
}

vector_float3 toFrame(vector_float3 v, Frame frame) {
    return vector_float3(dot(v, frame.right),
                         dot(v, frame.up),
                         dot(v, frame.forward));
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
    f.right = normalize(cross(normal, ray));
    f.forward = normalize(cross(f.right, f.up));
    return f;
}

Intersection trace(Ray ray,
                      constant char * scene,
                      constant GeometryType * types,
                      uint objectCount) {
    Intersection intersection;
    intersection.t = INFINITY;
    constant char * nextObject = scene;
    for (uint i = 0; i < objectCount; i++) {
        GeometryType type = types[i];
        Intersection next;
        switch (type) {
            case TRIANGLE: {
                Triangle tri = *(constant Triangle *)nextObject;
                nextObject = (constant char *)((constant Triangle *)nextObject + 1);
                next = triangleIntersection(tri, ray);
                break;
            }
            case PLANE: {
                Triangle tri = *(constant Triangle *)nextObject;
                nextObject = (constant char *)((constant Triangle *)nextObject + 1);
                next = planeIntersection(tri, ray);
                break;
            }
            case SPHERE: {
                Sphere s = *(constant Sphere *)nextObject;
                nextObject = (constant char *)((constant Sphere *)nextObject + 1);
                next = sphereIntersection(ray, s);
                break;
            }
            case SQUARE: {
                Triangle square = *(constant Triangle *)nextObject;
                nextObject = (constant char *)((constant Triangle *)nextObject + 1);
                next = squareIntersection(square, ray);
                break;
            }
            default:
                next.t = INFINITY;
        }
        
        if (next.t < intersection.t) {
            intersection = next;
        }
    }
    return intersection;
}
