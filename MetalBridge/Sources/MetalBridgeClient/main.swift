import MetalBridge

@dynamicMemberLookup
struct BasicType {
    var p: SIMD3<Float>
    var id: UInt
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Piece1, T>) -> T {
        get { self. }
    }
}

protocol Component {}

protocol Bridgeable {
    
}

protocol Constant: Bridgeable {
    associatedtype Raw: Component
    var other: Raw { get }
}

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")
