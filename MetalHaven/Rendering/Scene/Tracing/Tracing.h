//
//  Tracing.h
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

#ifndef Tracing_h
#define Tracing_h
#import "../Core3D.h"
#import <simd/simd.h>
enum RayState {
    TRACING=0,
    FINISHED=1,
    OLD=2,
    WAITING=3
};

typedef struct Ray {
    vector_float3 origin;
    vector_float3 direction;
    vector_float3 throughput;
    vector_float3 result;
    float eta;
    float expected; 
    float mis;
    enum RayState state;
} Ray;

typedef struct Frame {
    vector_float3 up;
    vector_float3 forward;
    vector_float3 right;
} Frame;

typedef struct Intersection {
    float t;
    vector_float3 p; // position
    vector_float3 n; // normal
    unsigned int materialId;
    Frame frame;
} Intersection;

typedef struct ShadingPoint {
    Intersection intersection;
    vector_float3 irradiance;
} ShadingPoint;

struct Ray createRay(vector_float3 origin, vector_float3 direction);
//struct Ray cameraRay(vector_float3 origin, metal::float4x4 projection, float2 uv);

Intersection createIntersection(float t, vector_float3 p, vector_float3 n, unsigned int materialId, Frame frame);
float sphereIntersect(Sphere sphere, Ray ray);
Intersection sphereIntersection(Ray ray, Sphere sphere);
Intersection planeIntersection(Triangle triangle, Ray ray);
Intersection triangleIntersection(Triangle triangle, Ray ray);
Intersection squareIntersection(Triangle square, Ray ray);

vector_float3 toFrame(vector_float3 v, Frame frame);
Frame newFrame(vector_float3 up, vector_float3 forward, vector_float3 right);
Frame newShadingFrame(vector_float3 normal, vector_float3 ray);
vector_float3 toWorld(vector_float3 v, Frame frame);

//{
//    v.x * frame.right + v.y * frame.up + v.z * frame.forward
//}

float vectorCos(vector_float3 wi, vector_float3 n);

float abscos(vector_float3 wi, vector_float3 n);
#endif /* Tracing_h */
