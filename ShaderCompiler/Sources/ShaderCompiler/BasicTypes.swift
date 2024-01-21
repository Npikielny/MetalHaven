//
//  BasicTypes.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 12/31/23.
//

import Foundation

protocol RawComponent: ShadingComponent {
    init()
}
protocol NumericComponent: ShadingComponent {
    associatedtype Raw
    var components: Int { get }
}

protocol BasicTypes: CustomStringConvertible {}
extension BasicTypes {
    var description: String { "" }
}
class FloatComponent: NumericComponent, RawComponent, BasicTypes {
    typealias Raw = Float
    let components: Int = 1
    
    required init() {}
}

class UIntComponent: NumericComponent, RawComponent, BasicTypes {
    typealias Raw = UInt32
    let components: Int = 1
    
    required init() {}
}

class IntComponent: NumericComponent, RawComponent, BasicTypes {
    typealias Raw = Int32
    let components: Int = 1
    
    required init() {}
}

protocol Constant: NumericComponent {
    associatedtype Rep: NumericComponent
}


class ConstantWrapper<T: Constant>: NumericComponent, BasicTypes {
    typealias Raw = T
    
    var components: Int { wrapped.components }
    var wrapped: T
    
    init(_ wrapped: T) {
        self.wrapped = wrapped
    }
}

protocol ScalarConstant: Constant where Raw == Self {}
extension ScalarConstant {
    var components: Int { 1 }
}
extension Float: ScalarConstant { typealias Rep = FloatComponent }
extension UInt32: ScalarConstant { typealias Rep = UIntComponent }
extension Int: ScalarConstant { typealias Rep = IntComponent }

protocol VectorConstant: SIMD, Constant where Scalar: Constant, Raw == Scalar.Raw {}
extension VectorConstant { var components: Int { Self.scalarCount } }

// TODO: Vector conformance
//extension SIMD2: ShadingComponent where Scalar: Constant, Raw == Scalar.Raw, Rep == Vec2<Scalar.Rep> {
//    
//}

//extension SIMD2: NumericComponent where Scalar: Constant, Raw == Scalar.Raw, Rep == Vec2<Scalar.Rep> {
//}
//
//extension SIMD2: Constant where Scalar: Constant, Raw == Scalar.Raw, Rep == Vec2<Scalar.Rep> {}
//
//extension SIMD2: Constant where Scalar: Constant {
//    typealias Rep = <#type#>
//    
//    typealias Raw = <#type#>
//    
//    var components: Int {
//        <#code#>
//    }
//    
//    typealias Rep = Vec2<Scalar.Rep>.Raw
//    
////    typealias Rep = <#type#>
////    typealias Rep = Vec2<Scalar.Rep>.Raw
//}
//extension SIMD3: Constant where Scalar: Constant { typealias Rep = Vc3<Scalar.Rep>.Raw }
//extension SIMD4: Constant where Scalar: Constant { typealias Rep = Vec4<Scalar.Rep>.Raw }

//let a = Vec4<FloatComponent>.Raw.self

//let t = ConstantWrapper(SIMD4<Float>(0, 0, 0, 1)) * ConstantWrapper(Float(4.0))// + ConstantWrapper(Float(3.0))
//let b = try! a.init() + FloatComponent()
//let t = try! Vec4f() + FloatComponent()
