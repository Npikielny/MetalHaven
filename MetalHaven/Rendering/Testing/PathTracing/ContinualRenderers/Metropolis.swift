//
//  Metropolis.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/20/24.
//

import MetalAbstract

class Metropolis: ContinualIntegrator {
    var generator: Generator = PRNG()
    var regenProbability: Float { 1 / 3000 }
    var singlePass: Bool { true }
    var intersectionsPerSample: Int { 2 }
    var integrator = ComputeShader.Function(name: "mlt")
    
    typealias State = Int
    
    var shadingPoints = Buffer<ShadingPoint>(name: "Shading points")
    var shadingCount = Buffer<UInt32>(name: "Shading count")
    
    var supplementaryBuffers: [any ErasedBuffer] {
        [
            shadingPoints,
            shadingCount
        ]
    }
    
    lazy var samples: [Float] = [generator.generate(), generator.generate(), generator.generate(), generator.generate(), generator.generate(), 1] // First sample is on the light
    var lastContribution: Float = 0
    var used = 0
    var lightingSampler: LightingSampler!
    required init() {}
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {
        self.lightingSampler = LightingSampler(scene: scene)
        let imgSize = imageSize.x * imageSize.y
        while lastContribution == 0 {
            mltStep(scene: scene, imageSize: imgSize)
        }
//        for _ in 0..<1_000 {
//            mltStep(scene: scene, imageSize: imgSize)
//        }
//        print(lastContribution, shadingPoints.count)
    }
    
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> Int {
        imageSize.x * imageSize.y
    }
    
    func updateState(gpu: GPU, scene: GeometryScene, state: Int) async throws -> Int {
        mltStep(scene: scene, imageSize: state)
        return state
    }
    
    func mltStep(scene: GeometryScene, imageSize: Int) {
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
        let nPerturbations = max(generator.generate() * Float(used), 1)
        for _ in 0..<Int(nPerturbations) {
            let perturbationId = Int(generator.generate() * Float(used))
            currentSamples[Int(perturbationId)] = generator.generate()
        }
        
        let start = lightingSampler.sample(samples: SIMD3<Float>(getNextSample(), getNextSample(), getNextSample()), geometry: scene.geometry)
        var dir = sampleCosineHemisphere(SIMD2<Float>(getNextSample(), getNextSample()))
        
        if dot(dir, start.n) < 0 {
            dir *= -1
        }
        
        let fakeRay = createRay(start.p + start.n, -start.n)
        let lightIntersection = trace(ray: fakeRay, scene: scene.geometry)
        var currentIntersections = [ShadingPoint]()
        currentIntersections.append(ShadingPoint(
            intersection: lightIntersection,
            irradiance: start.emission
        ))
        let radiance = dot(dir, start.n) * start.emission
        
        var ray = createRay(start.p, dir)
        ray.state = TRACING
        ray.result = radiance
        var cont: Float = 1
        var iterations = 0
        
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
            ray.direction = next.dir
            ray.result *= abs(dot(-ray.direction, intersection.n)) * next.sample
            
//            if iterations >= 2 {
                cont = min(ray.result.max() * ray.eta * ray.eta, 0.99)
//            }
            iterations += 1
        }
        
        let contribution = length(ray.result)
        if generator.generate() < contribution / lastContribution {
//            contributions.append(contribution)
            lastContribution = contribution
            used = sampleId
            samples = currentSamples
            
//            print(currentIntersections.last!.irradiance)
//            currentIntersections[currentIntersections.count - 1].irradiance /= Float(contribution)
            shadingPoints.reset([currentIntersections.last!], usage: Usage.managed)
            shadingCount.reset([UInt32(1)], usage: .sparse)
//            if iteration > n / 8 {
//                intersections.append(contentsOf: currentIntersections)
//            }
//            print("accept", currentIntersections.count, contribution)
        }
        //        print(contributions)
//        print("LIGHT RAYS:", intersections.count)
//        print("Acceptance", Float(contributions.count) / Float(n))
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
        //            }
    }
}
