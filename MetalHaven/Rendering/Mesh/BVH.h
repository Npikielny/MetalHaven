//
//  BVH.h
//  MetalHaven
//
//  Created by Noah Pikielny on 6/29/24.
//

#ifndef BVH_h
#define BVH_h

typedef struct BoundingBox {
    vector_float3 min;
    vector_float3 max;
    uint start; // start in buffer
    vector_uint2 count; // id, count
//    uint32_t mask;
} BoundingBox;
#endif /* BVH_h */
