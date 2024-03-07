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
        let width = 800 * 2
        let height = width * 600 / 800
        let o = SIMD3<Float>(0, 0.919769, 5.41159)
        let t = SIMD3<Float>(0, 0.893051, 4.41198)
        let d = t - o
        
        PathTracingView(
            scene: .boxScene,
            camera: Camera(position: o, forward: d, fov: 27.7856, imageSize: SIMD2<Int>(width, height)),
            samples: 1024,
            antialiased: true,
            renderer: ContinualRenderer(integrator: PMis(), generator: PRNG())
        )
//        PathTracingView(
//            scene: .boxScene,
//            camera: Camera(position: o, forward: d, fov: 27.7856, imageSize: SIMD2<Int>(width, height)),
//            samples: 512,
//            antialiased: true,
//            renderer: SequenceRenderer(method: PathMatsIntegratorSingle())
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
