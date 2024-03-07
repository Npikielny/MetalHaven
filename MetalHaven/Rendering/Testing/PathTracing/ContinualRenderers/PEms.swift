//
//  PEms.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/25/24.
//

import MetalAbstract

struct PEms: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 1 / 300 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 2 }
    
    var integrator = ComputeShader.Function(name: "pathEmsIntegrator")
    
    typealias State = ()
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {}
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {}
}

