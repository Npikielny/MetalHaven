//
//  PMats.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/25/24.
//

import MetalAbstract

struct PMats: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { /*1 / 300*/0 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 1 }
    
    var integrator = ComputeShader.Function(name: "pathMatsIntegrator")
    
    typealias State = ()
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {}
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {}
}
