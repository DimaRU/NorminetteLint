/////
////  NorminetteCheckRequest.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct NorminetteCheckRequest: Codable {
    let filename: String
    let content: String
    let rules: [String]
}
