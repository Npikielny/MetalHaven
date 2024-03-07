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
            default:
                next.t = INFINITY;
        }
        
        if (next.t < intersection.t) {
            intersection = next;
        }

    }
    
    return intersection;
}

uint sampleLuminarySet(constant AreaLight * lights,
                       float totalArea,
                       thread float & sample
                       ) {
    uint i = 0;
    float area = 0;
    while (area < sample) {
        area += lights[i].totalArea / totalArea;
        i ++;
    }
    i = i == 0 ? 0 : i - 1;
//    AreaLight light = lights[i];
//    float offset = area - light.totalArea / totalArea;
//    float s2 = (sample - offset) * totalArea / light.totalArea;
//    sample = s2;
    return max(i, uint(0));
}

float3 sampleLuminaryTriangle(Triangle triangle, float2 sample, thread float3 & n) {
    float rt = sqrt(1 - sample.x);
    float alpha = 1 - rt;
    float beta = sample.y * rt;
    
    float3 point = triangle.v1 * alpha + triangle.v2 * beta + triangle.v3 * (1 - alpha - beta);
    float3 v = triangle.v2 - triangle.v1;
    float3 u = triangle.v3 - triangle.v2;
    
    n = normalize(cross(v, u));
    return point;
}

float3 sampleLuminarySphere(Sphere sphere, float2 sample, thread float3 & n) {
    float3 s = sampleSphere(sample); // FIXME: Sample Sphere
    float3 p = s * sphere.size + sphere.position;
    n = s;
    return p;
}

float3 sampleLuminary(AreaLight light, device HaltonSampler & sampler, constant char * scene, constant GeometryType * types, thread float3 & n) {
    constant char * luminary = scene + light.start;
    
    float2 samples = generateVec(sampler);
    
    switch (types[light.index]) {
        case TRIANGLE: {
            return sampleLuminaryTriangle(*(constant Triangle *)luminary, samples, n);
            break;
        }
        case SPHERE: {
            return sampleLuminarySphere(*(constant Sphere *)luminary, samples, n);
            break;
        }
        default: {
            break;
        }
    }
    return INFINITY;
}

float3 sampleLuminaries(constant AreaLight * lights,
                        float totalArea, // 1 / pdf
                        device HaltonSampler & sampler,
                        constant char * scene,
                        constant GeometryType * types,
                        thread float3 & n
                        ) {
    thread float && sample1 = generateSample(sampler);
    uint lightIndex = sampleLuminarySet(lights, totalArea, sample1);
    AreaLight light = lights[lightIndex];
    
    return sampleLuminary(light, sampler, scene, types, n);
}
