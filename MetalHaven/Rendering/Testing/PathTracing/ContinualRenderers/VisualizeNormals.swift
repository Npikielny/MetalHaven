//
//  VisualizeNormals.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/23/24.
//

import MetalAbstract

struct VisualizeNormals: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 0 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 1 }
    
    var integrator = ComputeShader.Function(name: "visualizeNormals")
    
    typealias State = ()
}
