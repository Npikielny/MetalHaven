//
//  Geometry.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/23.
//

import MetalAbstract

protocol Geometry {
    var centroid:  SIMD3<Float> { get }
    //    var position: SIMD3<Float> { get set }
    var material: Int32 { get set }
    var geometryType: GeometryType { get }
    
    func intersect(ray: Ray) -> Intersection
    //    func sample(sample: SIMD2<Float>) -> (position: SIMD2<Float>, normal: SIMD2<Float>)
    
    func fit(boxMin: inout SIMD3<Float>, boxMax: inout SIMD3<Float>)
}

extension Geometry {
    var stride: Int { Self.stride }
    static var stride: Int {
        MemoryLayout<Self>.stride
    }
    
}

extension Sphere: Geometry, GPUEncodable {
    func fit(boxMin: inout SIMD3<Float>, boxMax: inout SIMD3<Float>) {
        boxMin = min(boxMin, position - size)
        boxMax = min(boxMax, position + size)
    }
    
    var centroid: SIMD3<Float> { position }
    var geometryType: GeometryType { SPHERE }
}

protocol TriangleRepresentation: GPUEncodable, Geometry {
    var v1: vector_float3 { get }
    var v2: vector_float3 { get }
    var v3: vector_float3 { get }
}

extension TriangleRepresentation {
    var centroid: SIMD3<Float> {
        (v1 + v2 + v3) / 3
    }
    
    func fit(boxMin: inout SIMD3<Float>, boxMax: inout SIMD3<Float>) {
        boxMin = min(min(min(boxMin, v1), v2), v3)
        boxMax = max(max(max(boxMax, v1), v2), v3)
    }
}

extension Triangle: TriangleRepresentation {
    var geometryType: GeometryType { TRIANGLE }
}

extension Plane: TriangleRepresentation {
    var geometryType: GeometryType { PLANE }
}

extension Square: TriangleRepresentation {
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
