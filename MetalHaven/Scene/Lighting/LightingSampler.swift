//
//  LightingSampler.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

import Foundation

class LightingSampler {
    let sampler: [AreaLight]
    let totalArea: Float
    
    init(scene: GeometryScene) {
        let basicMats = scene.materials.map { $0 as? BasicMaterial }
        
        var offset = UInt32(0)
        var luminaries = [AreaLight]()
        var totalArea: Float = 0
        for (index, geometry) in scene.geometry.enumerated() {
            guard let mat = basicMats[Int(geometry.material)] else { continue }
            if length(mat.emission) > 0 {
                let area: Float = {
                    switch geometry.geometryType {
                        case SPHERE:
                            let sphere = geometry as! Sphere
                            return 4 * Float.pi * sphere.size * sphere.size
                        case TRIANGLE:
                            let triangle = geometry as! Triangle
                            let s1 = triangle.v2 - triangle.v1
                            let s2 = triangle.v3 - triangle.v1
                            return length(cross(s1, s2)) / 2
                        case NO_GEOMETRY, BOX:
                            print("Non light type \(geometry.geometryType)")
                            return 0
                        default:
                            print("Invalid geometry type \(geometry.geometryType)")
                            return 0
                    }
                }()
                totalArea += area
                luminaries.append(AreaLight(color: mat.emission, index: UInt32(index), start: offset, totalArea: area))
            }
            offset += UInt32(geometry.stride)
        }
        
        self.totalArea = totalArea
        sampler = luminaries
    }
}
