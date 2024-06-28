//
//  PathMats.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/16/23.
//

import Metal
import MetalAbstract

// Material Sampling
typealias PathMats = SequencePathTracingView<PathMatsIntegrator, PathMatsIntegrator>

class PathMatsIntegrator: SequenceIntegrator, SequenceIntersector {
    typealias State = ()
    var maxIterations: Int? = 30
    var generator: Generator = PRNG()
    
    let shading = ComputeShader(
        name: "pathMatsShading",
        threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
        dispatchSize: ThreadGroupDispatchWrapper.buffer
    )
    
    let rng = PRNG()
    
    var materialBuffer: VoidBuffer!
    let materialDescriptorBuffer = Buffer<MaterialDescription>(name: "Material Descriptors")
    var sceneBuffer: VoidBuffer!
    let typeBuffer = Buffer<GeometryType>(name: "Types")
    let objectCountBuffer = Buffer<UInt32>(name: "Object Count")
    
    let samplers = Buffer<HaltonSampler>(name: "Samplers")
    var imageSize: SIMD2<Int>!
    
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
    }
    
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {
        samplers.reset(
            samplers.generate(rng: rng, maxSeed: 1024, count: imageSize.x * imageSize.y),
        usage: .managed)
    }
    
    func integrate(gpu: GPU, state: (), rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, intersector: SequenceIntersector, emitters: [Light], materials: [Material]) async throws {
        if rng.generate() < 1 / 150 {
            print("new rng")
            samplers.reset(
                samplers.generate(
                    rng: rng,
                    maxSeed: 1024,
                    count: samplers.count
                ),
                usage: .managed
            )
        }
        
        shading.buffers = [
            rays,
            Buffer(name: "Ray Count", [UInt32(rays.count)], usage: .sparse),
            intersections,
            materialBuffer,
            materialDescriptorBuffer,
            samplers
        ]
        
        try await gpu.execute {
            shading
        }
    }
    
    func intersect(gpu: GPU, rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
        
        try await gpu.execute {
            ComputeShader(
                name: "pathMatsIntersection",
                buffers: [
                    rays,
                    intersections,
                    sceneBuffer,
                    typeBuffer,
                    objectCountBuffer,
                    indicator
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper.groupsForSize(
                    size: MTLSize(width: 8, height: 1, depth: 1),
                    dispatch: MTLSize(width: intersections.count, height: 1, depth: 1))
            )
        }
    }
}
