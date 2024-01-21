//
//  Lighting.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/11/24.
//

#include <metal_stdlib>
#include "Lighting.h"
#include "MetalLighting.hpp"
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
            return 0.;
        }
    }
}
