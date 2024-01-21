//
//  Material.swift
//
//
//  Created by Noah Pikielny on 12/31/23.
//

import Foundation

protocol Material {}

class Diffuse: Material {
    var color = VariableComponent(wrappedValue: Vec3f(), name: "color")
}
