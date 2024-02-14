//
//  Sampler.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 8/21/23.
//

import Foundation

class SamplerWrapper {
    let sampler: UnsafeMutablePointer<HaltonSampler>
    
    var seed: UInt32 { sampler.pointee.seed }
    var uses: UInt32 { sampler.pointee.uses }
    
    
    init(seed: UInt32, uses: UInt32) {
        sampler = UnsafeMutablePointer<HaltonSampler>.allocate(capacity: 1)
        sampler.pointee = HaltonSampler(seed: seed, uses: uses)
    }
    
    func uniformSample() -> Float {
        generateSample(sampler)
    }
    
    func sampleHemiSphere() -> SIMD3<Float> {
        let s1 = generateSample(sampler)
        let s2 = generateSample(sampler)
        return sampleUniformHemisphere(SIMD2(s1, s2))
    }
    
    func cosineHemiSphere() -> SIMD3<Float> {
        let s1 = generateSample(sampler)
        let s2 = generateSample(sampler)
        return sampleCosineHemisphere(SIMD2(s1, s2))
    }
}

extension SamplerWrapper {
    static var primes: [Int] {
        [
            2,   3,  5,  7,
            11, 13, 17, 19,
            23, 29, 31, 37,
            41, 43, 47, 53,
            59, 61, 67, 71,
            73, 79, 83, 89
        ]
    }
    
    var prime: Int {
        SamplerWrapper.primes[Int(seed)]
    }
}
