//
//  BunnyScene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/27/24.
//

import Foundation

extension GeometryScene {
    static func bunnyScene(scale: Float = 2) -> GeometryScene {
        let bunny = try! MeshLoader.load(name: "bunny", material: 0)
            .map {
                Triangle(
                    v1: $0.v1 * scale,
                    v2: $0.v2 * scale,
                    v3: $0.v3 * scale,
                    material: $0.material,
                    reversible: $0.reversible
                )
            }
        let material = BasicMaterial(albedo: .one, specular: .zero, emission: .one)
        
        return GeometryScene(
            lights: [],
            geometry: bunny,
            materials: [material]
        )
    }
}
