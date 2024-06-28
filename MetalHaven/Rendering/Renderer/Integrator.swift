//
//  Integrator.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

import Metal
import MetalAbstract

protocol Integrator {
    associatedtype State
    
    init()
    
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> State
}

extension Integrator {
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {}
    
    func generateIntersections(gpu: GPU, intersectionBuffer: Buffer<Intersection>, count: Int, usage: Usage = .gpu) async throws {
        intersectionBuffer.reset(count: count, usage: usage)
        
        try await gpu.execute {
            ComputeShader(
                function: .generateNullIntersections,
                buffers: [intersectionBuffer],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper.buffer
            )
        }
    }
}

extension Integrator where State == () {
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> State { () }
}

protocol SequenceIntegrator: Integrator {
    var maxIterations: Int? { get }
    
    func integrate(
        gpu: GPU,
        state: State,
        rays: Buffer<ShadingRay>,
        intersections: Buffer<Intersection>,
        intersector: SequenceIntersector,
        emitters: [Light],
        materials: [Material]
    ) async throws
}

extension SequenceIntegrator where State == () {
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {
        ()
    }
}

protocol ContinualIntegrator: Integrator, Intersector {
    var regenProbability: Float { get }
    var singlePass: Bool { get }
    var intersectionsPerSample: Int { get }
    // Integration
    var integrator: ComputeShader.Function { get }
    var supplementaryBuffers: [any ErasedBuffer] { get }
    
    func updateState(gpu: GPU, scene: GeometryScene, state: State) async throws -> State
}

extension ContinualIntegrator {
    // Extra buffers for integration
    var supplementaryBuffers: [any ErasedBuffer] { [] }
    
    func updateState(gpu: GPU, scene: GeometryScene, state: State) async throws -> State {
        state
    }
}

struct ContinualIntegratorUniforms {
    let generator: Generator
    let geometry = VoidBuffer(name: "Geometry", usage: .managed)
    let geometryTypes = Buffer<GeometryType>(name: "Geometry Types")
    let materials = VoidBuffer(name: "Material", usage: .managed)
    let matTypes = Buffer<MaterialDescription>(name: "MatTypes")
    let samplers = Buffer<HaltonSampler>(name: "")
    let areaLight = Buffer<AreaLight>(name: "AreaLights")
    let totalArea = Buffer<Float>(name: "TotalArea")
    let camera: Camera
}

extension ContinualIntegrator {
    func intersect(
        gpu: GPU,
        queries: [(Buffer<ShadingRay>, Buffer<Intersection>)],
        scene: VoidBuffer,
        geometryTypes: Buffer<GeometryType>
    ) async throws {
        if singlePass {
            let pass = queries.map { (rays, intersections) in
                ComputeShader(
                    function: .intersect,
                    buffers: [
                        rays,
                        Buffer([UInt32(rays.count)], usage: .sparse),
                        intersections,
                        scene,
                        geometryTypes,
                        Buffer([UInt32(geometryTypes.count)], usage: .sparse)
                    ],
                    threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                    dispatchSize: ThreadGroupDispatchWrapper.buffer
                )
            }
            try await gpu.execute(pass: GPUPass(pass: pass, completion: { _ in }))
        } else  {
            for (rays, intersections) in queries {
                try await gpu.execute {
                    ComputeShader(
                        function: .intersect,
                        buffers: [
                            rays,
                            Buffer([UInt32(rays.count)], usage: .sparse),
                            intersections,
                            scene,
                            geometryTypes,
                            Buffer([UInt32(geometryTypes.count)], usage: .sparse)
                        ],
                        threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                        dispatchSize: ThreadGroupDispatchWrapper.buffer
                    )
                }
            }
        }
    }
    
    func integrate(
        gpu: GPU,
        queries: [(rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>)],
        uniforms: ContinualIntegratorUniforms
    ) async throws {
        let countBuffer = Buffer<UInt32>([UInt32(queries[0].rays.count)], usage: .sparse)
        try await gpu.execute {
            ComputeShader(
                function: integrator,
                buffers: [countBuffer] + queries.reduce([any ErasedBuffer]()) { $0 + [$1.rays, $1.intersections] } + [
                    uniforms.geometry,
                    uniforms.geometryTypes,
                    uniforms.matTypes,
                    uniforms.materials,
                    uniforms.samplers,
                    uniforms.areaLight,
                    uniforms.totalArea
                ] + supplementaryBuffers,
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper { size, resources in
                    let rayBuffer: any ErasedBuffer = resources.allBuffers[0][1]
                    return ThreadGroupDispatchWrapper.groupsForSize(size: size, dispatch: MTLSize(width: rayBuffer.unsafeCount!, height: 1, depth: 1))
                }
            )
        }
        regenerateRNG(rng: uniforms.generator, prob: regenProbability, samplers: uniforms.samplers)
    }
    
    func cleanAndAccumulate(
        gpu: GPU,
        rays: Buffer<ShadingRay>,
        samples: Buffer<UInt32>,
        maxSamples: UInt32,
        camera: Camera,
        samplers: Buffer<HaltonSampler>,
        indicator: Buffer<Bool>,
        accumulator: Texture,
        offset: SIMD2<Float>,
        display: Texture
    ) async throws {
        indicator[0] = false
        try await gpu.execute {
            ComputeShader(
                function: .continualAccumulator,
                buffers: [
                    rays,
                    Buffer([UInt32(0)], usage: .sparse),
                    Buffer([UInt32(rays.count)], usage: .sparse),
                    samples,
                    Buffer([maxSamples], usage: .sparse),
                    Buffer([camera.projection], usage: .sparse),
                    Buffer([camera.position], usage: .sparse),
                    samplers,
                    indicator,
                    Buffer([offset], usage: .sparse),
                ],
                textures: [accumulator, display],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper.buffer
            )
        }
    }
    
    func step(
        gpu: GPU,
        scene: GeometryScene,
        state: State,
        queries: [(rays: Buffer<ShadingRay>, intersections: Buffer<Intersection>)],
        uniform: ContinualIntegratorUniforms,
        sampleCounts: Buffer<UInt32>,
        maxSamples: Int,
        indicator: Buffer<Bool>,
        accumulator: Texture,
        display: Texture
    ) async throws -> State {
        try await intersect(
            gpu: gpu,
            queries: queries,
            scene: uniform.geometry,
            geometryTypes: uniform.geometryTypes
        )
        
        try await integrate(
            gpu: gpu,
            queries: queries,
            uniforms: uniform
        )
        
        try await cleanAndAccumulate(
            gpu: gpu,
            rays: queries[0].rays,
            samples: sampleCounts,
            maxSamples: UInt32(maxSamples),
            camera: uniform.camera,
            samplers: uniform.samplers,
            indicator: indicator,
            accumulator: accumulator,
            offset: uniform.generator.generateVec2(),
            display: display
        )
        
        return try await updateState(gpu: gpu, scene: scene, state: state)
    }
}

extension ComputeShader.Function {
    static let intersect = ComputeShader.Function(name: "intersect")
    static let continualAccumulator = ComputeShader.Function(name: "cleanAndAccumulate")
}

extension Integrator {
    func regenerateRNG(rng: Generator, prob: Float, samplers: Buffer<HaltonSampler>) {
        if rng.generate() < prob {
            print("Regenerating")
            samplers.reset(
                samplers.generate(
                    rng: rng,
                    maxSeed: 1024,
                    count: samplers.count
                ),
                usage: .managed
            )
        }
    }
}
