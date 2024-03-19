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
        BasicMaterial(albedo: .zero, specular: .zero, emission: .one * 40),// light
        MirrorMat(reflectance: .one * 0.99),
        Dielectric(reflectance: .one, IOR: 1.5046),
        BasicMaterial(albedo: .zero, specular: .zero, emission: .one * 300),// bright light
    ]
    
    static let boxScene = GeometryScene(
        lights: [],
        geometry: [
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 0, 0),
                material: 0,
                reversible: DIRECTIONAL
            ),
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 0, 0),
                material: 0,
                reversible: DIRECTIONAL
            ),
            Plane( // ceiling
                v1: vector_float3(1, 1.6, 0),
                v2: vector_float3(0, 1.6, 0),
                v3: vector_float3(0, 1.6, -1),
                material: 0,
                reversible: DIRECTIONAL
            ),
            Plane( // right
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(1, 1, 0),
                v3: vector_float3(1, 0, -1),
                material: 1,
                reversible: DIRECTIONAL
            ),
            Plane( // left
                v1: vector_float3(-1, 0, 0),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 1, 0),
                material: 2,
                reversible: DIRECTIONAL
            ),
            Plane( // back
                v1: vector_float3(0, 0, -1),
                v2: vector_float3(1, 0, -1),
                v3: vector_float3(0, 1, -1),
                material: 0,
                reversible: DIRECTIONAL
            ),
            // Light
            Square(
                v1: vector_float3(-0.25, 1.58, -0.25),
                v2: vector_float3(0.25, 1.58, -0.25),
                v3: vector_float3(-0.25, 1.58, 0.25),
                material: 4,
                reversible: DIRECTIONAL
            ),
//            Triangle(
//                v1: vector_float3(-0.25, 1.58, -0.25),
//                v2: vector_float3(0.25, 1.58, -0.25),
//                v3: vector_float3(0.25, 1.58, 0.25),
//                material: 4
//            ),
//            Triangle(
//                v1: vector_float3(-0.25, 1.58, -0.25),
//                v2: vector_float3(0.25, 1.58, 0.25),
//                v3: vector_float3(-0.25, 1.58, 0.25),
//                material: 4
//            ),
            
//            Sphere(
//                position: vector_float3(0, 1.58, 0),
//                size: 0.25,
//                material: 4
//            ),
            
            Sphere( // left sphere
                position: vector_float3(-0.45, 0.65 / 2, 0.3),
                size: 0.65 / 2,
                material: 6
            ),
            
            Sphere( // right sphere
                position: vector_float3(0.45, 0.3, -0.25),
                size: 0.3,
                material: 5
            )
        ],
        materials: Self.cs6630BoxColors
    )
    
    static let lampScene = GeometryScene(
        lights: [],
        geometry: [
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 0, 0),
                material: 0,
                reversible: DIRECTIONAL
            ),
            Plane( // floor
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 0, 0),
                material: 0,
                reversible: DIRECTIONAL
            ),
            Plane( // ceiling
                v1: vector_float3(1, 1.6, 0),
                v2: vector_float3(0, 1.6, 0),
                v3: vector_float3(0, 1.6, -1),
                material: 0,
                reversible: DIRECTIONAL
            ),
            Plane( // right
                v1: vector_float3(1, 0, 0),
                v2: vector_float3(1, 1, 0),
                v3: vector_float3(1, 0, -1),
                material: 1,
                reversible: DIRECTIONAL
            ),
            Plane( // left
                v1: vector_float3(-1, 0, 0),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 1, 0),
                material: 2,
                reversible: DIRECTIONAL
            ),
            Plane( // back
                v1: vector_float3(0, 0, -1),
                v2: vector_float3(1, 0, -1),
                v3: vector_float3(0, 1, -1),
                material: 0,
                reversible: DIRECTIONAL
            ),
            // Light
            Sphere(
                position: vector_float3(1 - 0.1,  1.6 - 0.1 - 0.05, -1 + 0.1),
                size: 0.1,
                material: 7
            ),
//            Triangle(
//                v1: vector_float3(0.9, 1.55, -1),
//                v2: vector_float3(0.9, 1.45, -0.9),
//                v3: vector_float3(1, 1.55, -0.9),
//                material: 7,
//                reversible: REVERSIBLE
//            ),
            // Cover
            Triangle(
                v1: vector_float3(1, 1.1, -1),
                v2: vector_float3(1, 1.55, -0.5),
                v3: vector_float3(0.5, 1.55, -1),
                material: 0,
                reversible: REVERSIBLE
            ),
            
            Sphere( // left sphere
                position: vector_float3(-0.45, 0.65 / 2, 0.3),
                size: 0.65 / 2,
                material: 6
            ),
            
            Sphere( // right sphere
                position: vector_float3(0.45, 0.3, -0.25),
                size: 0.3,
                material: 5
            )
        ],
        materials: Self.cs6630BoxColors
    )
    
    static let boxSceneWithSpheres = GeometryScene(
        lights: GeometryScene.boxScene.lights,
        geometry: GeometryScene.boxScene.geometry + [
            Sphere(
                position: vector_float3(-1, 0.75 / 2, -0.25),
                size: 0.75 / 2,
                material: 4
            ),
            Sphere(
                position: vector_float3(0.5, 0.5 / 2, -0.25),
                size: 0.5 / 2,
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
    
    private static let waterVerts: [[SIMD3<Float>]] = {
        let s = 20
        let height: (Float, Float) -> Float = { sin($0) * sin($1) }
        return (-s/2...s/2).map { x -> [SIMD3<Float>] in
            let xp = Float(x)
            return (-s/2...s/2).map { z -> SIMD3<Float> in
                let zp = Float(z)
                return SIMD3(xp / Float(s) * 2, height(xp, zp) / Float(s) + 0.5, zp / Float(s) * 2)
            }
        }
    }()
    
    static func meshGeometry(material: Int32, verts: [[SIMD3<Float>]]) -> [Geometry] {
        let verts = waterVerts
        var geometry = [Triangle]()
        for i in 0..<verts.count-1 {
            for j in 0..<verts[0].count-1 {
                geometry.append(Triangle(v1: verts[i][j], v2: verts[i + 1][j], v3: verts[i + 1][j + 1], material: material, reversible: REVERSIBLE))
                geometry.append(Triangle(v1: verts[i][j], v2: verts[i + 1][j + 1], v3: verts[i][j + 1], material: material, reversible: REVERSIBLE))
            }
        }
        return geometry
    }
    
    static var waterScene: GeometryScene = GeometryScene(
        lights: [],
        geometry: meshGeometry(material: 0, verts: waterVerts) + [
            Square( // Light
                v1: vector_float3(-0.25, 1.58, -0.25),
                v2: vector_float3(0.25, 1.58, -0.25),
                v3: vector_float3(-0.25, 1.58, 0.25),
                material: 1,
                reversible: REVERSIBLE
            ),
            Square( // Floor
                v1: vector_float3(-1, 0, -1),
                v2: vector_float3(-1, 0, 1),
                v3: vector_float3(1, 0, -1),
                material: 2,
                reversible: REVERSIBLE
            ),
        ],
        materials: [
//            Dielectric(reflectance: vector_float3(0.7,0.8,1)*0.99, IOR: 1.333), // water
            Dielectric(reflectance: vector_float3(0.33, 0.66, 1)*0.99, IOR: 1.333), // water
            BasicMaterial(albedo: .one, specular: .zero, emission: .one  * 40),
            BasicMaterial(albedo: SIMD3(0.725, 0.71, 0.68), specular: .zero, emission: .zero), // white
        ]
    )
}
