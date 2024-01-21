//
//  Frame.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/18/23.
//

import Foundation

struct Frame {
    var up: Vec3
    var forward: Vec3
    var right: Vec3
    
    init(n: Vec3, ray: Vec3) {
        up = n
        right = cross(n, ray)
        forward = cross(right, up)
    }
    
    func toFrame(v: Vec3) -> Vec3 {
        v.x * right + v.y * up + v.z * forward
    }
}
