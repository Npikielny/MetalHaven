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
        
        for i in 0...10_000 {
            if i % 200 == 0 {
                print(Float(i) / Float(10_000))
            }
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
                
                let intersection = trace(ray: ray, scene: scene.geometry)
                if intersection.t == .infinity {
                    ray.state = FINISHED
                    continue
                }
                let next = smat(ray: ray, intersection: intersection, scene: scene, generator: generator.generate)
                ray.origin = intersection.p
                ray.direction = next.dir
                ray.result *= abs(dot(-ray.direction, intersection.n)) * next.sample
                intersections.append(
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
//            print(ray.throughput)
        }
        shadingPoints.reset(intersections, usage: Usage.managed)
        shadingCount.reset([UInt32(intersections.count)], usage: .sparse)
        print("LIGHT RAYS:", intersections.count)
    }
}

func smat(ray: Ray, intersection: Intersection, scene: GeometryScene, generator: () -> Float) -> MaterialSample {
    let material = scene.materials[Int(intersection.materialId)]
    switch material.type {
        case BASIC:
            let dir = sampleCosineHemisphere(vector_float2(generator(), generator()))
            return MaterialSample(
                sample: material.reflectance,
                dir: toFrame(dir, intersection.frame),
                eta: 1,
                pdf: cosineHemispherePdf(dir)
            )
        case MIRROR:
            return MaterialSample(
                sample: material.reflectance,
                dir: reflect(ray.direction, n: intersection.n),
                eta: 1,
                pdf: 1
            )
        case DIELECTRIC:
            let mat = material as! Dielectric
            let c = dot(-ray.direction, intersection.n)
            let f = fresnel(c, 1.000277, mat.IOR)
            
            let entering = dot(ray.direction, intersection.n) < 0
            let eta1 = entering ? 1.000277 : mat.IOR
            let eta2 = entering ? mat.IOR : 1.000277
            
            var sample = MaterialSample()
            sample.pdf = 1
            if generator() < f {
                sample.dir = reflect(ray.direction, n: intersection.n)
                sample.sample = mat.reflectance
                sample.eta = 1
            } else {
                let eta = eta1 / eta2
                sample.dir = refract(ray.direction, n: intersection.n, eta: eta)
                sample.eta = 1 / eta
                sample.sample = mat.reflectance
            }
            return sample 
        default: fatalError()
            
    }
}

extension ShadingPoint: GPUEncodable {}
