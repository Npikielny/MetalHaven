//
//  MLT.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/19/24.
//

import Cocoa
import Charts
import MetalAbstract
import SwiftUI

struct MLT: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 1 / 300 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 2 }
    
    var integrator = ComputeShader.Function(name: "hybridBidir")
    
    typealias State = ()
    
    var shadingPoints = Buffer<ShadingPoint>(name: "Shading points")
    var shadingCount = Buffer<UInt32>(name: "Shading count")
    
    var supplementaryBuffers: [any ErasedBuffer] {
        [
            shadingPoints,
            shadingCount
        ]
    }
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {
        print("INITIALIZING")
        let lights = LightingSampler(scene: scene)
        var intersections = [ShadingPoint]()
        
        var samples = [generator.generate()]
        var lastContribution: Float = 0
        var used = 0
        var contributions = [Float]()
        let n = 100_000
        var last = [ShadingPoint]()
        for iteration in 0..<n {
            if iteration % 1000 == 0 {
                print(Float(iteration) / Float(n))
            }
            // perturbation
            var currentSamples = samples
            let nPerturbations = generator.generate() * Float(used)
            for _ in 0..<Int(nPerturbations) {
                let perturbationId = min(Int(generator.generate() * Float(used)), used - 1)
                currentSamples[Int(perturbationId)] = generator.generate()
            }
            
            var sampleId = 0
            let getNextSample: () -> Float = {
                defer { sampleId += 1 }
                if sampleId >= currentSamples.count {
                    let s = generator.generate()
                    currentSamples.append(s)
                    return s
                }
                return currentSamples[sampleId]
            }
            
            let start = lights.sample(samples: SIMD3<Float>(getNextSample(), getNextSample(), getNextSample()), geometry: scene.geometry)
            var dir = sampleCosineHemisphere(SIMD2<Float>(getNextSample(), getNextSample()))
            
            if dot(dir, start.n) < 0 {
                dir *= -1
            }
            
            let fakeRay = createRay(start.p + start.n, -start.n)
            let lightIntersection = trace(ray: fakeRay, scene: scene.geometry)
            var currentIntersections = [ShadingPoint]()
            currentIntersections.append(ShadingPoint(
                intersection: lightIntersection,
                irradiance: start.emission * lights.totalArea
            ))
            let radiance = dot(dir, start.n) * start.emission
            
            var ray = createShadingRay(start.p, dir)
            ray.state = TRACING
            ray.result = radiance
            var cont: Float = 1
            var iterations = 0
            
            while ray.state != FINISHED && generator.generate() < cont {
                ray.state = OLD
                ray.result /= cont
                
                let intersection = trace(ray: ray.ray, scene: scene.geometry)
                if intersection.t == .infinity {
                    ray.state = FINISHED
                    continue
                }
                let next = smat(ray: ray, intersection: intersection, scene: scene, generator: generator.generate)
                ray.ray.origin = intersection.p
                ray.ray.direction = next.dir
                ray.result *= abs(dot(-ray.ray.direction, intersection.n)) * next.sample
                currentIntersections.append(
                    ShadingPoint(
                        intersection: intersection,
                        irradiance: ray.result * lights.totalArea
                    )
                )
                
                if iterations >= 2 {
                    cont = min(ray.result.max() * ray.eta * ray.eta, 0.99)
                }
                iterations += 1
            }
            
            let contribution = length(currentIntersections.map(\.irradiance).reduce(.zero, +))
            if generator.generate() < contribution / lastContribution {
                contributions.append(contribution)
                lastContribution = contribution
                used = sampleId
                samples = currentSamples
                last = currentIntersections
                if iteration > n / 8 {
                    intersections.append(contentsOf: currentIntersections)
                }
            } else {
//                contributions.append(lastContribution)
                intersections.append(contentsOf: last)
            }
        }
//        print(contributions)
        shadingPoints.reset(intersections, usage: Usage.managed)
        shadingCount.reset([UInt32(intersections.count)], usage: .sparse)
        print("LIGHT RAYS:", intersections.count)
        print("Acceptance", Float(contributions.count) / Float(n))
//        let view = Chart(Array(contributions.enumerated()), id: \.offset) { (offset, element) in
//            LineMark(
//                x: .value("Iteration", offset),
//                y: .value("Contribution", element)
//            )
//        }
//            .frame(minWidth: 500, minHeight: 500)
//            .padding()
//        
//        Task {
//            await MainActor.run {
//                let controller = NSHostingController(rootView: view)
//                let window = NSWindow(contentViewController: controller)
//                window.makeKeyAndOrderFront(nil)
//            }
//        }
    }
}
