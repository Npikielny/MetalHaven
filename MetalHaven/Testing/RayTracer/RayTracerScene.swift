//
//  RayTracerScene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

import Foundation

extension RayTracerView {
    static let width = 512
    static let aspectRatio = Float(16 / 9)

    static let camera = Camera(
        position: .zero,
        forward: SIMD3(0, 0, 1),
        up: SIMD3(0, 1, 0),
        right: SIMD3(1, 0, 0),
        fov: 30 / 180 * Double.pi,
        imageSize: SIMD2(Self.width, Int(Float(Self.width) * Self.aspectRatio))
    )
    
    static var randomScene: GeometryScene = {
        let rand: () -> Float = { Float.random(in: 0...1) }
        let randVec: () -> Vec3 = { Vec3(rand(), rand(), rand()) }
        let materials = (0..<Int.random(in: 3..<10)).map { _ in
            BasicMaterial(albedo: randVec(), specular: .zero, emission: randVec() * rand())
        }
        
        let geometry = (0..<Int.random(in: 15...30)).map { _ in
            Sphere(position: Vec3(rand() * 30 -  15, rand() * 30 - 15, rand() * 30 + 15), size: rand() *  3, material: Int32.random(in: 0..<Int32(materials.count)))
        }
        
        return GeometryScene(lights: [], geometry: geometry, materials: materials)
    }()
    
    static var rayTracerScene = GeometryScene(
        lights: [
            DirectionLight(direction: vector_float3(0.5, -1, 0.1), color: vector_float3(1,1,1)),
            DirectionLight(direction: vector_float3(-0.5, 1, 0.1), color: vector_float3(1,0.5,0.5) * 0.75)
        ],
        geometry: [
            Sphere(position: SIMD3(5, 0, 25), size: 3, material: 0),
            Sphere(position: SIMD3(-3, 3, 30), size: 3, material: 1),
            Sphere(position: SIMD3(0, -302, 30), size: 300, material: 2),
        ],
        materials: [
            BasicMaterial(albedo: .one * 0.8, specular: .one, emission: .zero),
            BasicMaterial(albedo: .one * 0.25, specular: .zero, emission: .one * 0.5),
            BasicMaterial(albedo: Vec3(0.2, 0.7, 0.3), specular: .zero, emission: .zero)
        ]
    )
}
