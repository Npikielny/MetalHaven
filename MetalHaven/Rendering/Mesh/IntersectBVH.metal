//
//  IntersectBVH.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 6/27/24.
//

#include <metal_stdlib>
using namespace metal;

#import "../Testing/PathTracing/PathTracing.h"

struct BoundingRay {
    Ray ray;
    float3 inv_dir;
    float tmin = INFINITY;
    float tmax = INFINITY;
};

inline float vector_min(float3 v) {
    return (v.x < v.y && v.x < v.z) ? v.x : (v.y < v.z ? v.y : v.z);
}

inline float vector_max(float3 v) {
    return (v.x > v.y && v.x > v.z) ? v.x : (v.y > v.z ? v.y : v.z);
}

bool intersectNode(BoundingRay ray, BoundingBox box) {
    float3 t1 = (box.min - ray.ray.origin) * ray.inv_dir;
    float3 t2 = (box.max - ray.ray.origin) * ray.inv_dir;
    
    float3 tsmin = min(t1, t2);
    float tmin = vector_max(tsmin);
    float3 tsmax = max(t1, t2);
    float tmax = vector_min(tsmax);
    
//    float tmin = vector_min((box.min - ray.ray.origin) * ray.inv_dir);
//    float tmax = vector_max((box.max - ray.ray.origin) * ray.inv_dir);
//    return tmin <= tmax ? INFINITY : tmin;
    return tmin <= tmax && tmin;
}

Intersection intersectGeometry(Ray ray, uint startingId, uint start, uint count, constant char * geometry, constant GeometryType * types) {
    return trace(ray, geometry + start, types + startingId, count);
}

Intersection intersectBVH(Ray ray, constant BoundingBox * boxes, constant char * geometry, constant GeometryType * types) {
    ray.origin += ray.direction * 1e-4;
    int stackSize = 1;
    BoundingBox cache[15];
    cache[0] = boxes[0];
    Intersection intersection;
    intersection.t = INFINITY;
    
    BoundingRay br;
    br.ray = ray;
    br.inv_dir = 1 / ray.direction;
    
    int iterations = 0;
    while (stackSize > 0) {
        iterations += 1;
        BoundingBox box = cache[stackSize - 1];
        if (intersectNode(br, box)) { // hit and flip
            if (box.count.y > 0) {
                Intersection proposal = intersectGeometry(ray, box.count.x, box.start, box.count.y, geometry, types);
                if (proposal.t < intersection.t) {
                    intersection = proposal;
                }
            } else { // flip and push
                cache[stackSize] = boxes[box.start];
                cache[stackSize - 1] = boxes[box.start + 1];
                stackSize += 1;
                continue;
            }
        }
        // miss -> pop
        stackSize -= 1;
    }
    return intersection;
}

struct BVHStats {
    uint tests = 0;
    uint primitiveTests = 0;
    uint maxDepth = 0;
};

BVHStats createStats() {
    BVHStats stats;
    stats.primitiveTests = 0;
    stats.tests = 0;
    stats.maxDepth = 0;
    return stats;
}

Intersection monitorIntersectBVH(Ray ray, constant BoundingBox * boxes, constant char * geometry, constant GeometryType * types, thread BVHStats & stats) {
//    int stackSize = 1;
//    BoundingBox cache[15];
//    
//    Intersection intersection;
//    intersection.t = INFINITY;
//    
//    BoundingRay br;
//    br.ray = ray;
//    br.inv_dir = 1 / ray.direction;
//    
////    if (intersectNode(br, boxes[0]) == INFINITY)
////        return intersection;
//    cache[0] = boxes[0];
//    
//    while (stackSize > 0) {
//        BoundingBox box = cache[stackSize - 1];
//        stats.tests += 1;
//        if (intersectNode(br, box)) { // hit and flip
//            if (box.count.y > 0) {
//                Intersection proposal = intersectGeometry(ray, box.count.x, box.start, box.count.y, geometry, types);
//                stats.primitiveTests += box.count.y;
//                if (proposal.t < intersection.t) {
//                    intersection = proposal;
//                }
//            } else { // flip and push
//                float t1 = intersectNode(br, boxes[box.start]);
//                float t2 = intersectNode(br, boxes[box.start]);
//                
//                if (t1 < t2) {
//                    
//                } else {
//                    
//                }
//                cache[stackSize] = boxes[box.start];
//                cache[stackSize - 1] = boxes[box.start + 1];
//                stackSize += 1;
//                continue;
//            }
//        }
//        // miss -> pop
//        stackSize -= 1;
//    }
//    return intersection;
    ray.origin += ray.direction * 1e-4;
    int stackSize = 1;
    BoundingBox cache[15];
    cache[0] = boxes[0];
    Intersection intersection;
    intersection.t = INFINITY;
    
    BoundingRay br;
    br.ray = ray;
    br.inv_dir = 1 / ray.direction;
    
    while (stackSize > 0) {
        BoundingBox box = cache[stackSize - 1];
        if (intersectNode(br, box)) { // hit and flip
            stats.tests += 1;
            if (box.count.y > 0) {
                Intersection proposal = intersectGeometry(ray, box.count.x, box.start, box.count.y, geometry, types);
                if (proposal.t < intersection.t) {
                    intersection = proposal;
                }
                stats.primitiveTests += box.count.y;
            } else { // flip and push
                cache[stackSize] = boxes[box.start];
                cache[stackSize - 1] = boxes[box.start + 1];
                stackSize += 1;
                continue;
            }
        }
        // miss -> pop
        stackSize -= 1;
    }
    return intersection;
}

[[kernel]]
void visualizeBoundingBoxes(uint2 tid [[thread_position_in_grid]],
                            device ShadingRay * rays,
                            constant BoundingBox * boxes,
                            constant char * geometry,
                            constant GeometryType * types,
                            constant char * materials,
                            constant MaterialDescription * matTypes,
                            texture2d<float, access::write> tex) {
    if (tid.x >= tex.get_width() || tid.y >= tex.get_height())
        return;
    
    uint id = tid.x + tid.y * tex.get_width();
    thread BVHStats && stats = createStats();
    device ShadingRay & ray = rays[id];
    Intersection intersection = monitorIntersectBVH(ray.ray, boxes, geometry, types, stats);
//    Intersection intersection = intersectBVH(ray.ray, boxes, geometry, types);
    float3 metric = float3(stats.primitiveTests, stats.tests, 0) / float3(100, 100, 10);
    
    if (intersection.t == INFINITY) {
        tex.write(float4(float3(metric), 0), tid);
    } else {
//////        float3 r = getReflectance(matTypes[intersection.materialId], materials);
////        tex.write(float4((float3(metric) + r) * 0.5f, 1), tid);
        tex.write(float4((intersection.n * 0.5 + 0.5) * 0.5, 1), tid);
    }
}

float3 traceRay(ShadingRay ray, 
                constant BoundingBox * boxes,
                constant char * geometry,
                constant GeometryType * types,
                constant char * materials,
                constant MaterialDescription * matTypes,
                device HaltonSampler & sampler,
                constant AreaLight * lights,
                constant float & totalArea,
                int iters) {
    float bmis = 1;
    Intersection intersection = intersectBVH(ray.ray, boxes, geometry, types);
    
    for (int i = 0; i < iters && intersection.t != INFINITY; i++) {
        float3 emission = (sign(-dot(ray.ray.direction, intersection.n)) + 1) * getEmission(matTypes[intersection.materialId], materials) * bmis;
        ray.result += emission * ray.throughput;
        
        MaterialSample o = sampleBSDF(ray, intersection, sampler, matTypes, materials);
        bmis = o.pdf / (o.pdf + 1 / totalArea);
        ray.throughput *= o.sample;
        ray.ray.direction = o.dir;
        ray.eta *= o.eta;
        ray.ray.origin = intersection.p;
        
        intersection = intersectBVH(ray.ray, boxes, geometry, types);
        
        if (matSamplingStrategy(matTypes[intersection.materialId].type) == SOLID_ANGLE) {
            LuminarySample l = sampleLuminaries(lights, totalArea, sampler, geometry, types);
            float3 dir = (l.p - intersection.p);
            float d = length(dir);
            dir /= d;
            
            Ray shadowRay;
            
            float attenuation = abs(dot(dir, intersection.n)) * max(0.f, dot(-dir, l.n));
            if (attenuation == 0 || (dot(-ray.ray.direction, intersection.n) * dot(dir, intersection.n)) < 0) {
                continue;
            }
            
            shadowRay.origin = intersection.p;
            shadowRay.direction = dir;
//            expected = d;
//            result = l.emission * attenuation * ray.throughput * totalArea;
            float epdf = attenuation / totalArea;
            float3 frameDir = toFrame(dir, intersection.frame);
            frameDir *= sign(dot(frameDir, intersection.n));
            float bpdf = cosineHemispherePdf(frameDir);
//            shadowRay.mis = epdf / (epdf + bpdf);
            Intersection shadowTest = intersectBVH(shadowRay, boxes, geometry, types);
            if (abs(shadowTest.t - d) < 1e-4) {
                ray.result += l.emission * attenuation * ray.throughput * totalArea * epdf / (epdf + bpdf);
            }
        }
    }
    
    return ray.result;
}

[[kernel]]
void bvhRendering(uint2 tid [[thread_position_in_grid]],
                  constant ShadingRay * rays,
                  constant BoundingBox * boxes,
                  constant char * geometry,
                  constant GeometryType * types,
                  constant char * materials,
                  constant MaterialDescription * matTypes,
                  device HaltonSampler * samplers,
                  constant AreaLight * lights,
                  constant float & totalArea,
                  texture2d<float, access::write> tex) {
    if (tid.x >= tex.get_width() || tid.y >= tex.get_height())
        return;
    
    uint id = tid.x + tid.y * tex.get_width();
    constant ShadingRay & ray = rays[id];
    
    device HaltonSampler & sampler = samplers[id];
    
//    int n = 10;
//    float3 result = 0;
//    for (int i = 0; i < n; i ++) {
//        result += traceRay(ray, boxes, geometry, types, materials, matTypes, sampler, lights, totalArea, 3);
//    }
    int n = 1;
    float3 result = traceRay(ray, boxes, geometry, types, materials, matTypes, sampler, lights, totalArea, 3);
    
    tex.write(float4(result / float(n), 1), tid);
}

[[kernel]]
void bvhDirect(uint2 tid [[thread_position_in_grid]],
                  constant ShadingRay * rays,
                  constant BoundingBox * boxes,
                  constant char * geometry,
                  constant GeometryType * types,
                  constant char * materials,
                  constant MaterialDescription * matTypes,
                  device HaltonSampler * samplers,
                  constant AreaLight * lights,
                  constant float & totalArea,
                  texture2d<float, access::write> tex) {
    if (tid.x >= tex.get_width() || tid.y >= tex.get_height())
        return;
    
    uint id = tid.x + tid.y * tex.get_width();
    ShadingRay ray = rays[id];
    device HaltonSampler & sampler = samplers[id];
    
    Intersection intersection = intersectBVH(ray.ray, boxes, geometry, types);
    if (intersection.t == INFINITY)
        return tex.write(0, tid);
    
    for (int i = 0; matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE && i < 8; i ++) {
        auto desc = matTypes[intersection.materialId];
        switch (desc.type) {
            case DIELECTRIC: {
                Dielectric mat = *(constant Dielectric *)(materials + desc.index);
                //            b.sample = mat.reflectance;
                float c = dot(-ray.ray.direction, intersection.n);
                
                float f = fresnel(c, 1.000277f, mat.IOR);
                if (!isfinite(f) || isnan(f)) { // ray is tangent to surface
                    ray.ray.direction = reflect(ray.ray.direction, intersection.n);
                    break;
                }
                bool entering = dot(ray.ray.direction, intersection.n) < 0;
                float eta1 = entering ? 1.000277f : mat.IOR;
                float eta2 = entering ? mat.IOR : 1.000277f;
                if (generateSample(sampler) < f) {
                    // reflect
                    ray.ray.direction = reflect(ray.ray.direction, intersection.n);
                } else {
                    // refract
                    float eta = (eta1 / eta2);
                    ray.ray.direction = refract(ray.ray.direction, intersection.n * (entering ? 1 : -1), eta);
                }
                break;
            }
            case MIRROR: {
                MirrorMat m = *(constant MirrorMat *)(materials + desc.index);
                //            b.sample = m.reflectance;
                ray.ray.direction = reflect(ray.ray.direction, intersection.n);
                break;
            }
        }
        ray.ray.origin = intersection.p;
        intersection = intersectBVH(ray.ray, boxes, geometry, types);
    }
    
    float3 emission = getEmission(matTypes[intersection.materialId], materials);
    if (length(emission) > 0)
        return tex.write(float4(emission, 1), tid);
    
    if (matSamplingStrategy(matTypes[intersection.materialId].type) == DISCRETE)
        return tex.write(0, tid);
    
    LuminarySample sample = sampleLuminaries(lights, totalArea, sampler, geometry, types);
    float3 diff = sample.p - intersection.p;
    float d = length(diff);
    Ray shadowRay = createRay(intersection.p, diff / d);
    float attenuation = max(-dot(shadowRay.direction, sample.n), 0.f) * max(dot(shadowRay.direction, intersection.n), 0.f);
    if (attenuation == 0)
        return tex.write(0, tid);
    
    Intersection shadowTest = intersectBVH(shadowRay, boxes, geometry, types);
    if (abs(shadowTest.t - d) < 1e-4) {
//        return tex.write(float4(abs(dot(ray.ray.direction, intersection.n)) * attenuation * sample.emission * getReflectance(matTypes[intersection.materialId], materials), 1), tid);
        return tex.write(float4(abs(dot(ray.ray.direction, intersection.n)) * attenuation * sample.emission * getReflectance(matTypes[intersection.materialId], materials) * totalArea, 1), tid);
    }
    
    tex.write(float4(float3(0), 1), tid);
}
