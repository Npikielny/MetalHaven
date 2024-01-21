//
//  Color.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 10/14/23.
//

import Exposables
import SwiftUI


public struct EColor: Exposable {
    var color: SIMD3<Double>
    var vec: Vec3 {
        Vec3(Float(color.x), Float(color.y), Float(color.z))
    }
    public typealias Settings = ()
    
    public struct Interface: ExposableInterface {
        public var title: String?
        public var wrappedValue: Expose<EColor>
        @ObservedObject var update: Update
        let settings: Settings?
        public init(_ settings: EColor.Settings?, title: String?, wrappedValue: Expose<EColor>) {
            self.settings = settings
            self.wrappedValue = wrappedValue
            self.update = wrappedValue.state
        }
        
        public typealias ParameterType = EColor
        
        public var body: some View {
            VStack {
                if let title {
                    Text(title)
                }
                HStack {
                    VStack {
                        ForEach(Array(["Red", "Green", "Blue"].enumerated()), id: \.offset) { (index, name) in
                            HStack {
                                Text(name)
                                Slider(
                                    value: Binding<Double>(get: {
                                        wrappedValue.wrappedValue.color[index]
                                    }, set: { newValue in
                                        wrappedValue.wrappedValue.color[index] = newValue
                                        wrappedValue.state.send()
                                    }),
                                    in: 0...1.0
                                )
                                Text("\(NSString(format: "%.2f", wrappedValue.wrappedValue.color[index]))")
                            }
                        }
                    }
                    .frame(width: 150)
                    let color = wrappedValue.wrappedValue.color
                    Circle()
                        .foregroundColor(Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z)))
                        .frame(width: 30, height: 30, alignment: .center)
                }
            }
        }
        
        
    }

    
    
}

//
//struct Color: Exposable {
//    var wrapped: Vec3 {
//        didSet {
//            wrapped = normalize(wrapped)
//        }
//    }
//    
//    var color: Vec3 {
//        get { wrapped }
//        set { wrapped = newValue }
//    }
//    
//    typealias Settings = ()
//    
//    struct Interface: ExposableInterface {
//        typealias ParameterType = Color
//        
//        var title: String?
//        var wrappedValue: Expose<Color>
//        
//        init(_ settings: ()?, title: String?, wrappedValue: Expose<Color>) {
//            self.title = title
//            self.wrappedValue = wrappedValue
//        }
//        
//        var body: some View {
//            NumberField(range: (0.0..1.0), title: "Red", value: wrappedValue.)
//        }
//    }
//}
