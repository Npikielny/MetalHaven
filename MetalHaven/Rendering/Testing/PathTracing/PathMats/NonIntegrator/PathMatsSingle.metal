//
//  PathMatsSingle.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/13/24.
//

#include <metal_stdlib>
using namespace metal;
#import "../../PathTracing.h"

[[kernel]]
void pathMatsSingle(uint tid [[thread_position_in_grid]],
                    device ShadingRay * rays,
                    constant uint & rayCount,
                    device Intersection * intersections,
                    constant char * materials,
                    constant MaterialDescription * matTypes,
                    constant char * scene,
                    constant GeometryType * types,
                    constant uint & objectCount,
                    device HaltonSampler * samplers,
                    constant AreaLight * lights,
                    constant float & totalArea,
                    device bool & indicator) {
    if (tid >= rayCount)
        return;
    
    device ShadingRay & ray = rays[tid];
    device Intersection & intersection = intersections[tid];
    
    switch (ray.state) {
        case WAITING: { ray.state = FINISHED; }
        case FINISHED: return;
        case OLD: {
            PathSection section = matSample(ray, intersection, materials, matTypes, scene, types, objectCount, samplers[tid]);
            intersection = section.intersection;
            ray.result += section.result;
            ray.throughput *= section.throughput;
            ray.ray.direction = section.direction;
            ray.eta *= section.eta;
            ray.throughput /= ray.eta * ray.eta;
//            float cont = min(maxComponent(ray.throughput) * ray.eta * ray.eta, 0.99f);
//            if (generateSample(samplers[tid]) < cont) {
//                ray.throughput /= cont;
//            } else {
//                ray.state = FINISHED;
//                return;
//            }
            break;
        }
        case TRACING: {
            intersection = trace(ray.ray, scene, types, objectCount);
            if (intersection.t == INFINITY) {
                ray.state = FINISHED;
                return;
            }
            float cos = abs(dot(ray.ray.direction, intersection.n));
            MaterialDescription desc = matTypes[intersection.materialId];
            ray.result += cos * getEmission(desc, materials);
            ray.throughput *= cos * getReflectance(desc, materials);
            ray.state = OLD;
            break;
        }
    }
    indicator = true;
}
