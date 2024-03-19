//
//  HybridBidir.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 3/18/24.
//

import MetalAbstract

struct HybridBidir: ContinualIntegrator {
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
        
        for _ in 0...10000 {
            let start = lights.sample(samples: generator.generateVec3(), geometry: scene.geometry)
            var dir = sampleCosineHemisphere(generator.generateVec2())
            
            if dot(dir, start.n) < 0 {
                dir *= -1
            }
            
            let fakeRay = createRay(start.p + start.n, -start.n)
            let lightIntersection = trace(ray: fakeRay, scene: scene.geometry)
            intersections.append(ShadingPoint(
                intersection: lightIntersection,
                irradiance: start.emission * lights.totalArea
            ))
            let radiance = dot(dir, start.n) * start.emission
            
            var ray = createRay(start.p, dir)
            ray.state = TRACING
            ray.result = radiance
            var cont: Float = 1
            var iterations = 0
            
            while ray.state != FINISHED && generator.generate() < cont {
//                print(iterations)
                ray.state = OLD
                ray.result /= cont
                
                let next = trace(ray: ray, scene: scene.geometry)
                if next.t == .infinity {
                    ray.state = FINISHED
                    continue
                }
                ray.origin = next.p
                let dir = sampleCosineHemisphere(generator.generateVec2())
                let warped = toFrame(dir, next.frame)
                ray.result *= abs(dot(-ray.direction, next.n)) * scene.materials[Int(next.materialId)].reflectance
                intersections.append(
                    ShadingPoint(
                        intersection: next,
                        irradiance: ray.result * lights.totalArea
                    )
                )
                ray.direction = warped
                
                if iterations >= 2 {
                    cont = min(ray.result.max() * ray.eta * ray.eta, 0.99)
                }
                iterations += 1
            }
//            print(ray.throughput)
        }
        shadingPoints.reset(intersections, usage: Usage.managed)
        shadingCount.reset([UInt32(intersections.count)], usage: .sparse)
        print("LIGHT RAYS:", intersections.count)
    }
    
    func generateState(frame: Int, imageSize: SIMD2<Int>) -> () {
        
    }
}

extension ShadingPoint: GPUEncodable {}
