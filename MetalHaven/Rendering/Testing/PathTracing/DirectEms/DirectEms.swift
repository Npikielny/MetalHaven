//
//  PathEms.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 1/12/24.
//

import Metal
import MetalAbstract

typealias DirectEms = SequencePathTracingView<DirectEmsIntersector, DirectEmsIntersector>

class DirectEmsIntersector: SequenceIntersector, SequenceIntegrator {
    var maxIterations: Int? { 1 }
    
    let shader = ComputeShader(
        name: "directEms",
        threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
        dispatchSize: ThreadGroupDispatchWrapper.buffer
    )
    
    var materialBuffer: VoidBuffer!
    let materialDescriptorBuffer = Buffer<MaterialDescription>(name: "Material Descriptors")
    var sceneBuffer: VoidBuffer!
    let typeBuffer = Buffer<GeometryType>(name: "Types")
    let objectCountBuffer = Buffer<UInt32>(name: "Object Count")
    
    let samplers = Buffer<HaltonSampler>(name: "Samplers")
    var imageSize: SIMD2<Int>!
    
    let areaLightBuffer = Buffer<AreaLight>(name: "Area Lights")
    let totalAreaBuffer = Buffer<Float>(name: "Total Area")
    
    let rng = PRNG()
    
    required init() {}
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    ) {
        typeBuffer.reset(scene.geometry.map(\.geometryType), usage: .managed)
        materialBuffer = VoidBuffer(
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
        
        let descriptors: [MaterialDescription] = {
            var out = [MaterialDescription]()
            var total = 0
            for i in scene.materials {
                out.append(MaterialDescription(type: i.type, index: UInt32(total)))
                total += i.stride
            }
            return out
        }()
        
        materialDescriptorBuffer.reset(descriptors, usage: .managed)
        
        sceneBuffer = VoidBuffer(
            name: "objects",
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
        
        objectCountBuffer.reset([UInt32(scene.geometry.count)], usage: .sparse)
        samplers.reset(
            samplers.generate(
                rng: rng,
                maxSeed: 1024,
                count: imageSize.x * imageSize.y
            ),
            usage: .managed
        )
        self.imageSize = imageSize
        let lightSampler = LightingSampler(scene: scene)
        areaLightBuffer.reset(lightSampler.lights, usage: .managed)
        totalAreaBuffer.reset([lightSampler.totalArea], usage: .sparse)
    }
    
    func intersect(gpu: GPU, rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
        indicator[0] = false
        if rng.generate() < 1 / 100 {
            print("new rng")
            samplers.reset(
                samplers.generate(
                    rng: rng,
                    maxSeed: 1024,
                    count: imageSize.x * imageSize.y
                ),
                usage: .managed
            )
        }
        
        shader.buffers =  [
            rays,
            Buffer([UInt32(rays.count)], usage: .sparse),
            intersections,
            materialBuffer,
            materialDescriptorBuffer,
            sceneBuffer,
            typeBuffer,
            objectCountBuffer,
            samplers,
            areaLightBuffer,
            totalAreaBuffer,
            indicator
        ]
        
        try await gpu.execute { shader }
    }
    
    func integrate(gpu: GPU, state: (), rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, intersector: SequenceIntersector, emitters: [Light], materials: [Material]) async throws {
        
    }
}

extension VoidBuffer {
    static func copy(geom: some Geometry, ptr: UnsafeMutableRawPointer) -> Int {
        memcpy(ptr, [geom], geom.stride)
        return geom.stride
    }
    
    static func copy(mat: some Material, ptr: UnsafeMutableRawPointer) -> Int {
        memcpy(ptr, [mat], mat.stride)
        return mat.stride
    }
}

extension AreaLight: GPUEncodable {}
