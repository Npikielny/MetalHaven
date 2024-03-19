//
//  LightingSampler.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

import Foundation

class LightingSampler {
    let lights: [AreaLight]
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
                        case SQUARE:
                            let square = geometry as! Square
                            let s1 = square.v2 - square.v1
                            let s2 = square.v3 - square.v1
                            return length(cross(s1, s2))
                            //                            return sqrt(dot(s1, s1) * dot(s2, s2))
                        default:
                            print("Non light type \(geometry.geometryType)")
                            return 0
                    }
                }()
                totalArea += area
                luminaries.append(AreaLight(color: mat.emission, index: UInt32(index), start: offset, totalArea: area))
            }
            offset += UInt32(geometry.stride)
        }
        print(totalArea)
        self.totalArea = totalArea
        lights = luminaries
    }
    
    func sample(samples: SIMD3<Float>, geometry: [any Geometry]) -> LuminarySample {
        var integrated = Float(0)
        var lightIndex = 0
        while integrated < samples.x * totalArea {
            integrated += lights[lightIndex].totalArea
            lightIndex += 1
        }
        lightIndex = max(lightIndex == 0 ? 0 : lightIndex - 1, 0)
        
        let light = lights[lightIndex]
        
        let geometry = geometry[Int(light.index)]
        
        let sample = SIMD2<Float>(samples.y, samples.z)
        var luminarySample = switch geometry.geometryType {
        case TRIANGLE: sampleLuminaryTriangle(geometry as! Triangle, sample)
        case SPHERE: sampleLuminarySphere(geometry as! Sphere, sample)
        case SQUARE: sampleLuminarySquare(geometry as! Square, sample)
        default: fatalError()
        }
        
        luminarySample.emission = light.color
        luminarySample.lightId = UInt32(lightIndex)
        return luminarySample
    }
}
