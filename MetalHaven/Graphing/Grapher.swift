//
//  Grapher.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/14/24.
//

import Combine
import MetalAbstract
import SwiftUI

struct Grapher: View {
    let view: MAView
    
    let timer = Timer.publish(every: 1 / 30, on: .main, in: .default)
        .autoconnect()
    
    @State var equations: [String] = ["y+x=0"]
    @State var functions: [Parser.Statement?] = [try! Parser().parseStatement(statement: "y=x")]
    @State var tolerances = [0.005]
    
    let parser = Parser()
    let future: Future<ComputeShader>
    
    let boundsBuffer: Buffer<SIMD4<Float>>
    @State var bounds = SIMD4<Float>(-1, 1, -1, 1)
    init() {
        let tex = Texture(name: "Background", format: .rgba16Float, width: 1024, height: 1024, depth: 1, storageMode: .private, usage: [.shaderRead, .shaderWrite])
        let bounds = Buffer([SIMD4<Float>(-1, 1, -1, 1)], usage: .sparse)
        
        let bg = ComputeShader(
            name: "drawBackground",
            buffers: [bounds],
            textures: [tex],
            threadGroupSize: MTLSize(width: 8, height: 8, depth: 1)
        )
        let copy = RasterShader(
            vertexShader: "getCornerVerts",
            fragmentShader: "copyTexture",
            fragmentTextures: [tex],
            fragmentBuffers: [Buffer([Float(2)], usage: .sparse)],
            passDescriptor: .drawable,
            texture: tex
        )
        
        self.boundsBuffer = bounds
        
        let future = Future<ComputeShader>()
        self.future = future
        
        var t = 0.0
        self.view = MAView(
            gpu: .default,
            frame: CGRect(origin: .zero, size: CGSize(width: 1024, height: 1024)),
            format: .rgba16Float,
            draw: { gpu, drawable, descriptor in
                t += 1 / 30
                guard let drawable, let descriptor else { print("No context"); return }
                
                if let shader = future.wrapped {
                    shader.textures = [tex]
                    shader.buffers = [bounds, Buffer([Float(t)], usage: .sparse)]
                    try await gpu.execute(drawable: drawable, descriptor: descriptor) {
                        bg
                        shader
                        copy
                    }
                } else {
                    try await gpu.execute(drawable: drawable, descriptor: descriptor) {
                        bg
                        copy
                    }
                }
            }
        )
        compile()
    }
    
    static let fn = VariableComponent(wrappedValue: Vec2f(), name: "uv").wrappedValue.x
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                VStack {
                    HStack {
                        Button {
                            let theta = Float(equations.count) * Float.pi / 20 + Float.pi / 4
                            let fn = "\(abs(sin(theta)))y+\(abs(cos(theta)))x=0"
                            equations.append(fn)
                            functions.append(try! parser.parseStatement(statement: fn))
                            tolerances.append(0.005)
                            compile()
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        
                        Button {
                            let start = bounds
                            let dest = SIMD4<Float>(-1, 1, -1, 1)
                            var t: Task<(), Never>?
                            t = Task {
                                for i in 0...10 {
                                    let alpha = Float(i) / Float(10)
                                    let lerp = alpha * dest + (1 - alpha) * start
                                    await MainActor.run {
                                        bounds = lerp
                                        boundsBuffer[0] = lerp
                                    }
//                                    t.sleep(nanoseconds: 1000)
//                                    try await Task.sleep(nanoseconds: 10000)

                                }
                            }
                        } label: {
                            Image(systemName: "house.fill")
                        }

                    }
                    
                    ForEach(Array(equations.enumerated()), id: \.0) { (id, eq) in
                        HStack {
                            VStack {
                                TextField(
                                    "Equation \(id):",
                                    text: Binding(
                                        get: {
                                            if id < equations.count {
                                                return equations[id]
                                            }
                                            return ""
                                        }, set: { newValue in
                                            if id < equations.count, let parsed = try? parser.parseStatement(statement: newValue), parser.valid(statement: parsed) {
                                                equations[id] = newValue
                                                functions[id] = parsed
                                                compile()
                                            }
                                        }
                                    )
                                )
                                
                                Slider(value: Binding(get: {
                                    tolerances[id]
                                }, set: { newValue in
                                    tolerances[id] = newValue
                                    compile()
                                })) {
                                    Text("Tolerance")
                                } minimumValueLabel: {
                                    Text("0.0")
                                } maximumValueLabel: {
                                    Text("1.0")
                                }
                                Divider()
                            }
                            let color: (CGFloat, CGFloat, CGFloat) = {
                                let rng = SamplerWrapper(seed: 2262, uses: 425)
                                rng.seed += UInt32(id * 3)
                                rng.uses += UInt32(id * 3)
                                return (CGFloat(rng.next()), CGFloat(rng.next()), CGFloat(rng.next()))
                            }()
                            Circle()
                                .foregroundStyle(Color(red: color.0, green: color.1, blue: color.2))
                                .frame(width: 25, height: 25)
                        }
                    }
                    //                Text(text)
                }
                ZStack {
                    VStack {
                        HStack {
                            Text("\(bounds.w)")
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            Text("(\(bounds.x), \(bounds.z))")
                            Spacer()
                            Text("\(bounds.y)")
                        }
                    }
                    view
                        .padding()
                        .onReceive(timer) { _ in
                            view.draw()
                        }
                    
                }
                .padding()
            }
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { drag in
                    let t = drag.velocity
//                    let m = max(geometry.size.width, geometry.size.height)
                    let dx = -Float(t.width / geometry.size.width)
                    let dy = Float(t.height / geometry.size.height)
                    let diff = SIMD4<Float>(dx, dx, dy, dy) / 10 / 2
                    let bounds = boundsBuffer[0] ?? SIMD4<Float>(-1, 1, -1, 1)
                    let sum = bounds + diff
                    boundsBuffer[0] = sum
                    self.bounds = sum
                }
                .onEnded { drag in
                    
                }
            )
            .gesture(MagnifyGesture().onChanged { magnify in
                let bounds = boundsBuffer[0] ?? SIMD4<Float>(-1, 1, -1, 1)
                let result = bounds / Float(magnify.magnification)
                self.bounds = result
                boundsBuffer[0] = result
            })
            .onAppear {
                trackScrollWheel()
            }
            .onDisappear {
                for i in subs {
                    print(i)
                    i.cancel()
                }
                subs = Set()
            }
            
        }
    }
    
    @State var subs = Set<AnyCancellable>()
    
    func trackScrollWheel() {
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
//            .throttle(for: .milliseconds(2), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveCompletion: { failure in
                print("FAILURE", failure)
            }, receiveValue: { event in
                guard let event else { return }
                let zoom = exp(-Float(event.deltaY) / 30)
                bounds *= zoom
                boundsBuffer[0] = bounds
            })
//            .sink { [weak vm], event in
////                vm?.goBackOrForwardBy(delta: Int(event?.deltaY ?? 0))
//            }
            .store(in: &subs)
    }
    
//    var text: String {
//        do {
//            let (lhs, eq, rhs) = try parser.parseStatement(statement: eq)
//            return (lhs.map(\.description) + [String(eq)] + rhs.map(\.description))
//                .reduce("") { $0 + $1 + " " }
//        } catch {
//            print(error)
//            return error.localizedDescription
//        }
//    }
    
    func compile() {
        let rng = SamplerWrapper(seed: 2262, uses: 425)
        let function = """
#include <metal_stdlib>
using namespace metal;

[[kernel]]
void drawFunction(uint2 tid [[thread_position_in_grid]],
                    constant float4 & bounds,
                    constant float & t,
                    texture2d<half, access::read_write> background) {
    float2 uv = float2(tid) / float2(background.get_width(), background.get_height());
    float2 MIN = float2(bounds.x, bounds.z);
    float2 MAX = float2(bounds.y, bounds.w);
    float2 p = uv * (MAX - MIN) + MIN;
    
    float x = p.x;
    float y = p.y;

    float a;
    float b;

    float d;
    float z;
    float c;
"""
        let fnStrings = functions
            .enumerated()
            .compactMap { (idx, statement) -> (Int, Parser.Statement)? in
                guard let statement, parser.valid(statement: statement) else {
                    print("INVALID STATEMENT: \(statement)")
                    return nil
                }
                return (idx, statement)
            }
            .map {
"""

    a = \(parser.retextualize(symbols: $0.1.0));
    b = \(parser.retextualize(symbols: $0.1.2));
    d = a - b;
    d *= d;
    z = d / 2 / (\(tolerances[$0.0] * tolerances[$0.0]));
    c = exp(-z);
    if (z <= 1) {
        background.write(half4(half3(\(rng.next()), \(rng.next()), \(rng.next())) * c + (1 - c) * background.read(tid).xyz, 1), tid);
    }

"""
        }
        if fnStrings.isEmpty { return }
        
        let fullFunction = function + fnStrings.reduce("", +) + "}"
        print(fullFunction)
        let shader = ComputeShader.Function(name: "drawFunction")
        let device: MTLDevice = GPU.default.device
        do {
            let library = try device.makeLibrary(source: fullFunction, options: nil)
            try shader.compile(gpu: .default, library: library)
            future.wrapped = ComputeShader(function: shader, threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        } catch {
            print(error)
        }
//                try? function.compile(gpu: device, library: GPU.default.device.makeLibrary(source: function, options: nil)) else {
//
//        }
        
//        future.wrapped = ComputeShader(
//            name: "drawBackground",
//            threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
    }
}

class Future<T> {
    var wrapped: T? = nil
}
#Preview {
    Grapher()
}
