//
//  SimpleRenderer.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

import MetalAbstract

protocol SimpleRenderer {
    func renderScene(
        gpu: GPU,
        camera: Camera,
        sceneManager: SceneManager,
        rays: Buffer<ShadingRay>,
        texture: Texture
    ) async throws -> [Shader]
}
