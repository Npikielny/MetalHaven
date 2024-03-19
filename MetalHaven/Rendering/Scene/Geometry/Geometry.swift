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
    
    func intersect(ray: Ray) -> Intersection
//    func sample(sample: SIMD2<Float>) -> (position: SIMD2<Float>, normal: SIMD2<Float>)
}

extension Geometry {
    var stride: Int { Self.stride }
    static var stride: Int {
        MemoryLayout<Self>.stride
    }
    
}

extension Sphere: Geometry, GPUEncodable {
    var geometryType: GeometryType { SPHERE }
    
//    func sample(sample: SIMD2<Float>) -> (position: SIMD2<Float>, normal: SIMD2<Float>) {
//        sampleSphere(<#T##sample: vector_float2##vector_float2#>)
//    }
}
//extension Box: Geometry {
//    var geometryType: GeometryType { BOX }
//}

extension Triangle: GPUEncodable, Geometry {
    var geometryType: GeometryType { TRIANGLE }
}

extension Plane: GPUEncodable, Geometry {
    var geometryType: GeometryType { PLANE }
    
}

extension Square: GPUEncodable, Geometry {
    var geometryType: GeometryType { SQUARE }
}

extension GeometryType: CaseIterable, GPUEncodable {
    public static var allCases: [GeometryType] {
        [SPHERE, TRIANGLE, PLANE, SQUARE]
    }
    
    var type: Geometry.Type {
        switch self {
            case SPHERE: return Sphere.self
//            case BOX: return Box.self
            case TRIANGLE: return Triangle.self
            case SQUARE: return Square.self
            case PLANE: return Plane.self
                
            default: fatalError()
        }
    }
    
    static var strides: [Int] {
        GeometryType.allCases
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.type.stride }
    }
}
