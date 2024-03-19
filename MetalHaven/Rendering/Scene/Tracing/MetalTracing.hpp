//
//  MetalTracing.hpp
//  MetalHaven
//
//  Created by Noah Pikielny on 1/14/24.
//

#ifndef MetalTracing_h
#define MetalTracing_h

#import "../Core3D.h"
#import "../Lighting/Lighting.h"
#import "../Geometry/Geometry.h"
#import "../../Sampling/Sampling.h"

Intersection trace(Ray ray,
                      constant char * scene,
                      constant GeometryType * types,
                      uint objectCount);
#endif /* MetalTracing_h */
