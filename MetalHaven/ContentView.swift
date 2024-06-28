//
//  ContentView.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/23.
//

import Exposables
import MetalAbstract
import SwiftUI

var tracingGpu: GPU = GPU(
    device: MTLCopyAllDevices()
        .filter { $0.supportsRaytracing }
        .first!
)!

//var gpu: GPU = GPU(
//    device: MTLCopyAllDevices()
//        .filter { $0.supportsRaytracing }
//        .first!
//)!

struct ContentView: View {
    var body: some View {
//        let width = 800
//        let height = width * 600 / 800
////        let height = 10
//        let o = SIMD3<Float>(0, 0.919769, 5.41159)
//        let t = SIMD3<Float>(0, 0.893051, 4.41198)
////        let o = SIMD3<Float>(0, 1, 5)
////        let t = SIMD3<Float>(0, 0.7, 0)
////        let o = SIMD3<Float>(0, 243, 0)
////        let t = SIMD3<Float>(0, 0, 0)
//        let d = t - o
//        let camera = Camera(position: o, forward: d, fov: 27.7856, imageSize: SIMD2<Int>(width, height))
////        let camera = Camera(position: o, forward: d, fov: Double.pi / 2, imageSize: SIMD2<Int>(width, height))
//        PathTracingView(
//            scene: .sphereArray,
//            camera: camera,
//            samples: Int(2048),
//            antialiased: true,
//            renderer: ContinualRenderer(integrator: LiveHybridMLT(), generator: PRNG())
//        ).onAppear {
//            
////            HybridBidir()
////                .luminaryPath(gpu: .default, rng: PRNG(), scene: .boxScene, lights: LightingSampler(scene: .boxScene), camera: camera)
//        }
        
        RenderingSandbox()
            .onAppear {
                print("DEPTH: \(BVH.create(geometry: try! MeshLoader.load(name: "bunny", material: 0)).tree.depth())")
            }
        
//        FluidSim2D(gpu: .default, n: 300, rng: PRNG(), bins: 30)
//        PathTracingView(
//            scene: .boxScene,
//            camera: Camera(position: o, forward: d, fov: 27.7856, imageSize: SIMD2<Int>(width, height)),
//            samples: 512,
//            antialiased: true,
//            renderer: SequenceRenderer(method: BidirectionalIntegrator())
//        )
//
        
//        Grapher()
    }
}

extension CGPoint {
    var simd: SIMD2<Float> {
        SIMD2(Float(x), Float(y))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
