//
//  VideoScene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

import MetalAbstract

protocol VideoScene {
    mutating func setFrame(_ frame: Int)
    
    var camera: Camera { get }
    var scene: GeometryScene { get }
    var intersector: any SequenceIntersector { get }
    var integrator: any SequenceIntegrator { get }
}

protocol VideoManager {
    mutating func addTexture(texture: Texture, frame: Int)
    func finish()
}

struct EmptyVideoManager: VideoManager {
    func addTexture(texture: Texture, frame: Int) {}
    func finish() {}
}

struct VideoRenderer {
//    static func presentVideo(gpu: GPU, scene: VideoScene, frames: Int, samples: Int, antialiased: Bool, showIntermediate: Bool, writes: Bool) -> AsyncStream<(Texture, Float)> {
//        if writes { fatalError("Writing unimplemented") }
//        return AsyncStream<(Texture, Float)> { cont in
//            Task {
//                try await Self.createVideo(gpu: gpu, scene: scene, frames: frames, samples: samples, antialiased: antialiased, cont: cont, showIntermediate: showIntermediate, videoManager: EmptyVideoManager())
//            }
//        }
//    }
    
//    static func createVideo(gpu: GPU, scene: VideoScene, frames: Int, samples: Int, antialiased: Bool, cont: AsyncStream<(Texture, Float)>.Continuation?, showIntermediate: Bool, videoManager: VideoManager?) async throws {
//        var scene = scene
//        var manager = videoManager
//        for frame in 0..<frames {
//            scene.setFrame(frame)
//            
//            let texture = try await RendererManager.render(
//                gpu: gpu,
//                samples: samples,
//                renderer: SequenceRenderer(
//                    intersector: scene.intersector,
//                    integrator: scene.integrator,
//                ),
//                antialiased: antialiased,
//                scene: scene.scene,
//                camera: scene.camera,
//                frame: frame,
//                presentSteps: { if showIntermediate { cont?.yield(($0, $1)) } }
//            )
//            if !showIntermediate { cont?.yield((texture, 1)) }
//            manager?.addTexture(texture: texture, frame: frame)
//        }
//        manager?.finish()
//        cont?.finish()
//    }
}
