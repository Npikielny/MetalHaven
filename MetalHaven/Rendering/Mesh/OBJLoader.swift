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
        let lines = content.split(separator: "\n")
        
//        for line in lines {
//            print(line)
//        }
        
        let (info, admin) = lines.split { $0.contains("#") }
        print("ADMIN", admin)
        
        let sorted = info.sort { line -> OBJ in
            if line.contains("f") { return .f }
            if line.contains("vn") { return .vn }
            if line.contains("v") { return .v }
            return .other
        }
        
        let verts = sorted[.v]!
            .map {
                let floats = $0
                    .split(separator: " ")
                    .compactMap { Float($0) }
                return SIMD3(floats[0], floats[1], floats[2])
            }
        
        let faces: [[Int]] = sorted[.f]!.map { row -> [Int] in
            String(row)
                .components(separatedBy: .whitespaces)[1...]
                .compactMap { messyIndex -> Int? in
                    let slash = String(messyIndex).firstIndex(of: "/")!
                    return Int(String(String(messyIndex)[..<slash]))
                }
                .map { $0 - 1 }
        }
        
        return faces.map { indices -> Triangle in
            Triangle(v1: verts[indices[0]], v2: verts[indices[1]], v3: verts[indices[2]], material: materialId, reversible: DIRECTIONAL)
        }
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
