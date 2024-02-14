//
//  Geometry.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/23.
//

import MetalAbstract

protocol Geometry {
//    var position: SIMD3<Float> { get set }
    var material: Int32 { get set }
    var geometryType: GeometryType { get }
}

extension Geometry {
    var stride: Int { Self.stride }
    static var stride: Int {
        MemoryLayout<Self>.stride
    }
}

extension Sphere: Geometry, GPUEncodable {
    var geometryType: GeometryType { SPHERE }
}
extension Box: Geometry {
    var geometryType: GeometryType { BOX }
}

extension GeometryType: CaseIterable, GPUEncodable {
    public static var allCases: [GeometryType] {
        [SPHERE, BOX]
    }
    
    var type: Geometry.Type {
        switch self {
            case SPHERE: return Sphere.self
            case BOX: return Box.self
            default: fatalError()
        }
    }
    
    static var strides: [Int] {
        GeometryType.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.type.stride }
    }
}
