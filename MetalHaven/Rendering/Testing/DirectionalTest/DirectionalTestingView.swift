//
//  DirectionalTestingView.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

import Exposables
import MetalAbstract
import SwiftUI

struct DirectionalTestingView: View {
    @Expose var color: EColor
    @StateObject var container = ExposableContainer(displayMethod: .none)
    
    @ObservedObject var update: Update
    
    init() {
        let color = Expose(wrappedValue: EColor(color: SIMD3<Double>(1,1,1)))
        self._color = color
        self._update = ObservedObject(wrappedValue: color.state)
    }
    
    let view = MAView(
        gpu: .default,
        frame: CGRect(origin: .zero, size: CGSize(width: 512, height: Int(Float(512) * AspectRatio))),
        format: .rgba16Float,
        updateProcedure: .manual) { gpu, drawable, descriptor in
            guard let drawable, let descriptor else { print("No context"); return }
            
            let tex = try await RendererManager.render(
                gpu: gpu,
                samples: 1,
                renderer: SequenceRenderer(
                    intersector: DirectionalTestIntersector(),
                    integrator: DirectionalTestIntegrator()
                ),
                antialiased: false,
                scene: testScene,
                camera: testCamera,
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
                container.compile(Mirror(reflecting: self))
                Button { view.draw() } label: { Text("Draw") }
            }//.frame(width: 100)
            
            view
        }
    }
    
    func updateScene() {
        var dl = Self.testScene.lights.first! as! DirectionLight
        dl.color = color.vec
        Self.testScene.lights[0] = dl
    }
    
}

#Preview {
    DirectionalTestingView()
}
