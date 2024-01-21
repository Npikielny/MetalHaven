// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MetalBridgeMacros", type: "StringifyMacro")

//@attached(memberAttribute)
//public macro bridge<T>(_ value: T) = #externalMacro(
//    module: "MetalBridgeMacros",
//    type: "BridgeMacro"
//)
