/////
////  NorminetteReply.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

struct NorminetteReply: Decodable {
    struct NorminetteError: Decodable {
        let line: Int?
        let col: Int?
        let reason: String
    }
    let filename: String
    let display: String
    let errors: [NorminetteError]
}
