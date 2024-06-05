//
//  PMats.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/25/24.
//

import MetalAbstract

struct PMats: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 1 / 300 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 1 }
    
    var integrator = ComputeShader.Function(name: "pathMatsIntegrator")
    
    typealias State = ()
}
