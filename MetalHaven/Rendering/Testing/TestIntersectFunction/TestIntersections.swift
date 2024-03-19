//
//  TestIntersections.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/18/23.
//

import Metal
import MetalAbstract

class TestIntersectionsIntegrator: SequenceIntegrator {
    var maxIterations: Int? = 1
    
    required init() {}
    
    func integrate(gpu: GPU, state: (), rays: Buffer<Ray>, intersections: Buffer<Intersection>, intersector: SequenceIntersector, emitters: [Light], materials: [Material]) async throws {
        
    }
}

class TestIntersectionsIntersector: SequenceIntersector {
    typealias State = ()
    
    var geometry: VoidBuffer!
    var typeBuffer: Buffer<GeometryType>!
    var countBuffer: Buffer<UInt32>!
    var mats: Buffer<BasicMaterial>!
    required init() {}
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    ) {
        geometry = VoidBuffer(name: "Objects", future: { gpu in
            
            guard let buf = gpu.device.makeBuffer(
                length: scene.geometry.map(\.stride).reduce(0, +),
                options: .storageModeManaged
            ) else { return nil }
            
            var offset = 0
            for obj in scene.geometry {
                offset += self.copy(geom: obj, ptr: buf.contents() + offset)
            }
            buf.didModifyRange(0..<buf.length)
            
            return (buf, scene.geometry.count)
        }, usage: .managed)
        typeBuffer = Buffer(name: "Types", scene.geometry.map(\.geometryType), usage: .managed)
        countBuffer = Buffer([UInt32(scene.geometry.count)], usage: .sparse)
        mats = Buffer(scene.materials as! [BasicMaterial], usage: .managed)
    }
    
    func copy(geom: some Geometry, ptr: UnsafeMutableRawPointer) -> Int {
        memcpy(ptr, [geom], geom.stride)
        return geom.stride
    }
    
    func intersect(gpu: GPU, rays: Buffer<Ray>, intersections: Buffer<Intersection>, indicator: Buffer<Bool>) async throws {
        print("genning")
        try! await gpu.execute {
            ComputeShader(
                name: "testIntersections",
                buffers: [
                    rays,
                    intersections,
                    mats,
                    geometry,
                    typeBuffer,
                    countBuffer,
                    indicator
                ],
                threadGroupSize: MTLSize(width: 8, height: 1, depth: 1),
                dispatchSize: ThreadGroupDispatchWrapper.groupsForSize(size: MTLSize(width: 8, height: 8, depth: 1), dispatch: MTLSize(width: intersections.count, height: 1, depth: 1))
            )
        }
    }
}

class TestMPSIntersector: SequenceIntersector {
//    var geometry: Buffer<Triangle>!
    var accelerationStructure: AcceleratedRayIntersector!
    var mats: Buffer<BasicMaterial>!
    
//    var instanceBuffer: MTLBuffer!
//    var accel: MTLAccelerationStructure!
//    var pipeline: MTLComputePipelineState!
//    var functionTable: MTLIntersectionFunctionTable!
    
    required init() {}
    
    func initialize(
        scene: GeometryScene,
        imageSize: SIMD2<Int>
    ) {
//        geometry = Buffer(scene.geometry as! [Triangle], usage: .managed)
//        let triangles = scene.geometry as! [Triangle]
        self.accelerationStructure = AcceleratedRayIntersector(
            triangles: scene.geometry as! [Triangle]
        )
        mats = Buffer(scene.materials as! [BasicMaterial], usage: .managed)
    }
    
    func intersect(
        gpu: GPU,
        rays: Buffer<Ray>,
        intersections: Buffer<Intersection>,
        indicator: Buffer<Bool>
    ) async throws {
        let lib = gpu.library!
        try await accelerationStructure.initialize(gpu: gpu, library: lib)
        let (instances, accel, pipeline, funcTable) = accelerationStructure.unpack()
        let rayBuffer = try rays.forceUnwrap()
        let intersections = try intersections.forceUnwrap()
        let materials = try mats.forceUnwrap()
        let convergence = try indicator.forceUnwrap()
        
        let commandBuffer = gpu.queue.makeCommandBuffer()
        let encoder = commandBuffer?.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(pipeline)
        encoder?.setBuffer(rayBuffer, offset: 0, index: 0)
        encoder?.setBuffer(intersections, offset: 0, index: 1)
        encoder?.setBuffer(materials, offset: 0, index: 2)
        encoder?.setBuffer(instances, offset: 0, index: 3)
        encoder?.setAccelerationStructure(accel, bufferIndex: 4)
        encoder?.setIntersectionFunctionTable(funcTable, bufferIndex: 5)
        encoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }
    
    func newAccelerationStructure(gpu: GPU, descriptor: MTLAccelerationStructureDescriptor) -> MTLAccelerationStructure {
        let size = gpu.device.accelerationStructureSizes(descriptor: descriptor)
        
        let accelerationStructure = gpu.device.makeAccelerationStructure(size: size.accelerationStructureSize)!
        
        let scratchBuffer = gpu.device.makeBuffer(length: size.buildScratchBufferSize)!
        let compactBufferSize = gpu.device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModeShared)!
        var commandBuffer = gpu.queue.makeCommandBuffer()
        let accelerationEncoder = commandBuffer?.makeAccelerationStructureCommandEncoder()
        
        accelerationEncoder?.build(
            accelerationStructure: accelerationStructure,
            descriptor: descriptor,
            scratchBuffer: scratchBuffer,
            scratchBufferOffset: 0
        )
        
        accelerationEncoder?.writeCompactedSize(
            accelerationStructure: accelerationStructure,
            buffer: compactBufferSize,
            offset: 0
        )
        accelerationEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        let compactedSize = compactBufferSize
            .contents()
            .bindMemory(to: UInt32.self, capacity: 1)
            .pointee
        
        let compactedAccelerationStructure = gpu
            .device
            .makeAccelerationStructure(size: Int(compactedSize))!
        
        commandBuffer = gpu.queue.makeCommandBuffer()
        let encoder = commandBuffer?.makeAccelerationStructureCommandEncoder()
        encoder?.copyAndCompact(
            sourceAccelerationStructure: accelerationStructure,
            destinationAccelerationStructure: compactedAccelerationStructure
        )
        encoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        return compactedAccelerationStructure
    }
}

class AcceleratedRayIntersector {
    var representation: Representation
    
    init(triangles: [Triangle]) {
        representation = .triangles(triangles)
    }
    
    func initialize(gpu: GPU, library: MTLLibrary) async throws {
        switch representation {
            case .accelerationStructures: return
            case .triangles(let triangles):
                var indices = [UInt16]()
                var vertices = [SIMD3<Float>]()
                for (index, triangle) in triangles.enumerated() {
                    vertices.append(triangle.v1)
                    vertices.append(triangle.v2)
                    vertices.append(triangle.v3)
                    
                    let offset = UInt16(index * 3)
                    indices.append(offset)
                    indices.append(offset + 1)
                    indices.append(offset + 2)
                    
                    indices.append(offset)
                    indices.append(offset + 2)
                    indices.append(offset + 1)
                }
                
//                let indexBuffer = Buffer(indices, usage: .managed)
//                let vertexBuffer = Buffer(vertices, usage: .managed)
                
                let geometryDescriptor = MTLAccelerationStructureTriangleGeometryDescriptor()
                geometryDescriptor.indexBuffer = gpu.device.makeBuffer(
                    bytes: indices,
                    length: MemoryLayout<UInt16>.stride * indices.count,
                    options: .storageModeManaged
                )
                geometryDescriptor.indexType = .uint16
                geometryDescriptor.vertexBuffer =  gpu.device.makeBuffer(
                    bytes: vertices,
                    length: MemoryLayout<SIMD3<Float>>.stride * vertices.count,
                    options: .storageModeManaged
                )
                geometryDescriptor.vertexStride = MemoryLayout<SIMD3<Float>>.stride
                geometryDescriptor.triangleCount = triangles.count * 2
                
//                geometryDescriptor.intersectionFunctionTableOffset
                
                let accelDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
                accelDescriptor.geometryDescriptors = [geometryDescriptor]
                let triangleAcceleration = newAccelerationStructure(gpu: gpu, descriptor: accelDescriptor)
                
                let instanceBuffer = gpu.device.makeBuffer(length: MemoryLayout<MTLAccelerationStructureInstanceDescriptor>.stride, options: .storageModeManaged)!
                var unwrappedInstance = instanceBuffer
                    .contents()
                    .bindMemory(to: MTLAccelerationStructureInstanceDescriptor.self, capacity: 1)
                    .pointee
                unwrappedInstance.accelerationStructureIndex = 0
                instanceBuffer.didModifyRange(0..<instanceBuffer.length)
//                unwrappedInstance.options = 0
                unwrappedInstance.intersectionFunctionTableOffset = 0;
                unwrappedInstance.mask = UInt32(0xFF)
                
                let instanceAccelDesc = MTLInstanceAccelerationStructureDescriptor()
                
                instanceAccelDesc.instancedAccelerationStructures = [triangleAcceleration]
                instanceAccelDesc.instanceCount = 1
                instanceAccelDesc.instanceDescriptorBuffer = instanceBuffer
                
//                instanceAccel.instancedAccelerationStructures = _primitiveAccelerationStructures;
//                instanceAccel.instanceCount = geometryCount;
//                instanceAccel.instanceDescriptorBuffer = _instanceBuffer;
//                
//                // Create the instance acceleration structure that contains all instances in the scene.
//                _instanceAccelerationStructure = [self newAccelerationStructureWithDescriptor:instanceAccelDescriptor];
                
                let instanceAccel = newAccelerationStructure(gpu: gpu, descriptor: instanceAccelDesc)
                
                let triangleIntersector = library.makeFunction(name: "testIntersections")!
                
                let linkedFunction = MTLLinkedFunctions()
                linkedFunction.functions = [triangleIntersector]
                
                let intersectorTest = library.makeFunction(name: "testIntersector")
                let computeDescriptor = MTLComputePipelineDescriptor()
                computeDescriptor.computeFunction = intersectorTest
                computeDescriptor.linkedFunctions = linkedFunction
//                computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
                
                let (pipeline, _) = try await gpu.device.makeComputePipelineState(descriptor: computeDescriptor, options: MTLPipelineOption())
                
                let functionTableDesc = MTLIntersectionFunctionTableDescriptor()
                functionTableDesc.functionCount = 1
                
                let functionTable = pipeline.makeIntersectionFunctionTable(descriptor: functionTableDesc)!
                
                let handle = pipeline.functionHandle(function: triangleIntersector)
                functionTable.setFunction(handle, index: 0)
                
                representation = .accelerationStructures(instanceBuffer, instanceAccel, pipeline, functionTable)
        }
    }
    
    func newAccelerationStructure(gpu: GPU, descriptor: MTLAccelerationStructureDescriptor) -> MTLAccelerationStructure {
        let size = gpu.device.accelerationStructureSizes(descriptor: descriptor)
        
        let accelerationStructure = gpu.device.makeAccelerationStructure(size: size.accelerationStructureSize)!
        
        let scratchBuffer = gpu.device.makeBuffer(length: size.buildScratchBufferSize)!
        let compactBufferSize = gpu.device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModeShared)!
        var commandBuffer = gpu.queue.makeCommandBuffer()
        let accelerationEncoder = commandBuffer?.makeAccelerationStructureCommandEncoder()
        
        accelerationEncoder?.build(
            accelerationStructure: accelerationStructure,
            descriptor: descriptor,
            scratchBuffer: scratchBuffer,
            scratchBufferOffset: 0
        )
        
        accelerationEncoder?.writeCompactedSize(
            accelerationStructure: accelerationStructure,
            buffer: compactBufferSize,
            offset: 0
        )
        accelerationEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        let compactedSize = compactBufferSize
            .contents()
            .bindMemory(to: UInt32.self, capacity: 1)
            .pointee
        
        let compactedAccelerationStructure = gpu
            .device
            .makeAccelerationStructure(size: Int(compactedSize))!
        
        commandBuffer = gpu.queue.makeCommandBuffer()
        let encoder = commandBuffer?.makeAccelerationStructureCommandEncoder()
        encoder?.copyAndCompact(
            sourceAccelerationStructure: accelerationStructure,
            destinationAccelerationStructure: compactedAccelerationStructure
        )
        encoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        return compactedAccelerationStructure
    }
    
//    func encode(gpu: GPU, commandBuffer: MTLCommandBuffer) async throws {
//        guard case let .accelerationStructures(instance, accel, state, functions) = representation else { fatalError() }
//        
//        let encoder = commandBuffer.makeComputeCommandEncoder()
//        encoder?.setComputePipelineState(state)
//        encoder?.setBuffer(instance, offset: 0, index: 0)
//        encoder?.setAccelerationStructure(accel, bufferIndex: 1)
//        encoder?.setBuffer(<#T##buffer: MTLBuffer?##MTLBuffer?#>, offset: <#T##Int#>, index: <#T##Int#>)
//        
//        
//        encoder?.endEncoding()
//    }
//    
    func unpack() -> (MTLBuffer, MTLAccelerationStructure, MTLComputePipelineState, MTLIntersectionFunctionTable) {
        guard case let .accelerationStructures(instance, accel, compute, funcs) = representation else {
            fatalError()
        }
        return (instance, accel, compute, funcs)
    }
    
    enum Representation {
        case triangles([Triangle])
        case accelerationStructures(MTLBuffer, MTLAccelerationStructure, MTLComputePipelineState, MTLIntersectionFunctionTable)
    }
}

extension UInt16: GPUEncodable {}

