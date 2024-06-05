//
//  MPSIntersector.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/13/24.
//

import Metal
import MetalAbstract

class TriangleIntersector: SequenceIntersector, SequenceIntegrator {
    static let integrator = ComputeShader.Function(name: "integrateTriangle")
    
    required init() {}
    
    func intersect(gpu: GPU, rays: Buffer<Ray>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
        
    }
    
    var maxIterations: Int? = 1
    
    func integrate(gpu: GPU, state: (), rays: Buffer<Ray>, intersections: Buffer<Intersection>, intersector: SequenceIntersector, emitters: [Light], materials: [Material]) async throws {
        try await gpu.execute {
            ComputeShader(
                function: Self.integrator,
                buffers: [
                    rays,
                    Buffer([UInt32(rays.count)], usage: .sparse)
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper.buffer
            )
        }
    }
}
