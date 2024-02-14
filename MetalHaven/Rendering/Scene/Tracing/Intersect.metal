//
//  Intersect.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

#include <metal_stdlib>
#include "Tracing.h"
using namespace metal;

Intersection sphereIntersection(Ray ray, Sphere sphere) {
    float t = sphereIntersect(sphere, ray);
    float3 p = ray.origin + ray.direction * t;
    float3 n = normalize(p - sphere.position);
    
    Frame f = newShadingFrame(n, ray.direction);
    
    return createIntersection(t, p, n, sphere.material, f);
}

Intersection planeIntersection(Triangle triangle, Ray ray) {
    float3 v1 = triangle.v2 - triangle.v1;
    float3 v2 = triangle.v3 - triangle.v1;
    float3 n = normalize(cross(v1, v2));
    float woN = dot(n, ray.direction);
    Frame f = newFrame(0, 0, 0);
    Intersection i = createIntersection(INFINITY, 0, 0, 0, f);
    if (woN == 0)
        return i;
    float t = dot(triangle.v1 - ray.origin, n) / woN;
    if (t < 0)
        return i;
    
    n = -woN > 0 ? n : -n;
    
    float3 forward = normalize(triangle.v2 - triangle.v1);
    f = newFrame(n, forward, normalize(cross(n, forward)));
    return createIntersection(t, ray.origin + ray.direction * t, n, triangle.material, f);
}

inline bool isInUniformSegment(float t) {
    return abs(t - 0.5) <= 0.5;
}

Intersection triangleIntersection(Triangle triangle, Ray ray) {
    //    Intersection fail = createIntersection(INFINITY, 0, 0, 0, newFrame(0, 0, 0));
    Intersection success = planeIntersection(triangle, ray);
    
    float3 e1 = triangle.v2 - triangle.v1;
    float3 e2 = triangle.v3 - triangle.v1;
    float3 ep = success.p - triangle.v1;
    
    float e12 = dot(e1, e2);
    float e1d = dot(e1, e1);
    float e2d = dot(e2, e2);
    float ep2 = dot(ep, e2);
    float denom = e1d * e2d - e12 * e12;
    
    float alpha = (e2d * dot(ep, e1) - e12 * ep2) / denom;
    float beta = (e1d * ep2 - e12 * dot(ep, e1)) / denom;
    float gamma = (1 - alpha - beta);
    
    if (isInUniformSegment(alpha) && isInUniformSegment(beta) && isInUniformSegment(gamma))
        return success;
    Intersection i;
    
    i.t = INFINITY;
    return i;
}
