/////
////  NorminetteCheckRequest.swift
///   Copyright © 2021 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct NorminetteCheckRequest: Encodable {
    let filename: String
    let content: String
    let rules: [String]
}
