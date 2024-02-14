//
//  Warp.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 8/21/23.
//

import Foundation

protocol Warp {
    associatedtype Output
    static func warp(generator: inout Generator) -> Output
    static func pdf(warped: Output) -> Double
}

struct WarpToSphere: Warp {
    typealias Output = Vec3
    
    static func warp(generator: inout Generator) -> Vec3 {
        let samples = generator.generateVec2()
        
        let phi = Float.pi * 2 * samples.x
        let theta = acos(1 - 2 * samples.y)
        
        return SIMD3<Float>(
            cos(phi) * cos(theta),
            cos(theta),
            sin(phi) * cos(theta)
        )
    }
    
    static func pdf(warped: Vec3) -> Double {
        1 / 4 / Double.pi
    }
}

struct WarpToHemisphere: Warp {
    typealias Output = Vec3
    
    static func warp(generator: inout Generator) -> Vec3 {
        let samples = generator.generateVec2()
        
        let phi = Float.pi * 2 * samples.x
        let theta = acos(samples.y)
        
        return SIMD3(
            cos(phi) * cos(theta),
            cos(theta),
            sin(phi) * cos(theta)
        )
    }
    
    static func pdf(warped: Vec3) -> Double {
        1 / 2 / Double.pi
    }
}

//struct Warp {
//    func cubeToSphere(x1: Double, x2: Double) -> Vec3 {
//
//    }
//
//    func cubeSpherePdf(_ v: Vec3) -> Double {
//
//    }
//}

protocol Generator: AnyObject {
    func generate() -> Float
}

// Not Pseudo-Random
class RNG: Generator {
    func generate() -> Float { Float.random(in: 0...1) }
}

extension Generator {
    func generate(n: Int) -> [Float] {
        return (0..<n).map { _ in generate() }
    }
    
    func generateVec2() -> SIMD2<Float> {
        SIMD2(generate(), generate())
    }
    
    func generateVec3() -> SIMD3<Float> {
        SIMD3(generate(), generate(), generate())
    }
}

import GameplayKit
class PRNG: Generator {
    let source = GKRandomSource.sharedRandom()
    
    func generate() -> Float { source.nextUniform() }
}

extension SIMD3<Double> {
    var vec: Vec3 { Vec3(Float(x), Float(y), Float(z)) }
}
