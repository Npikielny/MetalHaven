//
//  Testing.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

import Metal
import MetalAbstract

extension DirectionalTestingView {
    static let width = 64
    static let AspectRatio = Float(16 / 9)
    
    static let testCamera = Camera(
        position: .zero,
        forward: SIMD3(0, 0, 1),
        up: SIMD3(0, 1, 0),
        right: SIMD3(1, 0, 0),
        fov: 30 / 180 * Double.pi,
        imageSize: SIMD2(width, Int(Float(width) * AspectRatio))
    )
    
    static var testScene = GeometryScene(
        lights: [
            DirectionLight(direction: vector_float3(0.5, -1, 0.1), color: vector_float3(1,1,1)),
            DirectionLight(direction: vector_float3(-0.5, 1, 0.1), color: vector_float3(1,0.5,0.5) * 0.75)
        ],
        geometry: [
            Sphere(position: SIMD3(5, 0, 25), size: 3, material: 0),
            Sphere(position: SIMD3(-5, 0, 25), size: 3, material: 1)
        ],
        materials: [
            BasicMaterial(albedo: vector_float3(1, 0, 0), specular: .zero, emission: vector_float3(0, 0, 0)),
            BasicMaterial(albedo: vector_float3(0, 0, 1), specular: .zero, emission: vector_float3(0, 1, 0))
        ]
    )
}

class DirectionalTestIntersector: SequenceIntersector {
    var geometryBuffer: Buffer<Sphere>! = nil
    
    required init() {}
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    ) {
        geometryBuffer = Buffer(scene.geometry as! [Sphere], usage: .managed)
    }
    
    func intersect(gpu: GPU, rays: Buffer<Ray>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
        try await gpu.execute {
            ComputeShader(
                name: "directionalTesting",
                buffers: [
                    rays,
                    intersections,
                    geometryBuffer,
                    Buffer([UInt32(geometryBuffer.count)], usage: .sparse),
                    indicator
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper { size, _ in
                    ThreadGroupDispatchWrapper.groupsForSize(
                        size: size,
                        dispatch: MTLSize(width: intersections.count, height: 1, depth: 1)
                    )
                }
            )
        }
    }
}

class DirectionalTestIntegrator: SequenceIntegrator {
    typealias State = ()
    
    var maxIterations: Int? = 8
    
    required init() {}
    
    func integrate(
        gpu: GPU,
        state: (),
        rays: Buffer<Ray>,
        intersections: Buffer<Intersection>,
        intersector: SequenceIntersector,
        emitters: [Light],
        materials: [Material]
    ) async throws {
        let diffuseMats = materials as! [BasicMaterial]
        let lights = await (DirectionalTestingView.testScene.lights as! [DirectionLight])
        for i in 0..<intersections.count {
            guard let intersection = intersections[i] else { print("No intersection"); continue }
            if intersection.t != Float.infinity {
                for light in lights {
                    rays[i]?.result += /*max(0, dot(intersection.n, -normalize(light.direction))) * light.color **/0.1 * diffuseMats[Int(intersection.materialId)].albedo
                }
            }
        }
    }
}
