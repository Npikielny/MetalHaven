//
//  DefaultIntersector.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/13/23.
//

import Metal
import MetalAbstract

// Only intersects with scene
class PassIntersector: SequenceIntersector {
    var geometryBuffer: VoidBuffer! = nil
    
    required init() {}
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    ) {
        
    }
    
    func intersect(
        gpu: GPU,
        rays: Buffer<Ray>,
        intersections: Buffer<Intersection>,
        indicator: Buffer<Bool>
    ) async {
        
    }
    
    
}

class PassIntegrator: SequenceIntegrator {
    required init() {}
    
    var maxIterations: Int? = 30
    
    func integrate(gpu: GPU, state: (), rays: Buffer<Ray>, intersections: Buffer<Intersection>, intersector: SequenceIntersector, emitters: [Light], materials: [Material]) async throws {
        
    }
    
    
}
