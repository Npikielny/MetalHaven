//
//  RawBuffferTest.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 1/2/24.
//

import Metal
import MetalAbstract
import SwiftUI

struct RawBufferTest: View {
    var objects: any ErasedBuffer
    let shader: RasterShader
    
    init(geometry: [Geometry]) {
        let strides = geometry.map(\.stride)
        var acc = UInt32(0)
        var offsets = [UInt32]()
        for i in strides {
            offsets.append(acc)
            acc += UInt32(i)
        }
        let offsetBuffer = Buffer(name: "Offsets", offsets, usage: .managed)
        
        self.objects = VoidBuffer(name: "Objects", future: { gpu in
            
            guard let buf = gpu.device.makeBuffer(
                length: geometry.map(\.stride).reduce(0, +),
                options: .storageModeManaged
            ) else { return nil }
            
            var offset = 0
            for obj in geometry {
                offset += Self.copy(geom: obj, ptr: buf.contents() + offset)
            }
            buf.didModifyRange(0..<buf.length)
            
            return (buf, geometry.count)
        }, usage: .managed)
        
        let types = Buffer(name: "Types", geometry.map(\.geometryType), usage: .managed)
        
        shader = RasterShader(
            vertexShader: "primitiveVertices",
            fragmentShader: "colorPrimitive",
            vertexBuffers: [
                self.objects,
                types,
                offsetBuffer
            ],
            vertexCount: geometry.count * 3,
            passDescriptor: .drawable,
            format: .rgba16Float
        )
    }
    
    static func copy(geom: some Geometry, ptr: UnsafeMutableRawPointer) -> Int {
        memcpy(ptr, [geom], geom.stride)
        return geom.stride
    }
    
    var body: some View {
        MAView(
            gpu: .default,
            format: .rgba16Float,
            updateProcedure: .rate(1 / 60)) { gpu, drawable, descriptor in
                guard let drawable, let descriptor else { print("Unable to draw"); return }
                
                try await gpu.execute(drawable: drawable, descriptor: descriptor) {
                    shader
                }
            }
    }
}

#Preview {
    RawBufferTest(geometry: GeometryScene.boxScene.geometry)
}
