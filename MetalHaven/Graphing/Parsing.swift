//
//  Parsing.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/14/24.
//

import Foundation

class Parser {
    typealias Statement = (lhs: [Symbol], eq: Character, rhs: [Symbol])
    func valid(statement: Statement) -> Bool {
        let left = validExpression(statement.lhs)
        let right = validExpression(statement.rhs)
        let res = left && right
        print(left, statement.lhs, right, statement.rhs)
        return res
    }
    func validExpression(_ symbols: [Symbol]) -> Bool {
        var inParens = 0
        var outParens = 0
        for (index, i) in symbols.enumerated() {
            switch i {
                case .in:
                    inParens += 1
                case .out:
                    outParens += 1
                case .operation(_):
                    guard index != 0 && index < symbols.count - 1,
                          !symbols[index - 1].isOp,
                          !symbols[index + 1].isOp else {
                        return false
                    }
                case .function(_):
                    guard index < symbols.count - 1, case .in = symbols[index + 1] else { return false }
                    continue
                case .expression(_, _):
                    continue
            }
        }
        return inParens == outParens
    }
    
    func split(expression: String) throws -> [Symbol] {
        var terms = [Symbol]()
        var term = Symbol.expression(.expression, "")
        
        for i in expression {
            switch i {
                case " ":
                    continue
                case let x where x.isLetter:
                    if case let .expression(.variable, string) = term {
                        term = .expression(.variable, string + String(x))
                    } else {
                        terms.append(term)
                        if needsMult(last: term) {
                            terms.append(.operation("*"))
                        }
                        term = .expression(.variable, String(x))
                    }
                case let x where operations.contains(x):
                    terms.append(term)
                    term = .operation(x)
                case let x where x.isNumber || x == ".":
                    if case let .expression(.number, string) = term {
                        term = .expression(.number, string + String(x))
                    } else {
                        terms.append(term)
                        if needsMult(last: term) {
                            terms.append(.operation("*"))
                        }
                        term = .expression(.number, String(x))
                    }
                case let x where x == "(":
                    if case let .expression(.variable, str) = term, let fn = Function.enumerate(str) {
                        term = .function(fn)
                        terms.append(term)
                    } else {
                        terms.append(term)
                    }
                    if needsMult(last: term) {
                        terms.append(.operation("*"))
                    }
                    term = .in
                case let x where x == ")":
                    terms.append(term)
                    term = .out
                default:
                    throw ParserError.unrecognizedSymbol(i)
            }
        }
        terms.append(term)
        
        if terms.count > 2 {
            return Array(terms[2...])
        } else {
            throw ParserError.failedToParse(reason: "Not sufficient args \(terms)")
        }
    }
    
    var equalities: [Character] = ["=", "<", ">", "≤", "≥"]
    
    func parseStatement(statement: String) throws -> Statement {
        for i in equalities {
            if let idx = statement.lastIndex(of: i) {
                let before = String(statement[..<idx])
                let after = String(statement[statement.index(after: idx)...])
                return (
                    try split(expression: before),
                    i,
                    try split(expression: after)
                )
            }
        }
        throw ParserError.failedToParse(reason: "No equality")
    }
    
    enum ParserError: Error {
        case unrecognizedSymbol(Character)
        case failedToParse(reason: String)
    }
    
    enum Term {
        case variable
        case number
        case expression
    }
    
    enum Symbol: CustomStringConvertible {
        case `in`
        case out
        case expression(Term, String)
        case operation(Character)
        case function(Function)
        
        var description: String {
            switch self {
                case let .expression(term, string):
                    switch term {
                        case .variable:
                            "var: \(string)"
                        case .number:
                            "num: \(string)"
                        case .expression:
                            "exp: \(string)"
                    }
                case let .function(fn): "\(fn)"
                case let .operation(character):
                    "op: " + String(character)
                case .in: "("
                case .out: ")"
            }
        }
        var isOp: Bool {
            if case .operation(_) = self {
                return true
            }
            return false
        }
    }
    
    func needsMult(last: Symbol) -> Bool {
        switch last {
            case .expression(_, _), .out:
                true
            default:
                false
        }
    }
    
    var operations: [Character] = ["*", "-", "/", "+"]
    
    enum DefaultFunction: CaseIterable {
        case sin
        case cos
        case tan
        case log
    }
    
    enum Function: CustomStringConvertible {
        case defaultFunctions(DefaultFunction)
        case custom(String)
        
        static var customFunctions = [String]()
        
        static func enumerate(_ str: String) -> Function? {
            if let fn = customFunctions.first { $0 == str } {
                return .custom(fn)
            }
            for i in DefaultFunction.allCases {
                if "\(i)" == str {
                    return .defaultFunctions(i)
                }
            }
            return nil
        }
        
        var description: String {
            switch self {
                case let .custom(fn): fn
                case let .defaultFunctions(def): "\(def)"
            }
        }
    }
    
    func retextualize(symbols: [Symbol]) -> String {
        var out = ""
        for symbol in symbols {
            switch symbol {
                case .in:
                    out += "("
                case .out:
                    out += ")"
                case .expression(_, let string):
                    out += string
                case .function(let fn):
                    out += "\(fn)"
                case .operation(let character):
                    out += String(character)
            }
        }
        return out
    }
    
//    enum Token {
//        case expression(Expression)
//        case binaryOperation(String)
//    }
//
//    func tokenize
}
