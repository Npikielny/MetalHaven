//
//  Integrator.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

import MetalAbstract

protocol Integrator {
    associatedtype State
    
    init()
    
    var maxIterations: Int? { get }
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> State
    func integrate(
        gpu: GPU,
        state: State,
        rays: Buffer<Ray>,
        intersections: Buffer<Intersection>,
        intersector: Intersector,
        emitters: [Light],
        materials: [Material]
    ) async throws
}

extension Integrator where State == () {
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {
        ()
    }
}
