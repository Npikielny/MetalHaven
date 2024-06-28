//
//  RayTracer.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

import Metal
import MetalAbstract

class RayTracerIntersector: SequenceIntersector {
    var spheres: Buffer<Sphere>!
    var materials: Buffer<BasicMaterial>!
    
    required init() {}
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    ) {
        spheres = Buffer(scene.geometry as! [Sphere], usage: .managed)
        materials = Buffer(scene.materials as! [BasicMaterial], usage: .managed)
    }
    
    func intersect(gpu: GPU, rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
        try await gpu.execute {
            ComputeShader(
                name: "rayTrace",
                buffers: [
                    rays,
                    intersections,
                    spheres,
                    Buffer([UInt32(spheres.count)], usage: .sparse),
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

class RayTracerIntegrator: SequenceIntegrator {
    typealias State = ()
    var maxIterations: Int? = 8
    
    required init() {}
    
    func integrate(
        gpu: GPU,
        state: (),
        rays: Buffer<ShadingRay>,
        intersections: Buffer<Intersection>,
        intersector: SequenceIntersector,
        emitters: [Light],
        materials: [Material]) async throws {
            let buffer = Buffer(materials as! [BasicMaterial], usage: .managed)
            let shader: ComputeShader = ComputeShader(
                name: "rayTaceShade",
                buffers: [
                    rays,
                    intersections,
                    buffer
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper { size, _ in
                    ThreadGroupDispatchWrapper.groupsForSize(
                        size: size,
                        dispatch: MTLSize(width: intersections.count, height: 1, depth: 1)
                    )
                }
            )
            try await gpu.execute {
                shader
            }
    }
}

extension BasicMaterial: GPUEncodable {}
