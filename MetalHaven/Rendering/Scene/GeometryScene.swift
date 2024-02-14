//
//  Scene.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 7/2/23.
//

import Foundation

protocol Light {}
extension PointLight: Light {}
extension DirectionLight: Light {}

struct GeometryScene {
    var lights: [Light]
    var geometry: [any Geometry]
    var materials: [Material]
}

