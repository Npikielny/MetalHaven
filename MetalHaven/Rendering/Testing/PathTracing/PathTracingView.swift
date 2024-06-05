//
//  PathTracingView.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/16/23.
//

import Exposables
import MetalAbstract
import SwiftUI


public class Temp: ObservableObject {
    var id = UUID()
    
    public func send() {
        Task {
            await MainActor.run {
                objectWillChange.send()
            }
        }
    }
    
    public static func == (lhs: Temp, rhs: Temp) -> Bool { lhs.id == rhs.id }
}

struct SequencePathTracingView<T: SequenceIntersector, K: SequenceIntegrator>: View {
    let view: MAView
    @StateObject var update: Temp
    let aspectRatio: Float
    
    let timer = Timer.publish(every: 1 / 30, on: .main, in: .default).autoconnect()
    
    init(width: Int, aspectRatio: Float, scene: GeometryScene, camera: Camera, samples: Int, antialiased: Bool) {
        self.aspectRatio = aspectRatio
        let upd = Temp()
        self._update = StateObject(wrappedValue: upd)
        
        let drawOperation = RasterShader(
            vertexShader: "getCornerVerts",
            fragmentShader: /*"dynamicTexture",*/ "copyTexture",
//            fragmentTextures: [tex],
//            fragmentBuffers: [Buffer(name: "Rscale", [Float(rescale)], usage: .sparse)],
            startingVertex: 0,
            vertexCount: 6,
            passDescriptor: .drawable,
            format: .rgba16Float
        )
        self.view = MAView(
            gpu: .default,
            frame: CGRect(origin: .zero, size: CGSize(width: width, height: Int(Float(width) * aspectRatio))),
            format: .rgba16Float,
            updateProcedure: .manual) { gpu, drawable, descriptor in
                guard let drawable, let descriptor else { print("No context"); return }
                guard drawOperation.fragmentTextures.count > 0, drawOperation.fragmentBuffers.count > 0 else { print("No textures or buffers yet..."); return }
                try! await gpu.execute(drawable: drawable, descriptor: descriptor) { drawOperation }
            }
        
        
        
        Task {
            let intersector = T()
            let _ = try! await RendererManager.render(
                gpu: .default,
                samples: samples,
                renderer: SequenceRenderer(
                    intersector: intersector,
                    integrator: T.self == K.self ? intersector as! K : K()
                ),
                antialiased: antialiased,
                scene: scene,
                camera: camera,
                frame: 0) { texture, rescale in
                    drawOperation.fragmentTextures = [texture]
                    drawOperation.fragmentBuffers = [Buffer(name: "Rescale", [Float(rescale)], usage: .sparse)]
                }
        }
    }
    
    init(width: Int, aspectRatio: Float, scene: GeometryScene, camera: Camera, samples: Int, antialiased: Bool, intersector: T, integrator: K) {
        self.aspectRatio = aspectRatio
        let upd = Temp()
        self._update = StateObject(wrappedValue: upd)
        
        let drawOperation = RasterShader(
            vertexShader: "getCornerVerts",
            fragmentShader: /*"dynamicTexture",*/ "copyTexture",
//            fragmentTextures: [tex],
//            fragmentBuffers: [Buffer(name: "Rscale", [Float(rescale)], usage: .sparse)],
            startingVertex: 0,
            vertexCount: 6,
            passDescriptor: .drawable,
            format: .rgba16Float
        )
        self.view = MAView(
            gpu: .default,
            frame: CGRect(origin: .zero, size: CGSize(width: width, height: Int(Float(width) * aspectRatio))),
            format: .rgba16Float,
            updateProcedure: .manual) { gpu, drawable, descriptor in
                guard let drawable, let descriptor else { print("No context"); return }
                guard drawOperation.fragmentTextures.count > 0, drawOperation.fragmentBuffers.count > 0 else { print("No textures or buffers yet..."); return }
                try! await gpu.execute(drawable: drawable, descriptor: descriptor) { drawOperation }
            }
        
        
        
        Task {
            let _ = try! await RendererManager.render(
                gpu: .default,
                samples: samples,
                renderer: SequenceRenderer(
                    intersector: intersector,
                    integrator: integrator
                ),
                antialiased: antialiased,
                scene: scene,
                camera: camera,
                frame: 0) { texture, rescale in
                    drawOperation.fragmentTextures = [texture]
                    drawOperation.fragmentBuffers = [Buffer(name: "Rescale", [Float(rescale)], usage: .sparse)]
                }
        }
    }
    
    var body: some View {
        HStack {
            
            VStack {
                Button { view.draw() } label: { Text("Draw") }
            }
            .onReceive(timer) { _ in
                view.draw()
            }
            GeometryReader { geometry in
                Spacer()
                if geometry.size.height * CGFloat(aspectRatio) > geometry.size.width {
                    view
                        .frame(width: geometry.size.width, height: geometry.size.width / CGFloat(aspectRatio))
                } else {
                    view
                        .frame(width: geometry.size.height * CGFloat(aspectRatio), height: geometry.size.height)
                }
            }
        }
    }
}

struct PathTracingView: View {
    static let present = RasterShader.Function(
        vertexShader: "getCornerVerts",
        fragmentShader: "copyTexture", // "dynamicTexture"
        format: MTLPixelFormat.rgba16Float
    )
    static var drawOperation = RasterShader(
        function: present,
        fragmentTextures: [],
        passDescriptor: .drawable
    )
    let view: MAView
    @StateObject var update: Temp
    let aspectRatio: Float
    
    let timer = Timer.publish(every: 1 / 30, on: .main, in: .default).autoconnect()
    
//    let drawOperation: RasterShader
    
    @State var appeared = false
    
    init(scene: GeometryScene, camera: Camera, samples: Int, antialiased: Bool, renderer: Renderer) {
        self.aspectRatio = Float(camera.imageSize.x) / Float(camera.imageSize.y)
        let upd = Temp()
        self._update = StateObject(wrappedValue: upd)
        
//        let drawOperation = RasterShader(
//            function: Self.present,
//            startingVertex: 0,
//            vertexCount: 6,
//            passDescriptor: .drawable
//        )
//        self.drawOperation = drawOperation
        self.view = MAView(
            gpu: .default,
            frame: CGRect(origin: .zero, size: CGSize(width: camera.imageSize.x, height: camera.imageSize.y)),
            format: .rgba16Float,
            updateProcedure: .manual) { gpu, drawable, descriptor in
                guard let drawable, let descriptor else { print("No context"); return }
                guard Self.drawOperation.fragmentTextures.count > 0, Self.drawOperation.fragmentBuffers.count > 0 else { print("No textures or buffers yet..."); return }
                try! await gpu.execute(drawable: drawable, descriptor: descriptor) { Self.drawOperation }
            }
        
        
        
        Task {
            sleep(1)
            let _ = try! await RendererManager.render(
                gpu: .default,
                samples: samples,
                renderer: renderer,
                antialiased: antialiased,
                scene: scene,
                camera: camera,
                frame: 0) { texture, rescale in
                    PathTracingView.drawOperation.fragmentTextures = [texture]
                    PathTracingView.drawOperation.fragmentBuffers = [Buffer(name: "Rescale", [Float(rescale)], usage: .sparse)]
                }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                
                //            VStack {
                //                Button { view.draw() } label: { Text("Draw") }
                //            }
                GeometryReader { geometry in
                    //                Spacer()
                    if geometry.size.height * CGFloat(aspectRatio) > geometry.size.width {
                        view
                            .frame(width: geometry.size.width, height: geometry.size.width / CGFloat(aspectRatio))
                    } else {
                        view
                            .frame(width: geometry.size.height * CGFloat(aspectRatio), height: geometry.size.height)
                    }
                }
                .onAppear {
                    appeared = true
                }
                .onReceive(timer) { _ in
                    if appeared {
                        view.draw()
                    }
                }
            }
        }.aspectRatio(CGFloat(aspectRatio), contentMode: .fit)
    }
}

class Lock {
    var locked = false
}
