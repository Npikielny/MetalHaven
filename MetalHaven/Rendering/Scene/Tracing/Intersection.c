//
//  Intersection.c
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

#include <stdio.h>
#include <simd/simd.h>
#include "../Core3D.h"

float sphereIntersect(Sphere sphere, Ray ray) {
    vector_float3 diff = ray.origin - sphere.position;
    float b = simd_dot(ray.direction, diff);
    float c = simd_dot(diff, diff) - sphere.size * sphere.size;
    float detSQ = b * b - c;
    
    if (detSQ < 0) {
        return INFINITY;
    }
    float det = sqrt(detSQ);
    float t1 = -b - det;
    if (t1 >= 0) {
        return t1;
    }
    float t2 = -b + det;
    if (t2 >= 0) {
        return t2;
    }
    return INFINITY;
}

Intersection sphereIntersection(Ray ray, Sphere sphere) {
    float t = sphereIntersect(sphere, ray);
    vector_float3 p = ray.origin + ray.direction * t;
    vector_float3 n = simd_normalize(p - sphere.position);
    
    Frame f = newShadingFrame(n, ray.direction);
    
    return createIntersection(t, p, n, sphere.material, f);
}

Intersection planeIntersection(Triangle triangle, Ray ray) {
    vector_float3 v1 = triangle.v2 - triangle.v1;
    vector_float3 v2 = triangle.v3 - triangle.v1;
    vector_float3 n = simd_normalize(simd_cross(v1, v2));
    float woN = simd_dot(n, ray.direction);
    Frame f = newFrame(0, 0, 0);
    Intersection i = createIntersection(INFINITY, 0, 0, 0, f);
    if (woN == 0)
        return i;
    float t = simd_dot(triangle.v1 - ray.origin, n) / woN;
    if (t < 0)
        return i;
    if (triangle.reversible == REVERSIBLE) {
        n = -woN > 0 ? n : -n;
    }
    
    vector_float3 forward = simd_normalize(triangle.v2 - triangle.v1);
    f = newFrame(n, forward, simd_normalize(simd_cross(n, forward)));
    return createIntersection(t, ray.origin + ray.direction * t, n, triangle.material, f);
}

Intersection triangleIntersection(Triangle triangle, Ray ray) {
    //    Intersection fail = createIntersection(INFINITY, 0, 0, 0, newFrame(0, 0, 0));
    Intersection success = planeIntersection(triangle, ray);
    
    vector_float3 e1 = triangle.v2 - triangle.v1;
    vector_float3 e2 = triangle.v3 - triangle.v1;
    vector_float3 ep = success.p - triangle.v1;
    
    float e12 = simd_dot(e1, e2);
    float e1d = simd_dot(e1, e1);
    float e2d = simd_dot(e2, e2);
    float ep2 = simd_dot(ep, e2);
    float denom = e1d * e2d - e12 * e12;
    
    float alpha = (e2d * simd_dot(ep, e1) - e12 * ep2) / denom;
    float beta = (e1d * ep2 - e12 * simd_dot(ep, e1)) / denom;
    float gamma = (1 - alpha - beta);
    
    if (fabs(alpha - 0.5) <= 0.5 && fabs(beta - 0.5) <= 0.5 && fabs(gamma - 0.5) <= 0.5)
        return success;
    Intersection i;
    
    i.t = INFINITY;
    return i;
}

Intersection squareIntersection(Triangle square, Ray ray) {
    Intersection success = planeIntersection(square, ray);
    
    vector_float3 e1 = square.v2 - square.v1;
    vector_float3 e2 = square.v3 - square.v1;
    vector_float3 ep = success.p - square.v1;
    float t1 = simd_dot(ep, e1);
    float t2 = simd_dot(ep, e2);
    if (t1 >= 0 && t1 <= simd_dot(e1, e1) && t2 >= 0 && t2 <= simd_dot(e2, e2))
        return success;
//    if (abs(t1 - 0.5) < 0.5 /*&& abs(dot(ep, e2) / length(e2) - 0.5) < 0.5*/) {
//        return success;
//    }
    success.t = INFINITY;
    return success;
}
