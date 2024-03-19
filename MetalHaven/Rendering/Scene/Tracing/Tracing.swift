//
//  Tracing.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/18/24.
//

import Foundation

func trace(ray: Ray, scene: [Geometry]) -> Intersection {
    var ray = ray
    ray.origin += ray.direction * 1e-4
    var intersection = Intersection()
    intersection.t = .infinity
    for object in scene {
        let next = object.intersect(ray: ray)
        if next.t < intersection.t {
            intersection = next
        }
    }
    intersection.t += 1e-4;
    return intersection
}

extension Sphere {
    func intersect(ray: Ray) -> Intersection {
        sphereIntersection(ray, self)
    }
}

extension Triangle {
    func intersect(ray: Ray) -> Intersection {
        triangleIntersection(self, ray)
    }
}

extension Square {
    func intersect(ray: Ray) -> Intersection {
        return squareIntersection(
            Triangle(v1: v1, v2: v2, v3: v3, material: material, reversible: reversible),
            ray
        )
    }
}

extension Plane {
    func intersect(ray: Ray) -> Intersection {
        planeIntersection(
            Triangle(v1: v1, v2: v2, v3: v3, material: material, reversible: reversible),
            ray
        )
    }
}
