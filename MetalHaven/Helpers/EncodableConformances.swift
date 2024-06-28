//
//  EncodableConformances.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/3/23.
//

import MetalAbstract

extension Bool: GPUEncodable {}
extension float3x3: GPUEncodable {}

// Tracing
extension Intersection: GPUEncodable {}
extension ShadingRay: GPUEncodable {}

// Geometry
extension PointLight: GPUEncodable {}


