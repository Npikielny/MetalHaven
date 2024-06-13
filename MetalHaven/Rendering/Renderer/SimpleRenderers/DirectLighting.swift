//
//  MaterialsRenderer.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/13/24.
//

import Metal
import MetalAbstract

struct DirectRenderer: SimpleRenderer {
    let shader = ComputeShader(
        name: "getDirectLighting",
        buffers: [],
        textures: [],
        threadGroupSize: MTLSize(width: 8, height: 8, depth: 1),
        dispatchSize: ThreadGroupDispatchWrapper()
    )
    
    func renderScene(
        gpu: GPU,
        camera: Camera,
        sceneManager: SceneManager,
        rays: Buffer<Ray>,
        texture: Texture
    ) async throws -> [Shader] {
        
        shader.buffers = [
            rays,
            sceneManager.geometry,
            sceneManager.geometryTypes,
            sceneManager.objectCount,
            sceneManager.materials,
            sceneManager.materialTypes
        ]
        shader.textures = [texture]
        
        return [shader]
    }
}
