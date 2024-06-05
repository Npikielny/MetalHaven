//
//  LiveHybridMLT.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/21/24.
//

import Foundation
import MetalAbstract

class LiveHybridMLT: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 1 / 500 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 2 }
    
    var integrator = ComputeShader.Function(name: "hybridBidir")
    
    typealias State = ()
    
    var shadingPoints = Buffer<ShadingPoint>(name: "Shading points")
    var shadingCount = Buffer<UInt32>(name: "Shading count")
    
    var samples: [Float] = [] // First sample is on the light
    var lastContribution: Float = 0
    var used = 0
    var iterations = 0
    var lightingSampler: LightingSampler!
    
    required init() {}
    
    var supplementaryBuffers: [any ErasedBuffer] {
        [
            shadingPoints,
            shadingCount
        ]
    }
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {
        lightingSampler = LightingSampler(scene: scene)
        for _ in 0...10_000 {
            mltStep(scene: scene)
        }
    }
    
    
    func updateState(gpu: GPU, scene: GeometryScene, state: ()) async throws -> () {
        if iterations % 500 == 0 {
            NSLog("\(iterations)")
        }
//        for _ in 0...30 {
        mltStep(scene: scene)
        iterations += 1
//        }
        return ()
    }
    
    func mltStep(scene: GeometryScene) {
        var sampleId = 0
        // perturbation
        var currentSamples = samples
        let getNextSample: () -> Float = {
            defer { sampleId += 1 }
            if sampleId >= currentSamples.count {
                let s = self.generator.generate()
                currentSamples.append(s)
                return s
            }
            return currentSamples[sampleId]
        }
        if iterations > 0 {
            let nPerturbations = max(generator.generate() * Float(used), 1)
            for _ in 0..<Int(nPerturbations) {
                let perturbationId = Int(generator.generate() * Float(used))
                currentSamples[Int(perturbationId)] = generator.generate()
            }
        }
        
        let start = lightingSampler.sample(samples: SIMD3<Float>(getNextSample(), getNextSample(), getNextSample()), geometry: scene.geometry)
        var dir = sampleCosineHemisphere(SIMD2<Float>(getNextSample(), getNextSample()))
        
        if dot(dir, start.n) < 0 {
            dir *= -1
        }
        
        var currentIntersections = [ShadingPoint]()
        let fakeRay = createRay(start.p + start.n, -start.n)
        let lightIntersection = trace(ray: fakeRay, scene: scene.geometry)
        currentIntersections.append(ShadingPoint(
            intersection: lightIntersection,
            irradiance: start.emission
        ))
        let radiance = dot(dir, start.n) * start.emission
        
        var ray = createRay(start.p, dir)
        ray.state = TRACING
        ray.result = radiance
        var cont: Float = 1
        var bounces = 0
//        if getNextSample() < 0.1 {
//            if currentIntersections.isEmpty {
//                let fakeRay = createRay(start.p + start.n, -start.n)
//                let lightIntersection = trace(ray: fakeRay, scene: scene.geometry)
//                currentIntersections.append(ShadingPoint(
//                    intersection: lightIntersection,
//                    irradiance: start.emission * lightingSampler.totalArea / 0.1
//                ))
//            }
//        } else {
//            ray.result /= 0.9
//            
            while ray.state != FINISHED && getNextSample() < cont {
                ray.state = OLD
                ray.result /= cont
                
                let intersection = trace(ray: ray, scene: scene.geometry)
                if intersection.t == .infinity {
                    ray.state = FINISHED
                    continue
                }
                let next = smat(ray: ray, intersection: intersection, scene: scene, generator: generator.generate)
                currentIntersections.append(
                    ShadingPoint(
                        intersection: intersection,
                        irradiance: ray.result
                    )
                )
                
                ray.origin = intersection.p
                ray.direction = dot(-ray.direction, intersection.n) * dot(next.dir, intersection.n) > 0 ? next.dir : -next.dir
                ray.result *= abs(dot(-ray.direction, intersection.n)) * next.sample
                
                if bounces >= 1 {
                    cont = min(ray.result.max() * ray.eta * ray.eta, 0.99)
                }
                bounces += 1
            }
//        }
        
        
        let contribution = length(currentIntersections
            .map(\.irradiance)
            .reduce(.zero, +))
        if generator.generate() < contribution / lastContribution {
            lastContribution = contribution
            used = sampleId
            samples = currentSamples
            
            shadingPoints.reset(currentIntersections, usage: Usage.managed)
            shadingCount.reset([UInt32(currentIntersections.count)], usage: .sparse)
        }
    }
}
