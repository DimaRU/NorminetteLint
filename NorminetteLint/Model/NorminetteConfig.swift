/////
////  NorminetteConfig.swift
///   Copyright © 2021 Dmitriy Borovikov. All rights reserved.
//


import Foundation

struct NorminetteConfig: Codable {
    let hostname: String
    let user: String
    let password: String
    var warnings: Bool?
    let disabledRules: [String]?
}
