//
//  BVHRenderer.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/24.
//

import Metal
import MetalAbstract

//"visualizeBoundingBoxes"
struct BVHNormalRenderer: SimpleRenderer {
    let shader = ComputeShader(name: "visualizeBoundingBoxes", threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
    
    func renderScene(gpu: GPU, camera: Camera, sceneManager: SceneManager, rays: Buffer<ShadingRay>, samplers: Buffer<HaltonSampler>, texture: Texture) async throws -> [Shader] {
        shader.buffers = [
            rays,
            sceneManager.bvh!,
            sceneManager.geometry,
            sceneManager.geometryTypes,
            sceneManager.materials,
            sceneManager.materialTypes
        ]
        
        shader.textures = [texture]
        
        return [shader]
    }
}

struct BVHRayTracer: SimpleRenderer {
    let shader = ComputeShader(name: "bvhRendering", threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
    
    func renderScene(gpu: GPU, camera: Camera, sceneManager: SceneManager, rays: Buffer<ShadingRay>, samplers: Buffer<HaltonSampler>, texture: Texture) async throws -> [Shader] {
        shader.buffers = [
            rays,
            sceneManager.bvh!,
            sceneManager.geometry,
            sceneManager.geometryTypes,
            sceneManager.materials,
            sceneManager.materialTypes,
            samplers,
            sceneManager.lights!,
            sceneManager.emittingArea!
        ]
        
        shader.textures = [texture]
        
        return [shader]
    }
}


struct BVHDirectRenderer: SimpleRenderer {
    let shader = ComputeShader(name: "bvhDirect", threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
    
    func renderScene(gpu: GPU, camera: Camera, sceneManager: SceneManager, rays: Buffer<ShadingRay>, samplers: Buffer<HaltonSampler>, texture: Texture) async throws -> [Shader] {
        shader.buffers = [
            rays,
            sceneManager.bvh!,
            sceneManager.geometry,
            sceneManager.geometryTypes,
            sceneManager.materials,
            sceneManager.materialTypes,
            samplers,
            sceneManager.lights!,
            sceneManager.emittingArea!
        ]
        
        shader.textures = [texture]
        
        return [shader]
    }
}

