//
//  RawBufferTest.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 1/2/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../../Scene/Tracing/Tracing.h"
#import "../../Scene/Geometry/Geometry.h"
#import "../../Scene/Lighting/Lighting.h"


struct Vert {
    float4 position [[position]];
    float3 color;
};

[[vertex]]
Vert primitiveVertices(uint vid [[vertex_id]],
                       constant char * objects,
                       constant GeometryType * types,
                       constant uint * offsets) {
    uint index = vid / 3;
    GeometryType t = types[index];
    Vert v;
    switch (t) {
        case SPHERE: {
            Sphere t = *(constant Sphere * )(objects + offsets[index]);
            uint id = vid % 3;
            float3 p;
            if (id == 0) {
                p = t.position - float3(t.size, 0, 0);
            } else if (id == 1) {
                p = t.position - float3(0, t.size, 0);
            } else {
                p = t.position + float3(t.size, 0, 0);
            }
            v.color = float3(1, 0, 1);
            v.position = float4(p.xy / (p.z + 5), 0, 1);
            
            break;
        }
        case TRIANGLE: {
            Triangle t = *(constant Triangle * )(objects + offsets[index]);
            uint id = vid % 3;
            float3 p;
            if (id == 0) {
                p = t.v1;
            } else if (id == 1) {
                p = t.v2;
            } else {
                p = t.v3;
            }
            v.color = float3(0, 1, 0);
            v.position = float4(p.xy / (p.z + 5), 0, 1);
            
            break;
        }
        default:
            break;
    }
    return v;
}

[[fragment]]
float4 colorPrimitive(Vert v [[stage_in]]) {
    return float4(v.color, 1);
}
