//
//  BVH.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/26/24.
//

import Foundation

struct BVH {
    static func create(geometry: [Geometry], maxDepth: Float = .infinity) -> BVH {
        let volume = findStructure(geometry: geometry, maxDepth: maxDepth)
        return BVH(volume: volume)
    }
    
    static func findStructure(geometry: [Geometry], maxDepth: Float) -> BoundingVolume {
        if geometry.count <= 1 || maxDepth <= 0 {
            return .leaf(geometry)
        }
        
        let c = geometry[0].centroid
        var box = Box(minimum: c, maximum: c)
        for geometry in geometry {
            geometry.fit(boxMin: &box.minimum, boxMax: &box.maximum)
        }
        
        let size = box.maximum - box.minimum
        let dimension = Dimension.findMax(size)
        let centroids = geometry
            .map(\.centroid)
            .map { $0[dimension] }
            .sorted()
        // could enumerate => sort, but double checking actual work is done...
        
        let midPoint = centroids[centroids.count / 2]
        
        var less = [Geometry]()
        var more = [Geometry]()
        for i in 0..<geometry.count {
            if centroids[i] < midPoint {
                less.append(geometry[i])
            } else {
                more.append(geometry[i])
            }
        }
        
        if less.isEmpty || more.isEmpty {
            return .leaf(geometry)
        }
        
        let L = findStructure(
            geometry: less,
            maxDepth: maxDepth - 1
        )
        
        let M = findStructure(
            geometry: more,
            maxDepth: maxDepth - 1
        )
        
        return .node(
            dimension,
            midPoint,
            box,
            L,
            M
        )
    }
    
    private let tree: BoundingVolume
    
    private init(volume: BoundingVolume) {
        self.tree = volume
        print("Depth", volume.depth())
        
        print(boxes[0].maximum + boxes[0].minimum)
    }
    
    var boxes: [Box] {
        tree.boxes()
    }
}

extension BVH {
    enum Dimension {
        case x
        case y
        case z
        
        func cycle() -> Dimension {
            switch self {
                case .x: return .y
                case .y: return .z
                case .z: return .x
            }
        }
        
        static func findMax(_ vector: SIMD3<Float>) -> Dimension {
            if vector.x > vector.y && vector.x > vector.z {
                return .x
            } else if vector.y > vector.z {
                return .y
            }
            return .z
        }
    }
    
    struct Box {
        var minimum: SIMD3<Float>
        var maximum: SIMD3<Float>
        
        mutating func expandToFit(other: Box) {
            minimum = min(minimum, other.minimum)
            maximum = max(maximum, other.maximum)
        }
    }
    
    enum BoundingVolume {
        case leaf(_ geometry: [any Geometry])
        indirect case node(_ dimension: Dimension, _ split: Float, _ box: Box, _ less: BoundingVolume, _ more: BoundingVolume)
        
        func depth() -> Int {
            switch self {
                case .leaf(_):
                    return 1
                case let .node(_, _, _, l, r):
                    return  max(l.depth(), r.depth()) + 1
            }
        }
        
        func boxes() -> [Box] {
            switch self {
                case .leaf: []
                case let .node(_, _, box, l, r): [box] + l.boxes() + r.boxes()
            }
        }
    }
}

extension SIMD3 {
    subscript(_ index: BVH.Dimension) -> Scalar {
        get {
            switch index {
                case .x: x
                case .y: y
                case .z: z
            }
        }
        set {
            switch index {
                case .x: x = newValue
                case .y: y = newValue
                case .z: z = newValue
            }
        }
    }
}
