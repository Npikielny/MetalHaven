//
//  BoxScene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/18/23.
//

import Foundation

extension GeometryScene {
    static let cs6630BoxColors: [Material] = [
        BasicMaterial(albedo: SIMD3(0.725, 0.71, 0.68), specular: .zero, emission: .zero), // white
        BasicMaterial(albedo: SIMD3(0.630, 0.065, 0.05), specular: .zero, emission: .zero),// blue
        BasicMaterial(albedo: SIMD3(0.161, 0.133, 0.427), specular: .zero, emission: .zero),// red
        BasicMaterial(albedo: .one, specular: .zero, emission: .zero),// sphere
        BasicMaterial(albedo: .one, specular: .zero, emission: .one * 40),// light
        MirrorMat(reflectance: .one * 0.99),
        Dielectric(reflectance: .one, IOR: 1.5046)
    ]
    
    static let boxScene = GeometryScene(
        lights: [],
        geometry: [
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, 0),
                v3: vector_float3(-1, 0, -1),
                material: 0
            ),
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, 0),
                v3: vector_float3(-1, 0, -1),
                material: 0
            ),
            Plane( // ceiling
                v1: vector_float3(1, 1.6, 0),
                v2: vector_float3(0, 1.6, 0),
                v3: vector_float3(0, 1.6, -1),
                material: 0
            ),
            Plane( // right
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(1, 1, 0),
                v3: vector_float3(1, 0, -1),
                material: 1
            ),
            Plane( // left
                v1: vector_float3(-1, 0, 0),
                v2: vector_float3(-1, 1, 0),
                v3: vector_float3(-1, 0, -1),
                material: 2
            ),
            Plane( // back
                v1: vector_float3(0, 0, -1),
                v2: vector_float3(0, 1, -1),
                v3: vector_float3(1, 0, -1),
                material: 0
            ),
            // Light
            Triangle(
                v1: vector_float3(0.25, 1.58, 0.25),
                v2 : vector_float3(0.25, 1.58, -0.25),
                v3: vector_float3(-0.25, 1.58, 0.25),
                material: 4
            ),
            Triangle(
                v1: vector_float3(-0.25, 1.58, 0.25),
                v2: vector_float3(0.25, 1.58, -0.25),
                v3: vector_float3(-0.255, 1.58, -0.25),
                material: 4
            ),

            Sphere( // left sphere
                position: vector_float3(-0.45, 0.65 / 2, 0.3),
                size: 0.65 / 2,
                material: 3 // 6
            ),
            
            Sphere( // right sphere
                position: vector_float3(0.45, 0.3, -0.25),
                size: 0.3,
                material: 3 // 5
            )
        ],
        materials: Self.cs6630BoxColors
    )
    
    static let lampScene = GeometryScene(
        lights: [],
        geometry: [
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, 0),
                v3: vector_float3(-1, 0, -1),
                material: 0
            ),
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, 0),
                v3: vector_float3(-1, 0, -1),
                material: 0
            ),
            Plane( // ceiling
                v1: vector_float3(1, 1.6, 0),
                v2: vector_float3(0, 1.6, 0),
                v3: vector_float3(0, 1.6, -1),
                material: 0
            ),
            Plane( // right
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(1, 1, 0),
                v3: vector_float3(1, 0, -1),
                material: 1
            ),
            Plane( // left
                v1: vector_float3(-1, 0, 0),
                v2: vector_float3(-1, 1, 0),
                v3: vector_float3(-1, 0, -1),
                material: 2
            ),
            Plane( // back
                v1: vector_float3(0, 0, -1),
                v2: vector_float3(0, 1, -1),
                v3: vector_float3(1, 0, -1),
                material: 0
            ),
            // Light
            Sphere(
                position: vector_float3(1 - 0.1,  1.6 - 0.1 - 0.05, -1 + 0.1),
                size: 0.1,
                material: 4
            ),
            // Cover
            Triangle(
                v1: vector_float3(1, 1.1, -1),
                v2: vector_float3(1, 1.55, -0.5),
                v3: vector_float3(0.5, 1.55, -1),
                material: 0
            ),
            
            Sphere( // left sphere
                position: vector_float3(-0.45, 0.65 / 2, 0.3),
                size: 0.65 / 2,
                material: 3 // 6
            ),
            
            Sphere( // right sphere
                position: vector_float3(0.45, 0.3, -0.25),
                size: 0.3,
                material: 3 // 5
            )
        ],
        materials: Self.cs6630BoxColors
    )
    
    static let boxSceneWithSpheres = GeometryScene(
        lights: GeometryScene.boxScene.lights,
        geometry: GeometryScene.boxScene.geometry + [
            Sphere(
                position: vector_float3(-1, -3 + 0.75, 9),
                size: 0.75,
                material: 4
            ),
            Sphere(
                position: vector_float3(0.5, -3 + 0.5, 8),
                size: 0.5,
                material: 4
            ),
//            Sphere(
//                position: vector_float3(-3, 3, 10),
//                size: 0.1,
//                material: 6
//            )
        ],
        materials: GeometryScene.boxScene.materials
    )
    
    static let boxSceneVerticalSpheres = GeometryScene(
        lights: GeometryScene.boxScene.lights,
        geometry: GeometryScene.boxScene.geometry + [
            Sphere(
                position: vector_float3(-1, 1, 6),
                size: 0.75,
                material: 3
            ),
            Sphere(
                position: vector_float3(-1, -1, 6),
                size: 0.5,
                material: 3
            )
        ],
        materials: GeometryScene.boxScene.materials
    )
}

extension MirrorMat: Material {
    var type: MaterialType { MIRROR }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3) {
        let normal = Vec3(0, 1, 0)
        return (incident + abs(dot(normal, incident)) * normal * 2, 1, reflectance)
    }
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double {
        let normal = Vec3(0, 1, 0)
        let correct = incident + abs(dot(normal, incident)) * normal * 2
        return distance(correct, outgoing) < 1e-4 ? 1 : 0
    }
}

extension Dielectric: Material {
    var type: MaterialType { DIELECTRIC }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3) {
        let normal = Vec3(0, 1, 0)
        return (incident + abs(dot(normal, incident)) * normal * 2, 1, reflectance)
    }
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double {
        let normal = Vec3(0, 1, 0)
        let correct = incident + abs(dot(normal, incident)) * normal * 2
        return distance(correct, outgoing) < 1e-4 ? 1 : 0
    }
}
