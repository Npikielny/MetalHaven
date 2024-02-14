//
//  Grapher.metal
//  MetalHaven
//
//  Created by Noah Pikielny on 2/14/24.
//

#include <metal_stdlib>
using namespace metal;

constant float MAJOR_GRIDLINES = 0.25;
constant float MINOR_GRIDLINES = 0.25 / 5;

[[kernel]]
void drawBackground(uint2 tid [[thread_position_in_grid]],
                    constant float4 & bounds,
                    texture2d<half, access::write> background) {
    float2 uv = float2(tid) / float2(background.get_width(), background.get_height());
    float2 MIN = float2(bounds.x, bounds.z);
    float2 MAX = float2(bounds.y, bounds.w);
    float2 p = uv * (MAX - MIN) + MIN;
    
    if (abs(p.x) < 0.005 || abs(p.y) < 0.005) {
        background.write(1, tid);
        return;
    }
    
    float2 offset = round(p / MAJOR_GRIDLINES);
    float2 deviation = abs(p - offset * MAJOR_GRIDLINES) / MAJOR_GRIDLINES;
    
    if (abs(deviation.x) < 0.01 || abs(deviation.y) < 0.01) {
        background.write(0.5, tid);
        return;
    }
    offset = round(p / MINOR_GRIDLINES);
    deviation = abs(p - offset * MINOR_GRIDLINES) / MINOR_GRIDLINES;
    if (abs(deviation.x) < 0.04 || abs(deviation.y) < 0.04) {
        background.write(0.25, tid);
        return;
    }
    background.write(0, tid);
    
//    float x = modf(p.x, f);
//    background.write(f < 0.1 ? 1 : 0, tid);
//    background.write(0, tid);
}

//[[kernel]]
//void drawFunction(uint2 tid [[thread_position_in_grid]],
//                    constant float4 & bounds,
//                    texture2d<half, access::write> background) {
//    float2 uv = float2(tid) / float2(background.get_width(), background.get_height());
//    float2 MIN = float2(bounds.x, bounds.z);
//    float2 MAX = float2(bounds.y, bounds.w);
//    float2 p = uv * (MAX - MIN) + MIN;
//    
//    float x = p.x;
//    float y = p.y;
//
//    float a;// = \(parser.retextualize(symbols: lhs));
//    float b;// = \(parser.retextualize(symbols: rhs));
//    if (abs(a - b) < 0.01) {
//        background.write(half4(0.1, 0.3, 1, 1), tid);
//    }
//}
