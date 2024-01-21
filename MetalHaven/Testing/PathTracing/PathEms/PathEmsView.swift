////
////  PathEmsView.swift
////  MetalHaven
////
////  Created by Noah Pikielny on 1/13/24.
////
//
//import MetalAbstract
//import SwiftUI
//
//struct PathEmsView: View {
//    
//    var view: MAView
//    
//    init(scene: GeometryScene, camera: Camera, width: Int, aspectRatio: Float, samples: Int) {
//        
//        var s = 0
//        
//        let frame = CGRect(origin: .zero, size: CGSize(width: width, height: Int(Float(width) * aspectRatio)))
//        let tex = Texture(format: .rgba16Float, width: width, height: Int(frame.height), storageMode: .private, usage: .renderTarget)
//        
//        let draw = RasterShader(
//            vertexShader: "getCornerVerts",
//            fragmentShader: "copyTexture",
//            fragmentTextures: [tex],
//            fragmentBuffers: [Buffer(name: "Rscale", [Float(1)], usage: .sparse)],
//            startingVertex: 0,
//            vertexCount: 6,
//            passDescriptor: .drawable,
//            format: .rgba16Float
//        )
//        
//        view = MAView(
//            gpu: .default,
//            frame: frame,
//            format: .rgba16Float,
//            updateProcedure: .rate(1 / 60)
//        ) { gpu, drawable, descriptor in
//            if s > samples { return }
//            
//            guard let drawable, let descriptor else { print("No context"); return }
//            
//            try await gpu.execute(drawable: drawable, descriptor: descriptor) {
//                
//            }
//        }
//        
//    }
//    
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//#Preview {
//    PathEmsView()
//}
