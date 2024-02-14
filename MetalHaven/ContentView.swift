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
//        RawBufferTest(geometry: [
//            Triangle(
//                v1: vector_float3(-1, 0, 1),
//                v2: vector_float3(1, 0, 1),
//                v3: vector_float3(0, 1, 1),
//                material: 0
//            ),
//            
//            Sphere(
//                position: vector_float3(0, -0.5, 1),
//                size: Float(0.25),
//                material: 0
//            )
//        ])
//        let _ = print(gpu.name)
//        PathTracingView<TestIntersectionsIntersector, TestIntersectionsIntegrator>(
//            width: 512,
//            aspectRatio: 16/9,
//            scene: .boxSceneWithSpheres,
//            camera: Camera(imageSize: SIMD2<Int>(512, 512)),
//            samples: 1
//        )
//        let width = 512 * 2// 4// / 4
//        let width = 800
//        let height = width * 600 / 800
//        let o = SIMD3<Float>(0, 0.919769, 5.41159)
//        let t = SIMD3<Float>(0, 0.893051, 4.41198)
//        let d = t - o
//        PathEms(
//            width: width,
//            aspectRatio: Float(width) / Float(height),
//            scene: .boxScene,
//            camera: Camera(position: o, forward: d / length(d), fov: 27.7856, imageSize: SIMD2<Int>(width, height)),
//            samples: 512 * 4,//512 * 32,//32 /** 4*/,
//            antialiased: true
//        )
        Grapher()
//        PathEms(
//            width: width,
//            aspectRatio: 16 / 9,
//            scene: .boxSceneWithSpheres,
//            camera: Camera(position: .zero, imageSize: SIMD2<Int>(width, width * 9 / 16)),
//            samples: 1024,
//            antialiased: true
//        )
//        Text("Hi")
//        .onAppear {
//            let sampler = SamplerWrapper(seed: .random(in: 5...1024), uses: 0)
//            for _ in 0...10 {
////                print(sampler.uniformSample(), sampler.sampler.pointee.seed, sampler.sampler.pointee.uses)
//                let sample = sampler.cosineHemiSphere()
//                print(sample, cosineHemispherePdf(sample))
//            }
////            let rng = PRNG()
////            let samples = (0..<100).map { _ in sampleNormal(rng.generateVec2()) }
////            print(samples)
////            print("Mean", samples.reduce(SIMD2<Float>.zero, +) / Float(samples.count))
////            let samples = (0..<100).map { _ in rng.generate() }
////            print(samples.reduce(0, +) / 100)
//        }
//        DirectionalTestingView()
//        TestSamplingView()
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
