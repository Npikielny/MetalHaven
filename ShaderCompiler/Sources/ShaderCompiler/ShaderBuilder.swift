//
//  ShaderBuilder.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 12/31/23.
//

import Foundation

struct AnyError: Error {
    var desc: String
}

protocol ShadingComponent: CustomStringConvertible {
}

//protocol NumberComponent {
//    static var raw: Set<Any> { get }
//}

@propertyWrapper
class VariableComponent<T: ShadingComponent>: ShadingComponent {
    var wrappedValue: T
    var name: String = ""
    
    init(wrappedValue: T, name: String) {
        self.wrappedValue = wrappedValue
        self.name = name
    }
    
    var description: String { ".\(name)" }
}

extension VariableComponent: NumericComponent where T: NumericComponent {
    var components: Int { wrappedValue.components }
    
    typealias Raw = T.Raw
}

protocol IntegratorComponent: ShadingComponent {
    var t: VariableComponent<FloatComponent> { get } // Float
    var p: VariableComponent<Vec3f> { get } // Vec3
    var n: VariableComponent<Vec3f> { get } // Vec3
    var material: VariableComponent<UIntComponent> { get }
}

class Shading {
    // Intersection, Ray, Material, Sampler
    
    // On Termination
}


