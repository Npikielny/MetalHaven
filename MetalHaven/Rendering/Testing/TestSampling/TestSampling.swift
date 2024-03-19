//
//  TestSampling.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 1/8/24.
//

import MetalAbstract
import SwiftUI

struct TestSamplingView: View {
    var view: MAView = {
        let tex = Texture(format: .rgba16Float, width: 512, height: 512, depth: 1, storageMode: .private, usage: [.shaderRead, .shaderWrite])
        let rng = PRNG()
        let random = (0..<512 * 512)
            .map { _ in UInt16(min(rng.generate() * 65536, 65536)) }
        
        let samplerBuffer = Buffer(
            name: "Samplers",
            random.map { seed in HaltonSampler(seed: UInt32(seed), uses: 0) },
            usage: .managed
        )
        
//        let generateSampler = ComputeShader(
//            name: "generateSampler",
//            buffers: [samplerBuffer],
//            textures: [randomTexture],
//            threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
//        )
        
        let draw = ComputeShader(
            name: "testSampling",
            buffers: [samplerBuffer],
            textures: [tex],
            threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
        )
        
        let raster = RasterShader(
            vertexShader: "getCornerVerts",
            fragmentShader: "copyTexture",
            fragmentTextures: [tex],
            fragmentBuffers: [Buffer([Float(1)], usage: .sparse)],
            startingVertex: 0,
            vertexCount: 6,
            passDescriptor: .drawable,
            format: .rgba16Float
        )
        
        return MAView(
            gpu: .default,
            frame: CGRect(origin: .zero, size: CGSize(width: 512, height: Int(Float(512) * DirectionalTestingView.AspectRatio))),
            format: .rgba16Float,
            updateProcedure: .manual) { gpu, drawable, descriptor in
                guard let drawable, let descriptor else { print("No context"); return }
                do {
                    try await gpu.execute(drawable: drawable, descriptor: descriptor) {
                        //                    generateSampler
                        draw
                        raster
                    }
                } catch {
                    print(error.localizedDescription)
                    fatalError(error.localizedDescription)
                }
            }
    }()
    
    var body: some View {
        HStack {
//            let _ = updateScene()
            let _ = view.draw()
            
//            VStack {
//                container.compile(Mirror(reflecting: self))
//                Button { view.draw() } label: { Text("Draw") }
//            }//.frame(width: 100)
            
            view
        }
    }
}

extension HaltonSampler: GPUEncodable {}

extension Buffer<HaltonSampler> {
    func generate(
        rng: Generator,
        maxSeed: Int,
        count: Int
    ) -> [HaltonSampler] {
        (0..<count)
            .map { _ -> (Int, Int) in
                (
                    min(Int(rng.generate() * Float(maxSeed)), maxSeed),
                    min(Int(rng.generate() * Float(maxSeed)), maxSeed)
                    )
        }
            .map { HaltonSampler(seed: uint32($0.0), uses: uint32($0.1)) }
    }
    
//    func generate(
//        rng: Generator,
//        maxSeed: Int,
//        count: Int
//    ) -> [HaltonSampler] {
//        Array(
//            repeating: (
//                min(Int(rng.generate() * Float(maxSeed)), maxSeed),
//                min(Int(rng.generate() * Float(maxSeed)), maxSeed)
//            ),
//            count: count
//        )
//            .map { HaltonSampler(seed: uint32($0.0), uses: uint32($0.1)) }
//    }
}
