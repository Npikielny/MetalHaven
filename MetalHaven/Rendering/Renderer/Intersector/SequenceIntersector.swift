//
//  Intersector.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/13/23.
//

import MetalAbstract

protocol Intersector {
    init()
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    )
}

protocol SequenceIntersector: Intersector {
    init()
    
    func intersect(
        gpu: GPU,
        rays: Buffer<Ray>,
        intersections: Buffer<Intersection>,
        indicator: Buffer<Bool>
    ) async throws
}
