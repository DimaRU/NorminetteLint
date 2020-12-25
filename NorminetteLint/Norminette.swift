/////
////  Norminette.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct Norminette: ParsableCommand {
    @Flag(help: "Display the current version of NorminetteLint")
    var version = false
    
    @Option(name: .shortAndLong, help: "The path to the file or directory to lint")
    var path: String = FileManager.default.currentDirectoryPath
    
    @Flag(name: .long, help: "Downgrades errors to warnings")
    var lenient = false
    
    @Option(name: .shortAndLong, help: "The path to the NorminetteLint configuration file")
    var config: String = FileManager.default.currentDirectoryPath + "/.norminette.yml"
    
    mutating func run() throws {
        let path = FileManager.default.currentDirectoryPath
        print(path)
    }
}


