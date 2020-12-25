/////
////  Config.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


import Foundation

struct Config: Codable {
    let hostname: String
    let user: String
    let password: String
    let disabledRules: String
}
