//
//  Lighting.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/11/24.
//

#include <metal_stdlib>
#import "../Core3DMetal.hpp"
//#include "Lighting.h"
//#include "MetalLighting.hpp"
using namespace metal;

float maxComponent(float3 v) {
    return max(max(v.x, v.y), v.z);
}

vector_float3 getEmission(MaterialDescription desc, constant char * ptr) {
    switch (desc.type) {
        case BASIC: {
            BasicMaterial mat = *(constant BasicMaterial *)(ptr + desc.index);
            return mat.emission;
        }
        case MICROFACET: {}
        case MIRROR: {}
        case DIELECTRIC: {
            return 0.;
        }
    }
}

vector_float3 getReflectance(MaterialDescription desc, constant char * ptr) {
    switch (desc.type) {
        case BASIC: {
            BasicMaterial mat = *(constant BasicMaterial *)(ptr + desc.index);
            return mat.albedo;
        }
        case MIRROR: {
            MirrorMat mat = *(constant MirrorMat *)(ptr + desc.index);
            return mat.reflectance;
        }
        case MICROFACET: {
            Microfacet mat = *(constant Microfacet *)(ptr + desc.index);
            return mat.kd;
        }
        case DIELECTRIC: {
            Dielectric mat = *(constant Dielectric *)(ptr + desc.index);
            return mat.reflectance;
        }
    }
}

BSDF matSamplingStrategy(MaterialType type) {
    switch (type) {
        case MICROFACET: {}
        case BASIC: {
            return SOLID_ANGLE;
        }
        case MIRROR: {}
        case DIELECTRIC: {
            return DISCRETE;
        }
    }
}

LuminarySample sampleLuminaryTriangle(Triangle triangle, vector_float2 sample) {
    LuminarySample s;
    float rt = sqrt(1 - sample.x);
    float alpha = 1 - rt;
    float beta = sample.y * rt;
    
    s.p = triangle.v1 * alpha + triangle.v2 * beta + triangle.v3 * (1 - alpha - beta);
    vector_float3 v = triangle.v2 - triangle.v1;
    vector_float3 u = triangle.v3 - triangle.v2;
    
    s.n = normalize(cross(v, u));
    return s;
}

LuminarySample sampleLuminarySphere(Sphere sphere, vector_float2 sample) {
    LuminarySample s;
    vector_float3 dir = sampleSphere(sample);
    s.p = dir * sphere.size + sphere.position;
//    s.n = normalize(dir); // TODO: I don't know why this didn't work...
    s.n = normalize(s.p - sphere.position);
    return s;
}

LuminarySample sampleLuminarySquare(Square square, vector_float2 sample) {
    LuminarySample s;
    vector_float3 v = square.v2 - square.v1;
    vector_float3 u = square.v3 - square.v2;
    s.n = normalize(cross(v, u));
    s.p = u * sample.x + v * sample.y + square.v1;
    return s;
}

LuminarySample sampleLuminary(AreaLight light, device HaltonSampler & sampler, constant char * scene, constant GeometryType * types) {
    constant char * luminary = scene + light.start;
    
    float2 samples = generateVec(sampler);
    LuminarySample s;
    s.p = INFINITY;
    switch (types[light.index]) {
        case TRIANGLE: {
            s = sampleLuminaryTriangle(*(constant Triangle *)luminary, samples);
        }
        case SPHERE: {
            Sphere light = *(constant Sphere *)luminary;
            s = sampleLuminarySphere(light, samples);
        }
        case SQUARE: {
            s = sampleLuminarySquare(*(constant Square *)luminary, samples);
        }
        default: {
            break;
        }
    }
    s.emission = light.color;
    return s;
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

LuminarySample sampleLuminaries(constant AreaLight * lights,
                        float totalArea, // 1 / pdf
                        device HaltonSampler & sampler,
                        constant char * scene,
                        constant GeometryType * types
                        ) {
    thread float && sample1 = generateSample(sampler);
    uint lightIndex = sampleLuminarySet(lights, totalArea, sample1);
    AreaLight light = lights[lightIndex];
    
    LuminarySample s = sampleLuminary(light, sampler, scene, types);
    s.lightId = lightIndex;
    return s;
}
