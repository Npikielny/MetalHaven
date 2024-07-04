//
//  RayDirections.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

import Metal
import MetalAbstract

struct RayDirectionRenderer: SimpleRenderer {
    let shader = ComputeShader(name: "rayDirections", buffers: [], textures: [], threadGroupSize: MTLSize(width: 8, height: 8, depth: 1), dispatchSize: ThreadGroupDispatchWrapper())
    
    func renderScene(gpu: GPU, camera: Camera, sceneManager: SceneManager, rays: Buffer<ShadingRay>, samplers: Buffer<HaltonSampler>, texture: Texture) async throws -> [Shader] {
        shader.buffers = [
            rays
        ]
        shader.textures = [texture]
        return [shader]
    }
}
