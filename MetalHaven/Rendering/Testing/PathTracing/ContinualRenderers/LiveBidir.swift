//
//  LiveBidir.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/23/24.
//

import MetalAbstract

class LiveBidir: ContinualIntegrator {
    var generator: Generator = PRNG()
    
    var regenProbability: Float { 1 / 300 }
    
    var singlePass: Bool { true }
    
    var intersectionsPerSample: Int { 2 }
    
    var integrator = ComputeShader.Function(name: "hybridBidir")
    
    typealias State = ()
    
    var shadingPoints = Buffer<ShadingPoint>(name: "Shading points")
    var shadingCount = Buffer<UInt32>(name: "Shading count")
    
    var lightingSampler: LightingSampler!
    
    var supplementaryBuffers: [any ErasedBuffer] {
        [
            shadingPoints,
            shadingCount
        ]
    }
    
    required init() {}
    
    func initialize(scene: GeometryScene, imageSize: SIMD2<Int>) {
        lightingSampler = LightingSampler(scene: scene)
        for _ in 0...30 {
            mltStep(scene: scene)
        }
    }
    
    
    func updateState(gpu: GPU, scene: GeometryScene, state: ()) async throws -> () {
        mltStep(scene: scene)
        return ()
    }
    
    func mltStep(scene: GeometryScene) {
        let start = lightingSampler.sample(samples: SIMD3<Float>(generator.generateVec3()), geometry: scene.geometry)
        var dir = sampleCosineHemisphere(SIMD2<Float>(generator.generateVec2()))
        
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
        var iterations = 0
        
        while ray.state != FINISHED && generator.generate() < cont {
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
            
            if iterations >= 1 {
                cont = min(ray.result.max() * ray.eta * ray.eta, 0.99)
            }
            iterations += 1
        }
        
        
        let contribution = length(currentIntersections
            .map(\.irradiance)
            .reduce(.zero, +))
        
        shadingPoints.reset(currentIntersections, usage: Usage.managed)
        shadingCount.reset([UInt32(currentIntersections.count)], usage: .sparse)
    }
}
