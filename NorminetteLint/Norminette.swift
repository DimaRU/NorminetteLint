/////
////  Norminette.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct Norminette: ParsableCommand {
    enum Command {
        case version, rules, check
    }
    @Argument var files: [String] = []
    
    @Flag(name: .shortAndLong, help: "Display the current version of NorminetteLint")
    var version = false
    
    @Flag(name: .long, help: "Display rules list")
    var rulesList = false
    
    @Flag(name: .shortAndLong, help: "Downgrades errors to warnings")
    var warnings = false

    @Option(name: .shortAndLong, help: "The path to the NorminetteLint configuration file")
    var config: String = FileManager.default.currentDirectoryPath + "/.norminette.yml"
    
    mutating func run() throws {
        if files.isEmpty {
            let path = FileManager.default.currentDirectoryPath
            files.append(path)
        }
        let command: Command
        if version {
            command = .version
        } else if rulesList {
            command = .version
        } else {
            command = .check
        }
        print(command, self)
    }
}


