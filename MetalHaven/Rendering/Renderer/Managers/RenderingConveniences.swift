//
//  RenderingConveniences.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

import Metal
import MetalAbstract

typealias ComputeFn = ComputeShader.Function
typealias RasterFn = RasterShader.Function

extension RasterFn {
    static let present = RasterFn(vertexShader: "getCornerVerts", fragmentShader: "copyTexture", format: MTLPixelFormat.rgba16Float)
    static let presentFlipped = RasterFn(vertexShader: "getCornerVertsFlipped", fragmentShader: "copyTexture", format: MTLPixelFormat.rgba16Float)
}

extension Texture {
    func present(rescale: Float = 2) -> RasterShader {
        RasterShader(
            function: .present,
            fragmentTextures: [self],
            fragmentBuffers: [Buffer([rescale], usage: .sparse)],
            passDescriptor: RenderPassDescriptor.drawable
        )
    }
    
    func presentFlipped(rescale: Float = 2) -> RasterShader {
        RasterShader(
            function: .presentFlipped,
            fragmentTextures: [self],
            fragmentBuffers: [Buffer([rescale], usage: .sparse)],
            passDescriptor: RenderPassDescriptor.drawable
        )
    }
}

extension ComputeFn {
    static let generateRays = ComputeFn(name: "generateRays")
}
extension Buffer<ShadingRay> {
    func generate(imageSize: SIMD2<UInt32>, camera: Camera, offset: SIMD2<Float>) -> ComputeShader {
        ComputeShader(
            function: .generateRays,
            buffers: [
                Buffer<SIMD2<UInt32>>(name: "Image Size", [imageSize], usage: .sparse),
                self,
                Buffer<float3x3>(name: "Camera Projection", [camera.projection], usage: .sparse),
                Buffer<SIMD3<Float>>(name: "Camera Position", [camera.position], usage: .sparse),
                Buffer<SIMD2<Float>>(name: "Offset", [offset], usage: .sparse)
            ],
            threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
            dispatchSize: ThreadGroupDispatchWrapper { size, resources in
                ThreadGroupDispatchWrapper.groupsForSize(size: size, dispatch: MTLSize(width: resources.allBuffers.first![1].unsafeCount!, height: 1, depth: 1))
            }
        )
    }
}


extension ComputeFn {
    static let clearKernel = ComputeFn(name: "clearTextureKernel")
}

extension [Texture] {
    func clearTextures(gpu: GPU) async throws {
        try await gpu.execute(pass: GPUPass(
            pass: self.map {
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
    
    
    func clearTexturesKernel(gpu: GPU) async throws {
        try await gpu.execute(pass: GPUPass(
            pass: self.map {
                ComputeShader(
                    function: .clearKernel,
                    textures: [$0],
                    threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
                )
            },
            completion: { _ in })
        )
    }
}
