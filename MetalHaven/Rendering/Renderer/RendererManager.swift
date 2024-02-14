//
//  Renderer.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

import Metal
import MetalAbstract

struct RendererManager {
    static func render(
        gpu: GPU,
        samples: Int,
        renderer: some Renderer,
        antialiased: Bool,
        scene: GeometryScene,
        camera: Camera,
        frame: Int,
        presentSteps: (Texture, _ rescale: Float) async throws -> Void = { _, _ in }
    ) async throws -> Texture {
        try await renderer.render(gpu: gpu, samples: samples, antialiased: antialiased, scene: scene, camera: camera, present: presentSteps)
    }
    
    private static func clearTextures(gpu: GPU, textures: [Texture]) async throws {
        try await gpu.execute(pass: GPUPass(
            pass: textures.map {
                RasterShader(
                    vertexShader: "getCornerVerts",
                    fragmentShader: "clearTexture",
                    passDescriptor: .future(texture: $0),
                    texture: $0
                ) // FIXME: Need to add some form of copying to minimize compilation time
            },
            completion: { _ in })
        )
    }
    
    private static func clearRaysAndIntersections(
        gpu: GPU,
        size: SIMD2<Int>,
        rays: Buffer<Ray>,
        rng: Generator?,
        intersections: Buffer<Intersection>,
        camera: Camera
    ) async throws {
        let dispatch = ThreadGroupDispatchWrapper { size, _ in
            ThreadGroupDispatchWrapper.groupsForSize(
                size: size,
                dispatch: MTLSize(width: rays.count, height: 1, depth: 1)
            )
        }
        
        let offset: SIMD2<Float> = {
            if let rng {
                return sampleNormal(rng.generateVec2()) / 2
            } else {
                return .zero
            }
        }()
        try await gpu.execute {
            ComputeShader(
                name: "generateRays",
                buffers: [
                    Buffer(name: "image size", [SIMD2<UInt32>(UInt32(size.x), UInt32(size.y))], usage: .sparse),
                    rays,
                    Buffer(name: "Camera Projection", [camera.projection], usage: .sparse),
                    Buffer(name: "Camera Position", [camera.position], usage: .sparse),
                    Buffer(name: "Offset", [offset], usage: .sparse)
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: dispatch)
            
            ComputeShader(
                name: "generateNullIntersections",
                buffers: [intersections],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: dispatch
            )
        }
    }
    
    private static func sum(gpu: GPU, destinations: [Texture], rays: Buffer<Ray>, samples: Int) async throws {
        try await gpu.execute {
            ComputeShader(
                name: "accumulate",
                buffers: [
                    rays,
                    Buffer(name: "Samples", [UInt32(samples)], usage: .sparse)
                ],
                textures: destinations,
                threadGroupSize: MTLSize(width: 8, height: 8, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper()
            )
        }
    }
}

protocol Renderer {
    func render(
        gpu: GPU,
        samples: Int,
        antialiased: Bool,
        scene: GeometryScene,
        camera: Camera,
        present: (Texture, _ rescale: Float) async throws -> Void
    ) async throws -> Texture
}

extension Renderer {
    static func clearTextures(gpu: GPU, textures: [Texture]) async throws {
        try await gpu.execute(pass: GPUPass(
            pass: textures.map {
                RasterShader(
                    vertexShader: "getCornerVerts",
                    fragmentShader: "clearTexture",
                    passDescriptor: .future(texture: $0),
                    texture: $0
                ) // FIXME: Need to add some form of copying to minimize compilation time
            },
            completion: { _ in })
        )
    }
}

struct SequenceRenderer<T: Intersector, K: Integrator>: Renderer {
    var intersector: T
    var integrator: K
    
    init(method: T) where T == K {
        intersector = method
        integrator = method
    }
    
    init(intersector: T, integrator: K) {
        self.intersector = intersector
        self.integrator = integrator
    }
    
    func render(gpu: GPU, samples: Int, antialiased: Bool, scene: GeometryScene, camera: Camera, present: (Texture, Float) async throws -> Void) async throws -> Texture {
        let size = camera.imageSize
        var destinations = (0..<2).map { _ in
            Texture(format: .rgba16Float, width: size.x, height: size.y, storageMode: .private, usage: [.shaderRead, .shaderWrite, .renderTarget])
        }
        
        let notConverged = Buffer(name: "Indicator", [true], usage: .shared)
        try await notConverged.initialize(gpu: gpu)
        
        let count = size.x * size.y
//        let rays = Buffer<Ray>(count: count, type: Ray.self)
//        let intersections = Buffer<Intersection>(count: count, type: Intersection.self)
        let rays = Buffer<Ray>(name: "Rays", Array(repeating: Ray(), count: count), usage: .shared)
        let intersections = Buffer<Intersection>(name: "Intersections", Array(repeating: Intersection(), count: count), usage: .shared)
        
        try await Self.clearTextures(gpu: gpu, textures: destinations)
        
        intersector.initialize(scene: scene, imageSize: size)
        
        let rng = PRNG()
        
        let state = integrator.generateState(frame: 0, imageSize: size)
        
        for sample in 0..<samples {
            notConverged[0] = true
            try await SequenceRenderer.clearRaysAndIntersections(gpu: gpu, size: size, rays: rays, rng: antialiased ? rng : nil, intersections: intersections, camera: camera)
            
            var iterations = 0
            while (notConverged[0] ?? false && iterations < (integrator.maxIterations ?? Int.max)) {
                notConverged[0] = false
                try await intersector.generateIntersections(gpu: gpu, rays: rays, intersections: intersections, indicator: notConverged)
                try await integrator.integrate(
                    gpu: gpu,
                    state: state,
                    rays: rays,
                    intersections: intersections,
                    intersector: intersector,
                    emitters: scene.lights,
                    materials: scene.materials
                )
                NSLog("Sample: \(sample), Iteration: \(iterations)")
                iterations += 1
            }
            try await Self.sum(gpu: gpu, destinations: destinations, rays: rays, samples: samples)
            destinations.swapAt(0, 1)
            try await present(destinations[0], Float(samples) / Float(sample + 1))
        }
        return destinations[0]
    }
    
    private static func clearRaysAndIntersections(
        gpu: GPU,
        size: SIMD2<Int>,
        rays: Buffer<Ray>,
        rng: Generator?,
        intersections: Buffer<Intersection>,
        camera: Camera
    ) async throws {
        let dispatch = ThreadGroupDispatchWrapper { size, _ in
            ThreadGroupDispatchWrapper.groupsForSize(
                size: size,
                dispatch: MTLSize(width: rays.count, height: 1, depth: 1)
            )
        }
        
        let offset: SIMD2<Float> = {
            if let rng {
                return sampleNormal(rng.generateVec2()) / 2
            } else {
                return .zero
            }
        }()
        try await gpu.execute {
            ComputeShader(
                name: "generateRays",
                buffers: [
                    Buffer(name: "image size", [SIMD2<UInt32>(UInt32(size.x), UInt32(size.y))], usage: .sparse),
                    rays,
                    Buffer(name: "Camera Projection", [camera.projection], usage: .sparse),
                    Buffer(name: "Camera Position", [camera.position], usage: .sparse),
                    Buffer(name: "Offset", [offset], usage: .sparse)
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: dispatch)
            
            ComputeShader(
                name: "generateNullIntersections",
                buffers: [intersections],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: dispatch
            )
        }
    }
    
    private static func sum(gpu: GPU, destinations: [Texture], rays: Buffer<Ray>, samples: Int) async throws {
        try await gpu.execute {
            ComputeShader(
                name: "accumulate",
                buffers: [
                    rays,
                    Buffer(name: "Samples", [UInt32(samples)], usage: .sparse)
                ],
                textures: destinations,
                threadGroupSize: MTLSize(width: 8, height: 8, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper()
            )
        }
    }
}

struct ContinualRenderer: Renderer {
    func render(
        gpu: GPU,
        samples: Int,
        antialiased: Bool,
        scene: GeometryScene,
        camera: Camera,
        present: (Texture, Float) async throws -> Void
    ) async throws -> Texture {
        Texture(format: .rgba16Float, width: 0, height: 0, storageMode: .managed, usage: .renderTarget)
    }
    
    
}
