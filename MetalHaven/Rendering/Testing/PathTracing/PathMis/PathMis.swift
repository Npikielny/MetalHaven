//
//  PathMis.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

import Metal
import MetalAbstract

typealias PathMis = SequencePathTracingView<PathMisIntersector, PathMisIntersector>

class PathMisIntersector: SequenceIntersector {
    var maxIterations: Int? { 10 }
    
    let shader = ComputeShader(
        name: "pathMis",
        threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
        dispatchSize: ThreadGroupDispatchWrapper.buffer
    )
    
    var materials: VoidBuffer!
    let materialDescriptors = Buffer<MaterialDescription>(name: "Material Descriptors")
    var geometry: VoidBuffer!
    let geometryType = Buffer<GeometryType>(name: "Types")
    let objectCount = Buffer<UInt32>(name: "Object Count")
    
    let samplers = Buffer<HaltonSampler>(name: "Samplers")
    var imageSize: SIMD2<Int>!
    
    let areaLight = Buffer<AreaLight>(name: "Area Lights")
    let totalArea = Buffer<Float>(name: "Total Area")
    
    let rng = PRNG()
    
    required init() {}
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {
        geometryType.reset(scene.geometry.map(\.geometryType), usage: .managed)
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
        
        let descriptors: [MaterialDescription] = {
            var out = [MaterialDescription]()
            var total = 0
            for i in scene.materials {
                out.append(MaterialDescription(type: i.type, index: UInt32(total)))
                total += i.stride
            }
            return out
        }()
        
        materialDescriptors.reset(descriptors, usage: .managed)
        
        geometry = VoidBuffer(
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
        
        objectCount.reset([UInt32(scene.geometry.count)], usage: .sparse)
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
        areaLight.reset(lightSampler.lights, usage: .managed)
        totalArea.reset([lightSampler.totalArea], usage: .sparse)
    }
    
    func intersect(gpu: GPU, rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
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
            materials,
            materialDescriptors,
            geometry,
            geometryType,
            objectCount,
            samplers,
            areaLight,
            totalArea,
            indicator
        ]
        
        try await gpu.execute { shader }
    }
}

extension PathMisIntersector: SequenceIntegrator {
    func integrate(gpu: GPU, state: (), rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, intersector: SequenceIntersector, emitters: [Light], materials: [Material]) async throws {}
    
    
}

typealias DirectMis = SequencePathTracingView<DirectMisIntegrator, DirectMisIntegrator>
class DirectMisIntegrator: PathMisIntersector {
    override var maxIterations: Int? { 1 }
}
