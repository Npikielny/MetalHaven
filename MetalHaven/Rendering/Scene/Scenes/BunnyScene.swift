//
//  BunnyScene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/27/24.
//

import Foundation

extension GeometryScene {
    func add(geometry: [any Geometry], bvh: [BVH]) -> GeometryScene {
        GeometryScene(
            lights: lights,
            bvh: self.bvh + bvh,
            geometry: self.geometry + geometry,
            materials: materials
        )
    }
    
    static func bunnyScene(scale: Float = 2) -> GeometryScene {
        objectScene(name: "bunny", scale: scale)
    }
    
    static func dragonScene(scale: Float = 1) -> GeometryScene {
        objectScene(name: "dragon", scale: scale)
    }
    
    static func buddhaScene(scale: Float = 1) -> GeometryScene {
        objectScene(name: "buddha", scale: scale)
    }
    
    static func objectScene(name: String, scale: Float) -> GeometryScene {
        let loaded = try! MeshLoader.load(name: name, material: 0)
        let obj = scale == 1 ? loaded : loaded
            .map {
                Triangle(
                    v1: $0.v1 * scale,
                    v2: $0.v2 * scale,
                    v3: $0.v3 * scale,
                    material: $0.material,
                    reversible: $0.reversible
                )
            }
        print("Scaled")
        let material = BasicMaterial(albedo: .one, specular: .zero, emission: .one)
        
        let bvh = BVH.create(geometry: obj)
        
        return GeometryScene(
            lights: [],
            bvh: [bvh],
            geometry: [],
            materials: [material]
        )
    }
    
    static func bvhTestScene() -> GeometryScene {
        let mat = BasicMaterial(albedo: .one, specular: .one, emission: .zero)
//        let geometry = [
//            Sphere(position: vector_float3(-0.3, 0.25, 0), size: 0.25, material: 0),
//            Sphere(position: vector_float3(0.3, 0.25, 0), size: 0.25, material: 0)
//        ] + stride(from: -0.25, to: 0.25, by: 0.02 * 2).map {
//            Sphere(position: vector_float3(-0.55, 0, Float($0)), size: 0.02, material: 0)
//        }
        
//        let geometry = [
//            Sphere(position: vector_float3(-0.3, 0.25, 0), size: 0.25, material: 0),
//            Sphere(position: vector_float3(0.3, 0.25, 0), size: 0.25, material: 0)
//        ] + stride(from: -0.25, to: 0.25, by: 0.02 * 6).map {
//            Sphere(position: vector_float3(-0.75, 0, Float($0)), size: 0.02, material: 0)
//        }
        
        let geometry = [
            Sphere(position: vector_float3(-0.3, 0.25, 0), size: 0.25, material: 0),
            Sphere(position: vector_float3(0.3, 0.25, 0), size: 0.25, material: 0),
            Sphere(position: vector_float3(0.87, 0.02, -0.25), size: 0.02, material: 0),
            Sphere(position: vector_float3(0.87, 0.02, 0.25), size: 0.02, material: 0),
            Sphere(position: vector_float3(0.87, 0.02, 0.2), size: 0.02, material: 0),
            Sphere(position: vector_float3(0.87, 0.02, -0.2), size: 0.02, material: 0)
        ]
        
        let bvh = BVH.create(geometry: geometry)
        
        return GeometryScene(lights: [], bvh: [bvh], geometry: [], materials: [mat])
    }
    
    func accelerate() -> GeometryScene {
        let areaLights = geometry.filter {
            length(self.materials[Int($0.material)].emission) > 0
        }
        
        return GeometryScene(
            lights: lights,
            bvh: [BVH.create(geometry: geometry)] + bvh,
            geometry: areaLights,
            materials: materials
        )
    }
}
