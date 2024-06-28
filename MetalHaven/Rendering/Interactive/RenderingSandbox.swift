//
//  RenderingSandbox.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 6/12/24.
//

import Exposables
import MetalAbstract
import SwiftUI

struct RenderingSandbox: View {
//    static let defaultCamera = Camera(position: .zero, forward: SIMD3<Float>(0, 0, 1), up: SIMD3<Float>(0, 1, 0), right: SIMD3<Float>(1, 0, 0), fov: Double.pi / 4, imageSize: SIMD2<Int>(512, 512))
    static let defaultCamera = Camera.closeCamera
    @FocusState private var focused: Bool
    
    @State var camera = Self.defaultCamera
    @State var tempCamera = Self.defaultCamera
    
    @Expose var settings: RenderingSettings
    
    let texture: Texture
    let renderingView: MAView
    
    let timer = Timer.publish(every: 1 / 30, on: .main, in: .default).autoconnect()
    
    init() {
        let settings = Expose(wrappedValue: RenderingSettings(
            scene: SceneManager(scene: .bunnyScene(scale: 3)),
            renderer: NormalRenderer()
        ), title: "Settings")
        self._settings = settings
        
        let texture = Texture(
            format: .rgba16Float,
            width: Self.defaultCamera.imageSize.x,
            height: Self.defaultCamera.imageSize.y,
            storageMode: .managed, usage: [.shaderRead, .shaderWrite]
        
        )
        self.texture = texture
        
        let gpu = GPU.default
        
        self.renderingView = MAView(
            gpu: gpu,
            frame: CGRect(
                origin: .zero,
                size: CGSize(width: 512, height: 512)
            ),
            format: .rgba16Float, updateProcedure: .manual) { gpu, drawable, descriptor in
            guard let drawable, let descriptor else { return }
            try await Self.draw(gpu: gpu, drawable: drawable, descriptor: descriptor, settings: settings.wrappedValue, texture: texture)
        }
        
        let view = self.renderingView
        Task {
            try await [texture].clearTexturesKernel(gpu: gpu)
            
            view.draw()
        }
    }
    
    @State var t = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            renderingView
                .focusable()
                .focused($focused)
                .gesture(DragGesture(coordinateSpace: .local)
                    .onChanged { event in
                        updateCamera(start: event.startLocation, end: event.location, size: geometry.size)
                    }
                    .onEnded { event in
                        updateCamera(start: event.startLocation, end: event.location, size: geometry.size)
                        camera = tempCamera
                    }
                )
                .onKeyPress(.downArrow) {
                    print("Down")
                    return .handled
                }
                .onKeyPress(.rightArrow) {
                    rotate(direction: 1)
                    return .handled
                }
                .onKeyPress(.leftArrow) {
                    rotate(direction: -1)
                    return .handled
                }
                .onAppear {
                    print("APP")
                    renderingView.draw()
                }
                .onKeyPress(.downArrow) {
                    renderingView.draw()
                    return .handled
                }
                .onReceive(timer) { _ in
                    t += 1 / 30
                    let radius: Float = 2
                    let o = SIMD3(radius * Float(cos(t)), settings.camera.position.y, radius * Float(sin(t)))
                    let t = SIMD3<Float>(0, 0.220812, 0)
                    let d = normalize(t - o)
                    
                    let right = normalize(cross(SIMD3(0, 1, 0), d))
                    let up = normalize(cross(d, right))
                    
                    let cam = Camera(position: o, forward: d, up: up, right: right, fov: 8 * 27.7856 / 180 * Double.pi, imageSize: SIMD2<Int>(800, 600))
                    settings.camera = cam
                    renderingView.draw()
                }
        }
    }
    
    func rotate(direction: Double) {
        let angle = Float(direction) * Float.pi / 100
        
        let c = cos(angle)
        let s = sin(angle)
        tempCamera.forward = normalize(c * camera.forward - s * camera.right)
        tempCamera.right = normalize(cross(camera.up, tempCamera.forward))
        camera = tempCamera
        
        settings.camera = tempCamera
        
        renderingView.draw()
    }
    
    func updateCamera(start: CGPoint, end: CGPoint, size: CGSize) {
        let diff = end.simd - start.simd
        let angles = diff / SIMD2(Float(size.width), Float(size.height)) * Float(camera.fov) / 2
        
        let c = cos(angles.x)
        let s = sin(angles.x)
        tempCamera.forward = normalize(c * camera.forward - s * camera.right)
        tempCamera.right = normalize(cross(camera.up, tempCamera.forward))
        
//        let cy = cos(angles.y)
//        let sy = sin(angles.y)
//        tempCamera.forward = normalize(cy * camera.forward - sy * camera.up)
//        tempCamera.up = normalize(cross(tempCamera.forward, tempCamera.right))
        
        settings.camera = tempCamera
        
        renderingView.draw()
    }
    
    static func draw(gpu: GPU, drawable: MTLDrawable, descriptor: MTLRenderPassDescriptor, settings: RenderingSettings, texture: Texture) async throws {
//        settings.scene
        let imageSize = Self.defaultCamera.imageSize
        let rays = Buffer(name: "Rays", count: imageSize.x * imageSize.y, type: ShadingRay.self)
        do {
            try await gpu.execute(
                drawable: drawable,
                descriptor: descriptor,
                pass: GPUPass(
                    pass:
                        [rays.generate(imageSize: SIMD2<UInt32>(UInt32(imageSize.x), UInt32(imageSize.y)), camera: settings.camera, offset: .zero)] +
                    settings.renderer.renderScene(
                        gpu: gpu,
                        camera: settings.camera,
                        sceneManager: settings.scene,
                        rays: rays,
                        texture: texture
                    ) +
                    [texture.presentFlipped()],
                    completion: { gpu in
                        
                    }
                )
            )
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension RenderingSandbox {
    struct RenderingSettings: Exposable {
        var camera = RenderingSandbox.defaultCamera
        var scene = SceneManager(scene: .bunnyScene(scale: 3))
        var renderer = NormalRenderer()
        struct Settings {
            
        }
        
        struct Interface: ExposableInterface {
            var title: String?
            var wrappedValue: Exposables.Expose<RenderingSandbox.RenderingSettings>
            var settings: Settings?
            init(_ settings: RenderingSandbox.RenderingSettings.Settings?, title: String?, wrappedValue: Exposables.Expose<RenderingSandbox.RenderingSettings>) {
                self.settings = settings
                self.title = title
                self.wrappedValue = wrappedValue
            }
            
            var body: some View {
                Text(title ?? "")
            }
            
            
        }
        
        // scene
        // renderer
    }
}
