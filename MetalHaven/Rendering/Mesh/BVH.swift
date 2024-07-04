//
//  BVH.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/26/24.
//

import Foundation
import MetalAbstract

struct BVH {
    static func create(geometry: [Geometry], maxDepth: Float = .infinity) -> BVH {
        let volume = findStructure(geometry: geometry, maxDepth: maxDepth)
        return BVH(volume: volume)
    }
    
    private static func fitToBox(fitting: [any Fitable]) -> Box {
        let first = fitting[0].centroid
        var box = Box(minimum: first, maximum: first)
        for f in fitting {
            f.fit(boxMin: &box.minimum, boxMax: &box.maximum)
        }
        return box
    }
    
    static func findStructure(geometry: [Geometry], maxDepth: Float) -> BoundingVolume {
        let box = fitToBox(fitting: geometry)
        if geometry.count == 1 || maxDepth <= 0 {
            return .leaf(box, geometry)
        }
        
        let centroids = geometry.map(\.centroid)
        let mean = centroids.reduce(.zero, +) / Float(geometry.count)
        let size = box.maximum - box.minimum
        let dimension = Dimension.findMax(size)
//        let centroids = geometry
//            .map(\.centroid)
//            .map { $0[dimension] }
//            .sorted()
//        // could enumerate => sort, but double checking actual work is done...
//        
//        let midPoint = centroids[centroids.count / 2]
        let midPoint = mean[dimension]
        
        var less = [Geometry]()
        var more = [Geometry]()
        for i in geometry {
            if i.centroid[dimension] < midPoint {
                less.append(i)
            } else {
                more.append(i)
            }
        }
        
        if less.count <= 1 || more.count <= 1 {
            return .leaf(box, geometry)
        }
        
        return .node(
            dimension,
            midPoint,
            box,
            findStructure(
                geometry: less,
                maxDepth: maxDepth - 1
            ),
            findStructure(
                geometry: more,
                maxDepth: maxDepth - 1
            )
        )
    }
    
    let tree: BoundingVolume
    
    private init(volume: BoundingVolume) {
        self.tree = volume
        print("Depth", volume.depth())
        
        print("Centroid ig", boxes[0].maximum + boxes[0].minimum)
    }
    
    var boxes: [Box] {
        tree.boxes()
    }
    
    func compile(boundingBoxOffset: inout Int, geometryOffset: inout Int, geometryCount: inout Int) -> ([BoundingBox], [any Geometry]) {
        var remainingVolumes = [BoundingVolume]()
        remainingVolumes.append(tree)
        
        var boxes = [BoundingBox]()
        var geometry = [any Geometry]()
        
        while !remainingVolumes.isEmpty {
            guard let current = remainingVolumes.first else { continue }
            remainingVolumes.remove(at: 0)
            switch current {
                case let .leaf(box, geo):
                    boxes.append(
                        BoundingBox(
                            min: box.minimum,
                            max: box.maximum,
                            start: UInt32(geometryOffset),
                            count: vector_uint2(UInt32(geometryCount), UInt32(geo.count))
                        )
                    )
                    geometryCount += geo.count
                    geometryOffset += geo.map(\.stride).reduce(0, +)
                    
                    geometry.append(contentsOf: geo)
                case let .node(_, _, box, left, right):
                    boxes.append(BoundingBox(
                        min: box.minimum,
                        max: box.maximum,
                        start: UInt32(boundingBoxOffset + 1),
                        count: .zero)
                    )
                    boundingBoxOffset += 2
                    
                    remainingVolumes.append(left)
                    remainingVolumes.append(right)
            }
        }
        return (boxes, geometry)
    }
    
    private static func _merge(_ bvhs: [BVH]) -> BoundingVolume {
        let box = fitToBox(fitting: bvhs)
        if bvhs.count == 1 {
            return bvhs[0].tree
        }
        
        let size = box.maximum - box.minimum
        let dimension = Dimension.findMax(size)
        let centroids = bvhs
            .map(\.centroid)
            .map { $0[dimension] }
            .sorted()
        // could enumerate => sort, but double checking actual work is done...
        
        let midPoint = centroids[centroids.count / 2]
        
        var less = [BVH]()
        var more = [BVH]()
        for i in 0..<bvhs.count {
            if centroids[i] < midPoint {
                less.append(bvhs[i])
            } else {
                more.append(bvhs[i])
            }
        }
        
        return .node(
            dimension,
            midPoint,
            box,
            _merge(less),
            _merge(more)
        )
    }
    
    static func merge(_ bvhs: [BVH]) -> BVH {
        let tree = _merge(bvhs)
        return BVH(volume: tree)
    }
    
    static func compile(_ bvhs: [BVH], geometryOffset: Int, geometryCountOffset: Int) -> ([BoundingBox], [any Geometry]) {
        let merged = merge(bvhs)
        
        var boundingBoxOffset = 0
        var geometryOffset = geometryOffset
        var geometryCount = geometryCountOffset
        
        var boxes = [BoundingBox]()
        var geometry = [any Geometry]()
        
        let (box, geo) = merged.compile(boundingBoxOffset: &boundingBoxOffset, geometryOffset: &geometryOffset, geometryCount: &geometryCount)
//        for (index, b) in box.enumerated() {
//            print("BOX", index, b.start, b.min, b.max, b.count.y == 0 ? "Node" : "Leaf")
//        }
        boxes.append(contentsOf: box)
        geometry.append(contentsOf: geo)
        
        return (boxes, geometry)
    }
}

extension BVH: Fitable {
    var centroid: SIMD3<Float> { tree.centroid }
    
    func fit(boxMin: inout SIMD3<Float>, boxMax: inout SIMD3<Float>) {
        tree.fit(boxMin: &boxMin, boxMax: &boxMax)
    }
}

extension BVH.BoundingVolume {
    var centroid: SIMD3<Float> {
        switch self {
            case let .leaf(box, _), let .node(_, _, box, _, _): (box.maximum + box.minimum) / 2
        }
    }
    
    func fit(boxMin: inout SIMD3<Float>, boxMax: inout SIMD3<Float>) {
        switch self {
            case let .leaf(box, _), let .node(_, _, box, _, _):
                boxMin = min(boxMin, box.minimum)
                boxMax = min(boxMax, box.maximum)
        }
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
        
//        mutating func expandToFit(other: Box) {
//            minimum = min(minimum, other.minimum)
//            maximum = max(maximum, other.maximum)
//        }
    }
    
    enum BoundingVolume {
        case leaf(_ box: Box, _ geometry: [any Geometry])
        indirect case node(_ dimension: Dimension, _ split: Float, _ box: Box, _ less: BoundingVolume, _ more: BoundingVolume)
        
        func depth() -> Int {
            switch self {
                case .leaf(_, _):
                    return 1
                case let .node(_, _, _, l, r):
                    return  max(l.depth(), r.depth()) + 1
            }
        }
        
        private func leafsHelper() -> SIMD2<Int> {
            switch self {
                case let .leaf(_, geo):
                    return SIMD2(1, geo.count)
                case let .node(_, _, _, l, r):
                    return l.leafsHelper() &+ r.leafsHelper()
            }
        }
        
        func leafs() -> (count: Int, geometry: Int) {
            let res = leafsHelper()
            return (res.x, res.y)
        }
        
        func boxes() -> [Box] {
            switch self {
                case let .leaf(box, _): [box]
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

extension BoundingBox: GPUEncodable {}

class DoublyLinkedList<T> {
    private var head: Node
    private var tail: Node
    
    init() {
        self.head = Node()
        self.tail = Node()
        head.next = tail
        tail.previous = head
    }
    
    func prepend(_ value: T) {
        let new = Node()
        new.next = head.next
        head.next = new
        new.previous = head
    }
    
    func append(_ value: T) {
        let new = Node()
        new.previous = tail.previous
        new.next = tail
        tail.previous = new
    }
    
    func popLast() -> T? {
        if let popping = tail.previous, popping != head {
            tail.previous = popping.previous
            popping.previous?.next = tail
            return popping.value
        }
        return nil
    }
    
    func popFirst() -> T? {
        if let popping = head.next, popping != tail {
            head.next = popping.next
            popping.next?.previous = head
            return popping.value
        }
        return nil
    }
    
    var isEmpty: Bool { head == tail }
    
    private class Node: Equatable {
        var id = UUID()
        var previous: Node?
        var next: Node?
        var value: T?
        
        init(previous: Node? = nil, next: Node? = nil, value: T? = nil) {
            self.previous = previous
            self.next = next
            self.value = value
        }
        
        static func == (lhs: DoublyLinkedList<T>.Node, rhs: DoublyLinkedList<T>.Node) -> Bool {
            lhs.id == rhs.id
        }
    }
}
