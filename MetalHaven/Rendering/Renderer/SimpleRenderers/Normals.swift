//
//  Normals.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

import Metal
import MetalAbstract

struct NormalRenderer: SimpleRenderer {
    let shader = ComputeShader(
        name: "getNormals",
        buffers: [],
        textures: [],
        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1),
        dispatchSize: ThreadGroupDispatchWrapper()
    )
    
    func renderScene(
        gpu: GPU,
        camera: Camera,
        sceneManager: SceneManager,
        rays: Buffer<ShadingRay>,
        samplers: Buffer<HaltonSampler>,
        texture: Texture
    ) async throws -> [Shader] {
//        let raw = try await texture.encode(gpu)
        
        shader.buffers = [
            rays,
            sceneManager.geometry,
            sceneManager.geometryTypes,
            sceneManager.objectCount
        ]
        shader.textures = [texture]
        
        return [shader]
    }
}
