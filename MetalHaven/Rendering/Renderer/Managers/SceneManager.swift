//
//  SceneManager.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

import MetalAbstract

class SceneManager {
    var scene: GeometryScene
    
    var geometry: VoidBuffer
    var geometryTypes: Buffer<GeometryType>
    var objectCount: Buffer<UInt32>
    
    var materials: VoidBuffer
    var materialTypes: Buffer<MaterialDescription>
    
    var lightingSampler: LightingSampler?
    var lights: Buffer<AreaLight>?
    var emittingArea: Buffer<Float>? // Area of emitters
    
    init(scene: GeometryScene) {
        self.scene = scene
        
        geometry = VoidBuffer(
            name: "Geometry",
            future: { gpu in
                guard let buf = gpu.device.makeBuffer(
                    length: scene.geometry.map(\.stride).reduce(0, +),
                    options: .storageModeManaged
                ) else { return nil }
                
                var offset = 0
                for obj in scene.geometry {
                    offset += VoidBuffer.copy(geom: obj, ptr: buf.contents() + offset)
                }
                buf.didModifyRange(0..<buf.length)
                
                return (buf, scene.geometry.count)
        },
            usage: .managed
        )
        geometryTypes = Buffer(scene.geometry.map(\.geometryType), usage: .managed)
        objectCount = Buffer(name: "Object Count", [UInt32(scene.geometry.count)], usage: .managed)
        
        let descriptors: [MaterialDescription] = {
            var out = [MaterialDescription]()
            var total = 0
            for i in scene.materials {
                out.append(MaterialDescription(type: i.type, index: UInt32(total)))
                total += i.stride
            }
            return out
        }()
        
        materialTypes = Buffer(name: "Material Types", descriptors, usage: .managed)
        
        materials = VoidBuffer(
            name: "Materials",
            future: { gpu in
                guard let buf = gpu.device.makeBuffer(
                    length: scene.materials.map(\.stride).reduce(0, +),
                    options: .storageModeManaged
                ) else { return nil }
                
                var offset = 0
                for mat in scene.materials {
                    offset += VoidBuffer.copy(mat: mat, ptr: buf.contents() + offset)
                }
                buf.didModifyRange(0..<buf.length)
                
                return (buf, scene.geometry.count)
            },
            usage: .managed
        )
        
        if length(scene.materials.map(\.emission).reduce(.zero, +)) > 0 {
            let sampler = LightingSampler(scene: scene)
            lightingSampler = sampler
            lights = Buffer(name: "Lights", sampler.lights, usage: .managed)
            emittingArea = Buffer(name: "Emitting Area", [sampler.totalArea], usage: .managed)
        }
    }
}
