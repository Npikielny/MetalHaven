//
//  Binops.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 12/31/23.
//

import Foundation

class BinopAbstract<T: NumericComponent, K: NumericComponent> where T.Raw == K.Raw {
    typealias Raw = T.Raw
    
    var components: Int { max(lhs.components, rhs.components) }
    
    var lhs: T
    var rhs: K
    
    init(lhs: T, rhs: K) {
        self.lhs = lhs
        self.rhs = rhs
    }
}

protocol Binop: NumericComponent {
    associatedtype T: ShadingComponent
    associatedtype K: ShadingComponent
    var lhs: T { get }
    var rhs: K { get }
    var desc: String { get }
}

extension Binop {
    var description: String {
        "\(lhs.description) \(desc) \(rhs.description)"
    }
}

typealias BinopComponent<T: NumericComponent, K: NumericComponent> = BinopAbstract<T, K> & Binop where T.Raw == K.Raw

class AddComponent<T: NumericComponent, K: NumericComponent>: BinopComponent<T, K> where T.Raw == K.Raw {
    var desc: String { "+" }
}

func +<T: NumericComponent, K: NumericComponent>(lhs: T, rhs: K) throws -> AddComponent<T, K> where T.Raw == K.Raw {
    guard lhs.components == 1 || lhs.components == 1 || lhs.components == rhs.components else {
        throw AnyError(desc: "Unable to add vectors of different lengths (\(lhs.components), \(rhs.components))")
    }
    
    return AddComponent(lhs: lhs, rhs: rhs)
}

class SubComponent<T: NumericComponent, K: NumericComponent>: BinopComponent<T, K> where T.Raw == K.Raw {
    var desc: String { "-" }
}

func -<T: NumericComponent, K: NumericComponent>(lhs: T, rhs: K) throws -> SubComponent<T, K> where T.Raw == K.Raw {
    guard lhs.components == 1 || lhs.components == 1 || lhs.components == rhs.components else {
        throw AnyError(desc: "Unable to add vectors of different lengths (\(lhs.components), \(rhs.components))")
    }
    
    return SubComponent(lhs: lhs, rhs: rhs)
}

class MulComponent<T: NumericComponent, K: NumericComponent>: BinopComponent<T, K> where T.Raw == K.Raw {
    var desc: String { "*" }
}

func *<T: NumericComponent, K: NumericComponent>(lhs: T, rhs: K) throws -> MulComponent<T, K> where T.Raw == K.Raw {
    guard lhs.components == 1 || lhs.components == 1 || lhs.components == rhs.components else {
        throw AnyError(desc: "Unable to add vectors of different lengths (\(lhs.components), \(rhs.components))")
    }
    
    return MulComponent(lhs: lhs, rhs: rhs)
}

class DivComponent<T: NumericComponent, K: NumericComponent>: BinopComponent<T, K> where T.Raw == K.Raw {
    var desc: String { "/" }
}

func /<T: NumericComponent, K: NumericComponent>(lhs: T, rhs: K) throws -> DivComponent<T, K> where T.Raw == K.Raw {
    guard lhs.components == 1 || lhs.components == rhs.components else {
        throw AnyError(desc: "Unable to add vectors of different lengths (\(lhs.components), \(rhs.components))")
    }
    
    return DivComponent(lhs: lhs, rhs: rhs)
}
