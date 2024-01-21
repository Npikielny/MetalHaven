//
//  RayTracerView.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

import Exposables
import MetalAbstract
import SwiftUI

struct RayTracerView: View {
//    @StateObject var container = ExposableContainer(displayMethod: .none)
    
    let view = MAView(
        gpu: .default,
        frame: CGRect(origin: .zero, size: CGSize(width: Self.width, height: Int(Float(Self.width) * Self.aspectRatio))),
        format: .rgba16Float,
        updateProcedure: .manual) { gpu, drawable, descriptor in
            guard let drawable, let descriptor else { print("No context"); return }
            
            let tex = try await RendererManager.render(
                gpu: gpu,
                samples: 1,
                renderer: SequenceRenderer(
                    intersector: RayTracerIntersector(),
                    integrator: RayTracerIntegrator()
                ),
                antialiased: true,
                scene: Self.randomScene,
                camera: Self.camera,
                frame: 0
            )
            
            try await gpu.execute(drawable: drawable, descriptor: descriptor) {
                RasterShader(
                    vertexShader: "getCornerVerts",
                    fragmentShader: "copyTexture",
                    fragmentTextures: [tex],
                    fragmentBuffers: [Buffer([Float(1.0)], usage: .sparse)],
                    startingVertex: 0,
                    vertexCount: 6,
                    passDescriptor: .drawable,
                    format: .rgba16Float
                )
            }
        }
    
    var body: some View {
        HStack {
            let _ = updateScene()
            let _ = view.draw()
            
            VStack {
//                container.compile(Mirror(reflecting: self))
                Button { view.draw() } label: { Text("Draw") }
            }//.frame(width: 100)
            
            view
        }
    }
    
    func updateScene() {
//        var dl = testScene.lights.first! as! DirectionLight
//        dl.color = color.vec
//        testScene.lights[0] = dl
    }
    
}

#Preview {
    RayTracerView()
}
