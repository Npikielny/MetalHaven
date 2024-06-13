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
    var reflectance: SIMD3<Float> { get }
    var emission: SIMD3<Float> { get }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3)
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double
}

extension Material {
    var stride: Int { Self.stride }
    static var stride: Int {
        MemoryLayout<Self>.stride
    }
    var emission: SIMD3<Float> { .zero }
}

extension BasicMaterial: Material {
    var reflectance: SIMD3<Float> { albedo }
    
    var type: MaterialType { BASIC }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3) {
        let sample = WarpToHemisphere.warp(generator: &generator)
        return (sample, pdf(incident: incident, outgoing: sample), albedo)
    }
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double {
        WarpToHemisphere.pdf(warped: outgoing)
    }
    
    
}

extension MirrorMat: Material {
    var type: MaterialType { MIRROR }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3) {
        let normal = Vec3(0, 1, 0)
        return (incident + abs(dot(normal, incident)) * normal * 2, 1, reflectance)
    }
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double {
        let normal = Vec3(0, 1, 0)
        let correct = incident + abs(dot(normal, incident)) * normal * 2
        return distance(correct, outgoing) < 1e-4 ? 1 : 0
    }
}

extension Dielectric: Material {
    var type: MaterialType { DIELECTRIC }
    
    func sample(generator: inout Generator, incident: Vec3) -> (outgoing: Vec3, pdf: Double, throughput: Vec3) {
        let normal = Vec3(0, 1, 0)
        return (incident + abs(dot(normal, incident)) * normal * 2, 1, reflectance)
    }
    
    func pdf(incident: Vec3, outgoing: Vec3) -> Double {
        let normal = Vec3(0, 1, 0)
        let correct = incident + abs(dot(normal, incident)) * normal * 2
        return distance(correct, outgoing) < 1e-4 ? 1 : 0
    }
}




extension MaterialDescription: GPUEncodable {}
