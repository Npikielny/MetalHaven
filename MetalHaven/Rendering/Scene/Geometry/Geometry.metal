//
//  Geometry.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 7/19/23.
//

#include <metal_stdlib>
using namespace metal;

#import "Geometry.h"

Sphere createSphere(vector_float3 position, float size, int material) {
    Sphere sphere;
    sphere.position = position;
    sphere.size = size;
    sphere.material = material;
    return sphere;
};

