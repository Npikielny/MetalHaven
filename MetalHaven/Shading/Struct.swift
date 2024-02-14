//
//  Struct.swift
//  MetalHaven
//
//  Created by Noah Pikielny on 2/14/24.
//

import Foundation



class Struct: BasicTypes {
    var name: String
    
    var properties: [String: BasicTypes]
    
    init(name: String, properties: [String : BasicTypes]) {
        self.name = name
        self.properties = properties
    }
    
    func set<T>(name: String, value: T) {}
}

