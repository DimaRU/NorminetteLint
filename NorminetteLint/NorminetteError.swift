/////
////  NorminetteError.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation

public enum NorminetteError: Error, CustomStringConvertible {
    case badConfig(message: String)
    case checkError
    case timeout
    
    public var description: String {
        switch self {
        case .badConfig(message: let message):
            return message
        case .checkError:
            return "Errors found."
        case .timeout:
            return "Norminette server reply timeout."
        }
    }
}