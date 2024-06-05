//
//  BoxScene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/18/23.
//

import Foundation

extension GeometryScene {
    static let cs6630BoxColors: [Material] = [
        BasicMaterial(albedo: SIMD3(0.725, 0.71, 0.68), specular: .zero, emission: .zero), // white 0
        BasicMaterial(albedo: SIMD3(0.630, 0.065, 0.05), specular: .zero, emission: .zero),// blue 1
        BasicMaterial(albedo: SIMD3(0.161, 0.133, 0.427), specular: .zero, emission: .zero),// red 2
        BasicMaterial(albedo: .one, specular: .zero, emission: .zero),// sphere 3
        BasicMaterial(albedo: .zero, specular: .zero, emission: .one * 40),// light 4
        MirrorMat(reflectance: .one * 0.99), // 5
        Dielectric(reflectance: .one, IOR: 1.5046), // 6
        BasicMaterial(albedo: .zero, specular: .zero, emission: .one * 300),// bright light 7
        BasicMaterial(albedo: SIMD3(0.133, 0.427, 0.161), specular: .zero, emission: .zero),// green 8
    ]
    
    static let emptyRoom = GeometryScene(
        lights: [],
        geometry: [
            Plane( // floor
                v1: vector_float3(-1, 0, -1),
                v2: vector_float3(-1, 0, 1),
                v3: vector_float3(1, 0, 1),
                material: 0,
                reversible: DIRECTIONAL
            ),
//            Square( // floor
//                v1: vector_float3(1, 0, 1),
//                v2: vector_float3(-1, 0, -1),
//                v3: vector_float3(-1, 0, 1),
//                material: 0,
//                reversible: DIRECTIONAL
//            ),
            Plane( // ceiling
                v1: vector_float3(1, 1.6, 1),
                v2: vector_float3(-1, 1.6, 1),
                v3: vector_float3(-1, 1.6, -1),
                material: 0,
                reversible: REVERSIBLE
            ),
            Plane( // right
                v1: vector_float3(1, 0, 1),
                v2: vector_float3(1, 1.6, 1),
                v3: vector_float3(1, 0, -1),
                material: 1,
                reversible: DIRECTIONAL
            ),
            Plane( // left
                v1: vector_float3(-1, 0, 1),
                v2: vector_float3(-1, 0, -1),
                v3: vector_float3(-1, 1.6, 1),
                material: 2,
                reversible: DIRECTIONAL
            ),
            Plane( // back
                v1: vector_float3(-1, 0, -1),
                v2: vector_float3(1, 0, -1),
                v3: vector_float3(-1, 1.6, -1),
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
            )
//            Sphere(
//                position: vector_float3(0, 1.60, 0),
//                size: 0.15,
//                material: 4
//            )
        ],
        materials: Self.cs6630BoxColors
    )
    
    static let boxScene = GeometryScene(
        lights: [],
        geometry: Self.emptyRoom.geometry + [
            
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
                material: 4
            ),
//            Square(
//                v1: vector_float3(1 - 0.1,  1.6 - 0.1 - 0.05, -1 + 0.1),
//                v2: vector_float3(1 - 0.1,  1.6 - 0.1 - 0.05, -1 + 0.1) + vector_float3(0.2, 0, 0),
//                v3: vector_float3(1 - 0.1,  1.6 - 0.1 - 0.05, -1 + 0.1) + vector_float3(0.2, 0, 0.2),
//                material: 7,
//                reversible: REVERSIBLE
//            ),
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
                v2: vector_float3(0.25, 1.55, -1),
                v3: vector_float3(1, 1.55, -0.25),
                material: 0,
                reversible: DIRECTIONAL
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
    
    static let sphereArray: GeometryScene = {
        let side = 5
        let n = side * side
        let width: Float = 2 // width of scene
        let sphereWidth = width / Float(side)
        let spheres: [Sphere] = (0..<n).map {
            let x = Float($0 % side)
            let z = Float($0 / side)
            return Sphere(
                position: vector_float3(x + 0.5, 0, z + 0.5) * sphereWidth + vector_float3(-width / 2, 0.5, -width / 2),
                size: sphereWidth / 2 - 2e-4,
                material: 6
            )
        }
        
        return GeometryScene(
            lights: GeometryScene.boxScene.lights,
            geometry: GeometryScene.emptyRoom.geometry + spheres,
            materials: GeometryScene.boxScene.materials
        )
    }()
    
    private static let waterVerts: [[SIMD3<Float>]] = {
        let s = 40
        let height: (Float, Float) -> Float = { sin($0 / 1.5) * sin($1 / 1.2) }
        return (-s/2-1...s/2+1).map { x -> [SIMD3<Float>] in
            let xp = Float(x)
            return (-s/2-1...s/2+1).map { z -> SIMD3<Float> in
                let zp = Float(z)
                return SIMD3(xp / Float(s) * 2, height(xp, zp) / Float(s) + 0.35, zp / Float(s) * 2)
            }
        }
    }()
    
    private static func meshVerts(
        n: Int,
        ibounds: ClosedRange<Float>,
        jbounds: ClosedRange<Float>,
        height: (_ i: Float, _ j: Float) -> Float,
        combiner: (_ i: Float, _ height: Float, _ j: Float) -> SIMD3<Float> = { i, height, j in
            SIMD3(i, height, j)
        }
    ) -> [[SIMD3<Float>]] {
        return (0..<n)
            .map { iindex -> [SIMD3<Float>] in
                let i = Float(iindex) / Float(n - 1) * (ibounds.upperBound - ibounds.lowerBound) + ibounds.lowerBound
                return (0..<n)
                    .map { jindex -> SIMD3<Float> in
                        let j = Float(jindex) / Float(n - 1) * (jbounds.upperBound - jbounds.lowerBound) + jbounds.lowerBound
                        return combiner(i, height(i, j), j)
                    }
            }
    }
    
    private static let poolVerts: [[SIMD3<Float>]] = {
        let s = 20
        let height: (Float, Float) -> Float = { sin($0) * sin($1) }
        return (-s/2...s/2).map { x -> [SIMD3<Float>] in
            let xp = Float(x)
            return (-s/2...s/2).map { z -> SIMD3<Float> in
                let zp = Float(z)
                return SIMD3(xp / Float(s) * 2, zp / Float(s) * 2, height(xp, zp) / Float(s) + 0.5)
            }
        }
    }()
    
    static func meshGeometry(material: Int32, verts: [[SIMD3<Float>]]) -> [Geometry] {
        var geometry = [Triangle]()
        for i in 0..<verts.count-1 {
            for j in 0..<verts[0].count-1 {
                geometry.append(Triangle(v1: verts[i][j], v2: verts[i + 1][j], v3: verts[i + 1][j + 1], material: material, reversible: DIRECTIONAL))
                geometry.append(Triangle(v1: verts[i][j], v2: verts[i + 1][j + 1], v3: verts[i][j + 1], material: material, reversible: DIRECTIONAL))
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
    
    static var waterBox: GeometryScene = GeometryScene(
        lights: [],
        geometry: Self.emptyRoom.geometry + meshGeometry(material: 6, verts: waterVerts),
        materials: Self.boxScene.materials
    )
    
    static var poolScene: GeometryScene = GeometryScene(
        lights: [],
        geometry: meshGeometry(material: 0, verts: poolVerts) + [
            Square( // Light
                v1: vector_float3(-0.25, 1.58, -0.25),
                v2: vector_float3(0.25, 1.58, -0.25),
                v3: vector_float3(-0.25, 1.58, 0.25),
                material: 1,
                reversible: REVERSIBLE
            ),
            Square( // Floor
                v1: vector_float3(-1, -1, 0),
                v2: vector_float3(-1, 1, 0),
                v3: vector_float3(1, -1, 0),
                material: 3,
                reversible: REVERSIBLE
            ),
            Sphere(
                position: vector_float3(0, 0, -10),
                size: 0.5,
                material: 3
            )
        ],
        materials: [
//            Dielectric(reflectance: vector_float3(0.7,0.8,1)*0.99, IOR: 1.333), // water
            Dielectric(reflectance: vector_float3(0.33, 0.66, 1) * 0.99, IOR: 1.333), // water
            BasicMaterial(albedo: .one, specular: .zero, emission: .one  * 40),
            BasicMaterial(albedo: SIMD3(0.725, 0.71, 0.68), specular: .zero, emission: .zero), // white
            BasicMaterial(albedo: vector_float3(0.9, 0.4, 0.3), specular: .zero, emission: .zero)
        ]
    )
    
    static var ocean: GeometryScene = GeometryScene(
        lights: [],
        geometry: [
            Sphere(position: vector_float3(0, 243 + 2 + 1e-4, 0), size: 2, material: 1),
        ] + meshGeometry(
            material: 0,
            verts: meshVerts(
                n: 100,
                ibounds: -300...300,
                jbounds: -300...300,
                height: { i, j in
//                    sin(i) * sin(j) * 3
//                    sin(i) * sin(j)
                    0
                },
                combiner: { i, height, j in
                    SIMD3(j, height, i)
                }
            )
        ),
        materials: [
            Dielectric(reflectance: .one, IOR: 1.333),
            BasicMaterial(albedo: .zero, specular: .zero, emission: .one * 40)
        ]
    )
}
