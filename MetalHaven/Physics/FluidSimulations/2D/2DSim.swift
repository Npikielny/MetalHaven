//
//  2DSim.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/15/24.
//

import MetalAbstract
import SwiftUI

// Fluid sim in the unit box
struct FluidSim2D: View {
    let gpu: GPU
    let particleBuffer: Buffer<Particle2D>
    
    let view: MAView
    
    let update: ComputeShader
    let drawShader: RasterShader
    
    let timer = Timer.publish(every: 1 / 60, on: .main, in: .default).autoconnect()
    
    init(gpu: GPU, n: Int, rng: Generator, bins: Int) {
        self.gpu = gpu
        
        particleBuffer = Buffer(
            (0..<n).map { _ -> Particle2D in 
                Particle2D(
                    position: rng.generateVec2() * 2 - 1,
                    velocity: .zero,
                    force: .zero,
                    mass: 0.01,
                    color: SIMD3<Float>(0.2, 0.3, 1),
                    size: 0.01
                )
            },
            usage: .managed
        )
        
        let constants = MTLFunctionConstantValues()
        constants.setConstantValue([UInt32(bins)], type: .uint, index: 0)
        
        let upd = ComputeShader(
            name: "updateParticles2D",
            constants: constants,
            buffers: [
                particleBuffer,
                Buffer([UInt32(particleBuffer.count)], usage: .sparse),
                Buffer([Float(1 / 60)], usage: .sparse)
            ],
            threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
            dispatchSize: ThreadGroupDispatchWrapper.buffer
        )
        self.update = upd
        
        let draw = RasterShader(
            vertexShader: "particle2DVerts",
            fragmentShader: "particle2DFragment",
            vertexBuffers: [particleBuffer],
            vertexCount: particleBuffer.count * 6,
            passDescriptor: RenderPassDescriptor.drawable,
            format: .rgba8Unorm
        )
        self.drawShader = draw
        
        self.view = MAView(
            gpu: gpu,
            frame: CGRect(origin: .zero, size: CGSize(width: 1920, height: 1080)),
            format: .rgba8Unorm,
            updateProcedure: .manual
        ) { gpu, drawable, descriptor in
            Self.t[0] = (Self.t[0] ?? 0) + 1 / 60
            try await gpu.execute(drawable: drawable, descriptor: descriptor) {
                upd
                draw
            }
        }
    }
    
    static let t = Buffer([Float(0)], usage: .sparse)
    
    @StateObject var u: Temp = Temp()
    var body: some View {
        view.onReceive(timer) { _ in
            view.draw()
            u.send()
        }
    }
}

extension Particle2D: GPUEncodable {}
