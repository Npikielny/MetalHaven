//
//  Material.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 8/21/23.
//

import MetalAbstract

typealias Vec3 = SIMD3<Float>

struct BounceQuery {
    var incident: Vec3
    var outgoing: Vec3
}

struct Bounce {
    var query: BounceQuery
    var pdf: Double
    var throughput: Vec3
}

protocol Material {
    var type: MaterialType { get }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3)
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double
}

extension Material {
    var stride: Int { Self.stride }
    static var stride: Int {
        MemoryLayout<Self>.stride
    }
}

extension BasicMaterial: Material {
    var type: MaterialType { BASIC }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3) {
        let sample = WarpToHemisphere.warp(generator: &generator)
        return (sample, pdf(incident: incident, outgoing: sample), albedo)
    }
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double {
        WarpToHemisphere.pdf(warped: outgoing)
    }
    
    
}

extension MaterialDescription: GPUEncodable {}
