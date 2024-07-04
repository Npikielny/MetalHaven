//
//  OBJLoader.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/27/24.
//

import Foundation

struct MeshLoader {
    static func load(name: String, material: Int32) throws -> [Triangle] {
        guard let file = Bundle.main.url(forResource: name, withExtension: "obj") else {
            throw AnyError(desc: "Unable to find file for \(name)")
        }
        
        return try load(path: file.path, materialId: material)
    }
    
    static func load(path: String, materialId: Int32) throws -> [Triangle] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        print("Read content of \(path)")
        
//        let lines = content.split(separator: "\n")
        let lines = content.components(separatedBy: .newlines)
        
//        for line in lines {
//            print(line)
//        }
        
        let (info, admin) = lines.split { $0.contains("#") }
        print("ADMIN")
        for line in admin {
            print(line)
        }
        
        print("Sorting")
        let sorted = info.sort { line -> OBJ in
            if line.hasPrefix("f") { return .f }
            if line.hasPrefix("vn") { return .vn }
            if line.hasPrefix("v")  { return .v }
            return .other
        }
        print("Sorted")
        
        let verts = sorted[.v]!
            .map {
                let floats = $0
                    .split(separator: " ")
                    .compactMap { Float($0) }
                return SIMD3(floats[0], floats[1], floats[2])
            }
        print("Got verts \(verts.count)")
        
        let faces: [[Int]] = sorted[.f]!.map { row -> [Int] in // vertex_index/texture_index/normal_index
            String(row)
                .components(separatedBy: .whitespaces)[1...]
                .compactMap { messyIndex -> Int? in
                    guard let slash = String(messyIndex).firstIndex(of: "/") else {
                        print("Failed", messyIndex)
                        return nil
                    }
                    guard let res = Int(String(String(messyIndex)[..<slash])) else {
                        print("Faiiled \(messyIndex)")
                        return nil
                    }
//                    assert(res >= 0)
//                    assert {
//                        res >= 0
//                    }
                    return res
                }
                .map { $0 - 1 }
        }
        print("Got faces \(faces.count)")
        
        let result = faces.map { indices -> Triangle in
            Triangle(v1: verts[indices[0]], v2: verts[indices[2]], v3: verts[indices[1]], material: materialId, reversible: REVERSIBLE)
        }
        print("Created triangles")
        return result
    }
    
    enum OBJ {
        case v
        case vn
        case f
        case other
    }
}

extension Array {
    func split(mask: [Bool]) -> (false: Self, true: Self) {
        var `true` = [Element]()
        var `false` = [Element]()
        
        for (elt, dest) in zip(self, mask) {
            if dest {
                `true`.append(elt)
            } else {
                `false`.append(elt)
            }
        }
        return (`false`, `true`)
    }
    
    func split(predicate: (Element) -> Bool) -> (false: Self, true: Self) {
        var `true` = [Element]()
        var `false` = [Element]()
        
        for elt in self {
            if predicate(elt) {
                `true`.append(elt)
            } else {
                `false`.append(elt)
            }
        }
        return (`false`, `true`)
    }
    
    func sort<T: Hashable>(predicate: (Element) -> T) -> [T: [Element]] {
        var out = [T: [Element]]()
        
        for elt in self {
            let dest = predicate(elt)
            if let _ = out[dest] {
                out[dest]!.append(elt)
            } else {
                out[dest] = [elt]
            }
        }
        return out
    }
}
