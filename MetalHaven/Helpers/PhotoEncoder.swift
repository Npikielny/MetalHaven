//
//  PhotoEncoder.swift
//  WildlifeDetector
//
//  Created by Noah Pikielny on 2/14/24.
//

import Cocoa
import MetalAbstract

struct PhotoEncoder {
    static func encode(output: URL, gpu: GPU, texture: Texture) async throws {
        let bitsPerComponent = 8//16
        let bytesPerPixel = bitsPerComponent * 4 / 8
        let copy = RasterShader.Function(
            vertexShader: "copyVert",
            fragmentShader: "uvFrag",
            format: MTLPixelFormat.rgba8Unorm
        )
        let dest = texture.emptyCopy(format: .rgba8Unorm, storageMode: .managed, usage: [.renderTarget, .shaderRead])
        try await gpu.execute {
            RasterShader(
                function: copy,
                fragmentTextures: [texture],
                passDescriptor: .future(texture: dest)
            )
//                CopyShader(from: tex, to: dest)
            CopyShader(synchronizing: dest)
        }
        let unwrapped = try dest.forceUnwrap()
        let bytesPerRow = bytesPerPixel * unwrapped.width
        
        guard let bytes = malloc(bytesPerRow * unwrapped.height) else {
            print("UNABLE TO MALLOC")
            return
        }
        defer {
            free(bytes)
        }
        unwrapped.getBytes(
            bytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegion(
                origin: MTLOrigin(x: 0, y: 0, z: 0),
                size: MTLSize(width: unwrapped.width, height: unwrapped.height, depth: unwrapped.depth)
            ),
            mipmapLevel: 0
        )
        
        let context = CGContext(
            data: bytes,
            width: unwrapped.width,
            height: unwrapped.height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue// | CGBitmapInfo.floatComponents.rawValue
        )
        
        guard let cgImage = context?.makeImage() else { print("Failed making cgImage"); return }
        let image = NSImage(
            cgImage: cgImage,
            size: NSSize(width: unwrapped.width, height: unwrapped.height)
        )
        guard let data = image.tiffRepresentation else {
            print("Unable to make rep")
            return
        }
        let path = output.path + "/" + "texture\(index).tiff"
        print(path)
        FileManager.default.createFile(atPath: path, contents: data)
    }
}
