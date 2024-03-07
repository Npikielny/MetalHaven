//
//  PMis.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/21/24.
//

import MetalAbstract

struct PMis: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 0 / 300 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 2 }
    
    var integrator = ComputeShader.Function(name: "pathMisIntegrator")
    
    typealias State = ()
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {}
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {}
}
