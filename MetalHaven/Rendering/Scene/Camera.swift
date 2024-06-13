//
//  Camera.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 7/19/23.
//

import Foundation

class Camera {
    var position: SIMD3<Float>
    var forward: SIMD3<Float>
    var up: SIMD3<Float>
    var right: SIMD3<Float>
    
    var fov: Double
    
    var projection: float3x3 {
        let s = Float(cos(fov / 2))
        
        return float3x3(
            SIMD3(right) * s,
            SIMD3(up) * s * Float(imageSize.y) / Float(imageSize.x),
            SIMD3(forward) * sin(Float(fov / 2))
        )
    }
    
    var imageSize: SIMD2<Int>
    
    init(
        position: SIMD3<Float> = .zero,
        forward: SIMD3<Float> = SIMD3(0, 0, 1),
        up: SIMD3<Float> = SIMD3(0, 1, 0),
        right: SIMD3<Float> = SIMD3(1, 0, 0),
        fov: Double = 45 / 180 * Double.pi,
        imageSize: SIMD2<Int>
    ) {
        self.position = position
        self.forward = forward
        self.up = up
        self.right = right
        self.fov = fov
        self.imageSize = imageSize
    }
    
    static var boxCamera: Camera {
        let o = SIMD3<Float>(0, 1, 5)
        let t = SIMD3<Float>(0, 0.7, 0)
        let d = normalize(t - o)
        
        return Camera(position: o, forward: d, fov: 8 * 27.7856 / 180 * Double.pi, imageSize: SIMD2<Int>(800, 600))
    }
}
