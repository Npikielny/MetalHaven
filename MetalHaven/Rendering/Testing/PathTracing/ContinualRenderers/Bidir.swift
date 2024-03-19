//
//  Bidir.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/8/24.
//

import MetalAbstract

struct Bidir: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 1 / 300 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 3 }
    
    var integrator = ComputeShader.Function(name: "bidir")
    
    typealias State = ()
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {}
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {}
}
