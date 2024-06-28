//
//  TestIntersections.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 10/18/23.
//

#include <metal_stdlib>
#import "../../Scene/Tracing/Tracing.h"
#import "../../Scene/Geometry/Geometry.h"
#import "../../Scene/Lighting/Lighting.h"
using namespace metal;
using namespace raytracing;

[[kernel]]
void testIntersections(uint tid [[thread_position_in_grid]],
                       device ShadingRay * rays,
                       device Intersection * intersections,
                       constant BasicMaterial * materials,
                       constant char * scene,
                       constant GeometryType * types,
                       constant uint & objectCount,
                       device bool & notConverged) {
    notConverged = false;
    
    device ShadingRay & ray = rays[tid];
    device Intersection & intersection = intersections[tid];
    
    constant char * nextObject = scene;
    for (uint i = 0; i < objectCount; i++) {
        GeometryType type = types[i];
        Intersection next;
        switch (type) {
            case TRIANGLE: {
                Triangle tri = *(constant Triangle *)nextObject;
                nextObject = (constant char *)((constant Triangle *)nextObject + 1);
                next = planeIntersection(tri, ray.ray);
                break;
            }
            case SPHERE: {
                Sphere s = *(constant Sphere *)nextObject;
                nextObject = (constant char *)((constant Sphere *)nextObject + 1);
                next = sphereIntersection(ray.ray, s);
                break;
            }
            default:
                next.t = INFINITY;
        }
        
        if (next.t < intersection.t) {
            intersection = next;
        }

    }
    
    if (intersection.t != INFINITY) {
        ray.result = materials[intersection.materialId].albedo * (max(0.0, dot(normalize(float3(-1, 1, -1)), intersection.n)) + 0.1);
    }
}

/*
 The custom curves intersection function. The [[intersection]] keyword marks this as an intersection
 function. The [[curve]] keyword means that this intersection function handles intersecting rays
 with curve primitives.
 
 The [[curve_data]] and [[instancing]] keywords indicate that the intersector that calls this
 intersection function returns a curve parameter value of type float. This parameter is the value
 to pass to the curve basis functions to reconstruct the position of the
 intersection along the curve segment. Note that this value is generally not the distance along
 the curve, nor does it vary linearly with distance along the curve. It does, however, increase
 monotonically with distance along the curve. It's up to the app to compute a linear
 (that is, an arc-length) parameterization of the curve if the app requires one.
 Also note that the position that the basis functions return isn't the same as the actual intersection
 point (that is, origin + direction * distance) because the curve has a nonzero radius.
 
 The combination of these keywords needs to match between the intersection functions, intersection function table,
 intersector, and intersection result to ensure that Metal propagates data correctly between stages.
 
 The arguments to the intersection function contain information about the ray, primitive to be
 tested, and so on. The ray intersector provides this data when it calls the intersection function.
 Metal provides other built-in arguments, but this sample doesn't use them.
 */
[[intersection (triangle, triangle_data, instancing)]]
bool triangleIntersectionFunction(// Ray parameters passed to the ray intersector.
                                  float3 origin               [[origin]],
                                  float3 direction            [[direction]],
                                  float distance              [[distance]],
                                  // Information about the primitive.
                                  uint primitiveId            [[primitive_id]],
                                  float2 uv                   [[barycentric_coord]],
                                  ray_data float3& normal     [[payload]],
                                  // Custom resources bound to the intersection function table.
                                  constant float3 *vertexNormals   [[buffer(2)]],
                                  constant uint16_t *vertexIndices [[buffer(3)]]
                                  )
{
    // Look up the corresponding geometry's normal.
    float3 t0 = vertexNormals[vertexIndices[primitiveId * 3 + 0]];
    float3 t1 = vertexNormals[vertexIndices[primitiveId * 3 + 1]];
    float3 t2 = vertexNormals[vertexIndices[primitiveId * 3 + 2]];
    
    // Compute the sum of the vertex attributes weighted by the barycentric coordinates.
    // The barycentric coordinates sum to one.
    normal = (1.0f - uv.x - uv.y) * t0 + uv.x * t1 + uv.y * t2;
    return true;
}

// Get sky color.
inline float3 interpolateSkyColor(float3 ray) {
    float t = mix(ray.y, 1.0f, 0.5f);
    return mix(float3(1.0f, 1.0f, 1.0f), float3(0.45f, 0.65f, 1.0f), t);
}

[[kernel]]
void testIntersector(uint tid [[thread_position_in_grid]],
                     device ShadingRay * rays,
                     device Intersection * intersections,
                     constant BasicMaterial * materials,
                     constant MTLAccelerationStructureInstanceDescriptor *instances,
                     acceleration_structure<instancing> accelerationStructure,
                     intersection_function_table<triangle_data, instancing> intersectionFunctionTable,
                     device bool & notConverged) {
    notConverged = false;
    
    device ShadingRay & raySource = rays[tid];
//    device Intersection & intersectionDest = intersections[tid];
    
    intersector<triangle_data, instancing> i;
    typename intersector<triangle_data, instancing>::result_type intersection;
    
    // Get the closest intersection, not the first intersection.
    i.accept_any_intersection(false);
    
    // Enabling curves has a cost even in cases where curves don't intersect.
    // The new default value of assume_geometry_type is geometry_type::bounding_box | geometry_type::triangle
    // (rather than geometry_type::all).
    // This means that for curves to intersect in an intersect call or an intersection query step,
    // the assume_geometry_type field needs to be explicitly set to a value, including geometry_type::curve.
    i.assume_geometry_type(geometry_type::triangle);
    
    ray ray;
    // Rays start at the camera position.
    ray.origin = raySource.ray.origin;
    // Map the normalized pixel coordinates into the camera's coordinate system.
    ray.direction = raySource.ray.direction;
    // Don't limit the intersection distance.
    ray.max_distance = INFINITY;
    float3 worldSpaceSurfaceNormal{0.0f, 0.0f, 0.0f};
    uint32_t m = 0xFF;
    intersection = i.intersect(ray, accelerationStructure, m, intersectionFunctionTable, worldSpaceSurfaceNormal);
    
    if (intersection.type == intersection_type::none) {
        float3 sky = interpolateSkyColor(ray.direction);
        raySource.result = sky;
    } else {
        raySource.result = materials[intersection.primitive_id].albedo;// * max(0.0, dot(-ray.direction, intersectionDest.n));
    }
}
