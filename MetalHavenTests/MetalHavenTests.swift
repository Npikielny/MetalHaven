//
//  MetalHavenTests.swift
//  MetalHavenTests
//
//  Created by Noah Pikielny on 7/2/23.
//

import XCTest
@testable import MetalHaven

final class MetalHavenTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testExpression() throws {
        let parser = Parser()
        
        let result = try parser.parseStatement(statement: "x(42/x-3) + uv*4 = 123/4")
        print(result)
        print(parser.retextualize(symbols: result.lhs))
        print(result.1)
        print(parser.retextualize(symbols: result.rhs))
        
        try print(parser.split(expression: "sin(x)"))
    }
    
    func testSampling() throws {
        let ptr = UnsafeMutablePointer<HaltonSampler>.allocate(capacity: 1)
        ptr.pointee = HaltonSampler(seed: 3, uses: 1)
        let sampled = sampleUniformDisk(generateVec2(ptr))
        print(sampled)
        assert(uniformDiskPdf(sampled) > 0)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
