//
//  VectorTypes.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 12/31/23.
//

import Foundation

class VectorComponent<T: NumericComponent & RawComponent>: NumericComponent, BasicTypes {
    typealias Raw = T.Raw
    var components: Int { 0 }
    
    var x: VariableComponent<T> { VariableComponent(wrappedValue: T(), name: "x") }
}

class Vec2<T: NumericComponent & RawComponent>: VectorComponent<T> {
    var y: VariableComponent<T> { VariableComponent(wrappedValue: T(), name: "y") }
}
class Vc3<T: NumericComponent & RawComponent>: Vec2<T> { //MARK: FIX Name
    var z: VariableComponent<T> { VariableComponent(wrappedValue: T(), name: "z") }
}
class Vec4<T: NumericComponent & RawComponent>: Vc3<T> {
    var xyz: VariableComponent<Vc3<T>> { VariableComponent(wrappedValue: Vc3(), name: "xyz") }
    var w: VariableComponent<T> { VariableComponent(wrappedValue: T(), name: "xyz") }
}

typealias Vec2f = Vec2<FloatComponent>
typealias Vec3f = Vc3<FloatComponent>
typealias Vec4f = Vec4<FloatComponent>
