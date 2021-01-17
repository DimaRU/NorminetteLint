/////
////  NorminetteError.swift
///   Copyright © 2021 Dmitriy Borovikov. All rights reserved.
//

import Foundation

public enum NorminetteError: Error, CustomStringConvertible {
    case badConfig(message: String)
    case checkError
    case timeout
    case invalidXcodeProj
    case scriptAlreadyExist
    case projectNotFound
    
    public var description: String {
        switch self {
        case .badConfig(message: let message):
            return message
        case .checkError:
            return "Errors found."
        case .timeout:
            return "Norminette server reply timeout."
        case .invalidXcodeProj:
            return "Invalid Xcode project: no targets"
        case .scriptAlreadyExist:
            return "Script already added"
        case .projectNotFound:
            return "Xcode project not found"
        }
    }
}
