//
//  ThreadManager.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/17/23.
//

import Foundation

actor ThreadManager {
    typealias Thread<Partial> = () async throws -> Partial
    static func dispatch<Partial, Result>(max: Int, threads: [Thread<Partial>], initial: Result, reducer: (Result, Partial) async throws -> Result) async throws -> Result {
        typealias Cont = AsyncStream<Partial>.Continuation
        
        var threads = threads
        
        var tempCont: Cont!
        
        let stream = AsyncStream<Partial> {
            tempCont = $0
        }
        let cont = tempCont
        
        let dispatchNext: (Cont, Thread) async throws -> Void = { cont, thread in
            cont.yield(try await thread())
        }
        
        for _ in 0..<max {
            if let thread = threads.popLast() {
                Task { try await dispatchNext(cont!, thread) }
            }
        }
        
        var result = initial
        var used = max
        for try await partial in stream {
            if let next = threads.popLast() {
                Task { try await dispatchNext(cont!, next) }
            } else {
                used -= 1
                if used <= 0 {
                    cont!.finish()
                }
            }
            result = try await reducer(result, partial)
        }
        return result
    }
}
