/////
////  NorminetteCheckRequest.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct NorminetteCheckRequest: Encodable {
    let filename: String
    let content: String
    let rules: [String]
}
